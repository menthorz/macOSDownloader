import SwiftUI

@main
struct MacOSVersionManagerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 900, minHeight: 600)
                .onAppear {
                    setupWindow()
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Nova Janela") {
                    openNewWindow()
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            CommandGroup(after: .windowArrangement) {
                Button("Downloads") {
                    // Open downloads window
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
                
                Button("Histórico") {
                    // Open history window
                }
                .keyboardShortcut("h", modifiers: [.command, .shift])
            }
        }
    }
    
    private func setupWindow() {
        // Configure window appearance
        if let window = NSApplication.shared.windows.first {
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.styleMask.insert(.fullSizeContentView)
        }
    }
    
    private func openNewWindow() {
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        newWindow.contentView = NSHostingView(rootView: ContentView())
        newWindow.center()
        newWindow.makeKeyAndOrderFront(nil)
        newWindow.titlebarAppearsTransparent = true
        newWindow.titleVisibility = .hidden
    }
}
