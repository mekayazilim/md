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

    var body: some View {
        ZStack {
            if #available(macOS 26.0, *) {
                // Use native Liquid Glass when available
                Rectangle()
                    .foregroundStyle(.clear)
                    .glassEffect(.regular, in: .rect)
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
        .frame(height: 44)
        .ignoresSafeArea(edges: .top)
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
}
