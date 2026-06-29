import SwiftUI

struct AppToolbar: ToolbarContent {
    var viewModel: WorkspaceViewModel

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Button {
                openPDFs()
            } label: {
                Label("Add PDFs", systemImage: "plus.circle")
            }
            .help("Add PDFs to workspace (⌘O)")
        }
    }

    private func openPDFs() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.pdf]
        if panel.runModal() == .OK {
            viewModel.importPDFs(urls: panel.urls)
        }
    }
}
