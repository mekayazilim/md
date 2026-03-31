Audit: nonisolated NSCache usage

Files inspected:
- mdviewer/Sources/mdviewer/Services/MarkdownRenderService.swift
- mdviewer/Sources/mdviewer/Services/Pipeline/TypographyApplier.swift
- mdviewer/Sources/mdviewer/Services/Pipeline/MermaidDiagramRenderer.swift
- mdviewer/Sources/mdviewer/Design/TableLayoutMetrics.swift
- mdviewer/Sources/mdviewer/Views/Content/FolderSidebarView.swift

Summary of findings & actions:
- MarkdownRenderService: caches are actor-isolated (actor MarkdownRenderService). No change necessary.
- TypographyApplier.fontCache: previously nonisolated static NSCache. Risk: AppKit (NSFont) usage off-main and unsynchronized access. Action: converted to @MainActor static cache and ensured font creation/cache access executed on main thread. Committed on branch agent/audit-nonisolated-caches.
- TableLayoutMetrics.tabStopCache: previously nonisolated static NSCache storing NSTextTab (AppKit). Risk: NSTextTab must be used on main thread. Action: made cache @MainActor and ensured tabStops() creates/accesses cache on main thread. Committed on branch agent/audit-nonisolated-caches.
- MermaidImageCache: wrapped NSCache, previously @unchecked Sendable. Risk: NSImage/TIFF calls are AppKit. Action: synchronized object(forKey:)/setObject to perform cache access and cost calculation on main thread.
- FolderSidebarView.imageCache: UI-only cache; usage appears to be main-thread-only (NSView). No change.

Notes:
- Changes committed locally on branch: agent/audit-nonisolated-caches.
- No remote push performed.

Next steps (optional):
- Replace MermaidImageCache with an @MainActor actor wrapper if we prefer typed actor isolation (requires callers to use await).
- Run targeted `just` checks (minimal build) and run affected unit tests.
