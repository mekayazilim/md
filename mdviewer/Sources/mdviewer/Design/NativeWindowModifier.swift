//
//  NativeWindowModifier.swift
//  mdviewer
//

internal import SwiftUI

#if os(macOS)
    internal import AppKit
#endif

extension View {
    /// Lightweight fallback that configures the hosting NSWindow for the app's document window.
    /// Mirrors `configureWindow(_:)` behavior and ensures common window properties are applied
    /// when the original helper modifier is missing.
    func configureNativeWindow() -> some View {
        #if os(macOS)
            return onAppear {
                DispatchQueue.main.async {
                    guard let window = NSApplication.shared.windows.first else { return }
                    let className = window.className
                    guard className != "NSOpenPanel", className != "NSSavePanel" else { return }
                    window.tabbingMode = .preferred
                    if !window.styleMask.contains(.fullSizeContentView) {
                        window.styleMask.insert(.fullSizeContentView)
                    }
                    window.isMovableByWindowBackground = true
                }
            }
        #else
            return self
        #endif
    }
}
