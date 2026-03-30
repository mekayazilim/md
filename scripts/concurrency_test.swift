import Foundation

struct Dummy: Hashable {
    let id: UUID
}

final class CacheAsync {
    private var cache: [String: Dummy] = [:]
    private let queue = DispatchQueue(label: "cache.async", attributes: .concurrent)
    func get(key: String) -> Dummy {
        if let c = queue.sync(execute: { cache[key] }) {
            return c
        }
        let d = Dummy(id: UUID())
        queue.async(flags: .barrier) { [weak self] in
            self?.cache[key] = d
        }
        return d
    }
}

final class CacheSync {
    private var cache: [String: Dummy] = [:]
    private let queue = DispatchQueue(label: "cache.sync", attributes: .concurrent)
    func get(key: String) -> Dummy {
        if let c = queue.sync(execute: { cache[key] }) {
            return c
        }
        let d = Dummy(id: UUID())
        queue.sync(flags: .barrier) {
            if cache[key] == nil {
                cache[key] = d
            }
        }
        return queue.sync { cache[key]! }
    }
}

func runTest(cacheName: String, accessor: @escaping () -> Dummy) -> Int {
    let group = DispatchGroup()
    let q = DispatchQueue.global(qos: .userInitiated)
    var ids = Set<UUID>()
    let lock = NSLock()
    let iterations = 1000
    for _ in 0..<iterations {
        group.enter()
        q.async {
            let d = accessor()
            lock.lock()
            ids.insert(d.id)
            lock.unlock()
            group.leave()
        }
    }
    group.wait()
    return ids.count
}

let asyncCache = CacheAsync()
let syncCache = CacheSync()

let asyncUnique = runTest(cacheName: "async", accessor: { asyncCache.get(key: "theKey") })
let syncUnique = runTest(cacheName: "sync", accessor: { syncCache.get(key: "theKey") })

print("Async cache produced unique instances: \(asyncUnique)")
print("Sync cache produced unique instances:  \(syncUnique)")
