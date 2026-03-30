//
//  mdviewerApp.swift
//  mdviewer
//

internal import SwiftUI
#if os(macOS)
    internal import AppKit
    internal import OSLog
#endif

@main
struct mdviewerApp: App {
    #if os(macOS)
        @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
        @FocusedValue(\.editorActions) private var focusedEditorActions
    #endif

    @State private var showingKeybindings = false
    #if os(macOS)
        private let logger = Logger(subsystem: "mdviewer", category: "default-association")
    #endif

    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { file in
            ContentView(document: file.$document, fileURL: file.fileURL)
                .frame(minWidth: 600, minHeight: 400)
                .configureNativeWindow()
                .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
                .containerBackground(.ultraThinMaterial, for: .window)
                .environment(\.preferences, AppPreferences.shared)
                .sheet(isPresented: $showingKeybindings) {
                    KeybindingsView()
                }
        }
        .defaultSize(width: 900, height: 700)
        #if os(macOS)
            .windowStyle(.automatic)
            .windowToolbarStyle(.unified)
            .windowBackgroundDragBehavior(.enabled)
            .windowResizability(.contentMinSize)
            .commands {
                // Edit Menu - Markdown editing commands using focused values
                CommandMenu("Edit") {
                    Button("Toggle Bold") {
                        sendEditorAction(\.insertBold)
                    }
                    .keyboardShortcut("b", modifiers: [.command])
                    .disabled(focusedEditorActions == nil)

                    Button("Toggle Italic") {
                        sendEditorAction(\.insertItalic)
                    }
                    .keyboardShortcut("i", modifiers: [.command])
                    .disabled(focusedEditorActions == nil)

                    Button("Insert Code Block") {
                        sendEditorAction(\.insertCodeBlock)
                    }
                    .keyboardShortcut("k", modifiers: [.command, .shift])
                    .disabled(focusedEditorActions == nil)

                    Divider()

                    Button("Insert Link") {
                        sendEditorAction(\.insertLink)
                    }
                    .keyboardShortcut("k", modifiers: [.command])
                    .disabled(focusedEditorActions == nil)

                    Button("Insert Image") {
                        sendEditorAction(\.insertImage)
                    }
                    .keyboardShortcut("i", modifiers: [.command, .shift])
                    .disabled(focusedEditorActions == nil)
                }

                // View Menu
                CommandMenu("View") {
                    Button("Rendered Mode") {
                        focusedEditorActions?.setRenderedMode()
                    }
                    .keyboardShortcut("r", modifiers: [.command, .option])
                    .disabled(focusedEditorActions == nil)

                    Button("Raw Mode") {
                        focusedEditorActions?.setRawMode()
                    }
                    .keyboardShortcut("e", modifiers: [.command, .option])
                    .disabled(focusedEditorActions == nil)

                    Divider()

                    // Zoom controls - using explicit key equivalents
                    Group {
                        Button("Zoom In") {
                            AppPreferences.shared.increaseFontSize()
                        }
                        .keyboardShortcut(KeyboardShortcut("=", modifiers: .command))

                        Button("Zoom Out") {
                            AppPreferences.shared.decreaseFontSize()
                        }
                        .keyboardShortcut(KeyboardShortcut("-", modifiers: .command))

                        Button("Reset Zoom") {
                            AppPreferences.shared.resetFontSize()
                        }
                        .keyboardShortcut(KeyboardShortcut("0", modifiers: .command))
                    }
                }

                // Help Menu with keybindings
                CommandMenu("Help") {
                    Button("Keyboard Shortcuts") {
                        showingKeybindings = true
                    }
                    .keyboardShortcut("/", modifiers: .command)

                    Divider()

                    Button("Set Default For *.md Files") {
                        setDefaultMarkdownAssociation()
                    }
                }

                // Window Menu - Tabbing and Full Screen
                CommandGroup(after: .windowSize) {
                    Divider()

                    Button("Show All Tabs") {
                        NSApplication.shared.keyWindow?.toggleTabOverview(nil)
                    }
                    .keyboardShortcut("\\", modifiers: [.command, .shift])

                    Button("New Tab") {
                        NSDocumentController.shared.newDocument(nil)
                    }
                    .keyboardShortcut("t", modifiers: [.command])

                    Divider()

                    Button("Enter Full Screen") {
                        NSApplication.shared.keyWindow?.toggleFullScreen(nil)
                    }
                    .keyboardShortcut("f", modifiers: [.command, .control])
                }

                // Replace standard zoom with our custom implementation
                CommandGroup(replacing: .textFormatting) {
                    // Empty - we handle zoom in View menu
                }
            }
        #endif

        #if os(macOS)
            Settings {
                SettingsView()
            }
            .defaultSize(width: DesignTokens.Layout.settingsWidth, height: DesignTokens.Layout.settingsHeight)
        #endif
    }

    #if os(macOS)
        /// Sends an action to the focused editor if available
        private func sendEditorAction(_ keyPath: KeyPath<EditorActions, () -> Void>) {
            focusedEditorActions?[keyPath: keyPath]()
        }

        private func setDefaultMarkdownAssociation() {
            do {
                try DefaultMarkdownAppRegistrar.setAppAsDefaultMarkdownHandler()
                showAssociationAlert(
                    title: "Default App Updated",
                    message: "md is now set as the default app for Markdown files."
                )
            } catch {
                logger.error("Failed to set default markdown association: \(error.localizedDescription)")
                showAssociationAlert(
                    title: "Could Not Update Default App",
                    message: error.localizedDescription
                )
            }
        }

        private func showAssociationAlert(title: String, message: String) {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    #endif
}

#if os(macOS)
    @MainActor
    final class AppDelegate: NSObject, NSApplicationDelegate {
        func applicationDidFinishLaunching(_ notification: Notification) {
            NSWindow.allowsAutomaticWindowTabbing = true

            // Yield the first frame, then prewarm heavy services at utility priority.
            Task(priority: .utility) {
                try? await Task.sleep(for: .seconds(PerformanceConstants.startupPrewarmDelay))
                let _ = AppPreferences.shared
                await MarkdownRenderService.shared.prewarm()

                // Pre-compile syntax highlighting regexes for common languages
                _ = LanguageRegistry.definition(for: "swift")
                _ = LanguageRegistry.definition(for: "markdown")
            }

            openDocumentFromCLIIfNeeded()
        }

        private func openDocumentFromCLIIfNeeded() {
            guard let url = cliDocumentURL() else {
                return
            }

            // For CLI opening, we use the standard NSDocumentController flow.
            // Large file checks are handled by MarkdownDocument itself.
            NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, error in
                if let error {
                    NSApplication.shared.presentError(error)
                }
            }
        }

        private func cliDocumentURL() -> URL? {
            let args = CommandLine.arguments.dropFirst()

            guard let rawPath = args.first(where: { !$0.hasPrefix("-") }) else {
                return nil
            }

            let expandedPath = (rawPath as NSString).expandingTildeInPath
            let resolvedPath: String
            if expandedPath.hasPrefix("/") {
                resolvedPath = expandedPath
            } else {
                resolvedPath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                    .appendingPathComponent(expandedPath)
                    .path
            }

            guard FileManager.default.fileExists(atPath: resolvedPath) else {
                return nil
            }

            return URL(fileURLWithPath: resolvedPath)
        }

        func configureWindow(_ window: NSWindow) {
            // Ignore system windows like the Open/Save panels
            let className = window.className
            guard className != "NSOpenPanel", className != "NSSavePanel" else { return }

            window.tabbingMode = .preferred

            // Defer property changes that trigger layout to avoid constraint crashes
            DispatchQueue.main.async { [weak window] in
                guard let window else { return }
                window.titlebarAppearsTransparent = true
                window.titlebarSeparatorStyle = .none
                if !window.styleMask.contains(.fullSizeContentView) {
                    window.styleMask.insert(.fullSizeContentView)
                }

                // Allow dragging from any empty background area
                window.isMovableByWindowBackground = true
            }
        }
    }
#endif
