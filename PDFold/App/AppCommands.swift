import SwiftUI

struct AppCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Workspace") {
                NSDocumentController.shared.newDocument(nil)
            }
            .keyboardShortcut("n", modifiers: .command)
        }
    }
}
