import SwiftUI

@main
struct PDFoldApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: { WorkspaceDocument() }) { config in
            ContentView(document: config.document)
        }
        .commands {
            AppCommands()
        }
    }
}
