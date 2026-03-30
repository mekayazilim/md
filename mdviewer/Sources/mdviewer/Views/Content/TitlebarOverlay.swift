//
//  TitlebarOverlay.swift
//  mdviewer
//

internal import SwiftUI
#if os(macOS)
internal import AppKit
#endif

@MainActor
struct TitlebarOverlay: View {
    @Binding var readerMode: ReaderMode
    @Binding var showMetadataInspector: Bool
    @Binding var sidebarMode: SidebarMode

    let documentText: String
    let hasFrontmatter: Bool
    let fileURL: URL?

    // Dynamic titlebar height measured from the hosting NSWindow so the overlay
    // fully covers the native titlebar / toolbar area across toolbar styles.
    @State private var titlebarHeight: CGFloat = 44

    var body: some View {
        ZStack {
            if #available(macOS 26.0, *) {
                // Use native Liquid Glass when available
                Rectangle()
                    .foregroundStyle(.clear)
                    .background(.ultraThinMaterial)
            } else {
                // Fallback to ultra thin material
                Rectangle()
                    .foregroundColor(.clear)
                    .background(.ultraThinMaterial)
            }

            HStack {
                Spacer(minLength: 0)

                // Center mode switcher (no capsule background)
                HStack(spacing: 12) {
                    Button { readerMode = .rendered } label: {
                        Image(systemName: "doc.text.image")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(readerMode == .rendered ? Color.accentColor : .secondary)
                            .frame(width: 28, height: 24)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Rendered Mode")

                    Button { readerMode = .raw } label: {
                        Image(systemName: "doc.plaintext")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(readerMode == .raw ? Color.accentColor : .secondary)
                            .frame(width: 28, height: 24)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Raw Mode")
                }

                Spacer()

                // Right-side controls (no capsule background)
                HStack(spacing: DesignTokens.Spacing.tight) {
                    Button {
                        if canShowSidebar {
                            if !showMetadataInspector {
                                updateSidebarModeIfNeeded()
                            }
                            showMetadataInspector.toggle()
                        }
                    } label: {
                        Image(systemName: "sidebar.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(showMetadataInspector ? Color.accentColor : .secondary)
                            .frame(width: 28, height: 24)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help(sidebarHelpText)
                    .disabled(!canShowSidebar)

                    ShareLink(item: documentText) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 28, height: 24)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Share Document")
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.tight)
            .padding(.vertical, 6)
        }
        .frame(height: titlebarHeight)
        .ignoresSafeArea(edges: .top)
        .onAppear {
            updateTitlebarHeight()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResizeNotification)) { _ in
            updateTitlebarHeight()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didMoveNotification)) { _ in
            updateTitlebarHeight()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            updateTitlebarHeight()
        }
        .accessibilityElement(children: .contain)
    }

    private var canShowSidebar: Bool {
        hasFrontmatter || fileURL != nil
    }

    private var sidebarHelpText: String {
        if !canShowSidebar { return "No metadata or folder available" }
        if showMetadataInspector { return "Hide Sidebar" }
        return "Show Sidebar"
    }

    private func updateSidebarModeIfNeeded() {
        if sidebarMode == .folder, fileURL == nil, hasFrontmatter {
            sidebarMode = .metadata
        } else if sidebarMode == .metadata, !hasFrontmatter, fileURL != nil {
            sidebarMode = .folder
        }
    }

    private func updateTitlebarHeight() {
        #if os(macOS)
        DispatchQueue.main.async {
            guard let window = NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first else { return }

            var height: CGFloat = 44
            if let close = window.standardWindowButton(.closeButton) {
                // close.frame is in the contentView coordinate space; maxY approximates the titlebar area.
                let closeMaxY = close.frame.maxY
                // Add a small padding to ensure overlap with any toolbar or accessory view.
                height = max(44, closeMaxY + 8)
            }

            titlebarHeight = height
        }
        #endif
    }
}
