import SwiftUI
import PDFKit

struct ContentView: View {
    var document: WorkspaceDocument
    @State private var viewModel: WorkspaceViewModel

    init(document: WorkspaceDocument) {
        self.document = document
        _viewModel = State(initialValue: WorkspaceViewModel(document: document))
    }

    var body: some View {
        Group {
            if viewModel.document.workspace.documents.isEmpty {
                EmptyStateView(viewModel: viewModel)
            } else {
                NavigationSplitView {
                    SidebarView(viewModel: viewModel)
                } content: {
                    ReadingCanvas(viewModel: viewModel)
                } detail: {
                    InspectorView(viewModel: viewModel)
                }
                .navigationSplitViewStyle(.balanced)
            }
        }
        .onDrop(of: [.pdf, .fileURL], isTargeted: nil, perform: handleDrop)
        .alert("Import Error", isPresented: Binding(
            get: { viewModel.importError != nil },
            set: { if !$0 { viewModel.importError = nil } }
        )) {
            Button("OK") { viewModel.importError = nil }
        } message: {
            Text(viewModel.importError?.message ?? "")
        }
        .sheet(isPresented: $viewModel.isShowingPasswordPrompt) {
            if let url = viewModel.pendingPasswordURL,
               let pdf = PDFDocument(url: url) {
                PasswordPromptView(
                    fileName: url.lastPathComponent,
                    pdf: pdf,
                    url: url,
                    viewModel: viewModel
                )
            }
        }
        .toolbar {
            AppToolbar(viewModel: viewModel)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var urls: [URL] = []
        let group = DispatchGroup()
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                group.enter()
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                    defer { group.leave() }
                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil),
                       url.pathExtension.lowercased() == "pdf" {
                        urls.append(url)
                    }
                }
            }
        }
        group.notify(queue: .main) {
            viewModel.importPDFs(urls: urls)
        }
        return true
    }
}
