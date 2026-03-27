//
//  ContentToolbar.swift
//  mdviewer
//

internal import SwiftUI

/// A standalone toolbar content component that manages mode switching, sidebar visibility, and sharing.
@MainActor
struct ContentToolbar: ToolbarContent {
    @Binding var readerMode: ReaderMode
    @Binding var showMetadataInspector: Bool
    @Binding var sidebarMode: SidebarMode

    let documentText: String
    let hasFrontmatter: Bool
    let fileURL: URL?

    var body: some ToolbarContent {
        // Centered Mode Switcher
        ToolbarItem(id: "mode", placement: .principal) {
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
        }

        // Sidebar Toggle
        ToolbarItem(id: "sidebar", placement: .primaryAction) {
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
        }

        // Share Action
        ToolbarItem(id: "share", placement: .primaryAction) {
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

    // MARK: - Helpers

    private var canShowSidebar: Bool {
        hasFrontmatter || fileURL != nil
    }

    private var sidebarHelpText: String {
        if !canShowSidebar {
            return "No metadata or folder available"
        }
        if showMetadataInspector {
            return "Hide Sidebar"
        }
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
