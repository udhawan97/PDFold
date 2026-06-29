import SwiftUI

struct EmptyStateView: View {
    var viewModel: WorkspaceViewModel
    @State private var isDropTargeted = false

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)

            VStack(spacing: 24) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 64, weight: .ultraLight))
                    .foregroundStyle(.secondary)

                VStack(spacing: 8) {
                    Text("Drag PDFs here to start a workspace")
                        .font(.title2)
                        .fontWeight(.medium)
                    Text("Combine multiple PDFs into one readable, annotatable workspace")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 12) {
                    Button {
                        openPDFs()
                    } label: {
                        Label("Open PDFs…", systemImage: "folder")
                            .frame(minWidth: 120)
                    }
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(48)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.accentColor, lineWidth: isDropTargeted ? 3 : 0)
                .padding(8)
                .animation(.easeInOut(duration: 0.15), value: isDropTargeted)
        )
        .onDrop(of: [.pdf, .fileURL], isTargeted: $isDropTargeted) { providers in
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

    private func openPDFs() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.pdf]
        if panel.runModal() == .OK {
            viewModel.importPDFs(urls: panel.urls)
        }
    }
}
