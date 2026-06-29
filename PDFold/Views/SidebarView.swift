import SwiftUI
import PDFKit

struct SidebarView: View {
    var viewModel: WorkspaceViewModel
    @State private var expandedDocs: Set<UUID> = []

    var body: some View {
        List {
            ForEach(viewModel.document.workspace.documents) { member in
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedDocs.contains(member.id) },
                        set: { if $0 { expandedDocs.insert(member.id) } else { expandedDocs.remove(member.id) } }
                    )
                ) {
                    ThumbnailRowView(member: member, viewModel: viewModel)
                } label: {
                    HStack {
                        Image(systemName: "doc.fill")
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(member.displayName)
                                .font(.callout)
                                .lineLimit(1)
                            Text("\(member.pageRefs.count) page\(member.pageRefs.count == 1 ? "" : "s")")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .onMove { viewModel.moveDocument(from: $0, to: $1) }
            .onDelete { viewModel.removeDocument(at: $0) }
        }
        .listStyle(.sidebar)
        .navigationTitle(viewModel.document.workspace.title)
        .toolbar {
            ToolbarItem {
                Button {
                    openPDFs()
                } label: {
                    Image(systemName: "plus")
                }
                .help("Add PDFs")
            }
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

struct ThumbnailRowView: View {
    var member: MemberDocument
    var viewModel: WorkspaceViewModel

    private var pdfDoc: PDFDocument? {
        viewModel.loadedPDFs.first(where: { $0.0.id == member.id })?.1
    }

    var body: some View {
        if let pdf = pdfDoc {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 4) {
                    ForEach(0..<pdf.pageCount, id: \.self) { i in
                        if let page = pdf.page(at: i) {
                            PDFThumbnailCellView(page: page, index: i)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
            .frame(maxHeight: 300)
        }
    }
}

struct PDFThumbnailCellView: View {
    var page: PDFPage
    var index: Int

    var body: some View {
        HStack(spacing: 8) {
            PDFPageThumbnail(page: page)
                .frame(width: 48, height: 64)
                .cornerRadius(4)
                .shadow(radius: 1)
            Text("p. \(index + 1)")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

struct PDFPageThumbnail: NSViewRepresentable {
    var page: PDFPage

    func makeNSView(context: Context) -> PDFThumbnailView {
        let view = PDFThumbnailView()
        view.thumbnailSize = CGSize(width: 48, height: 64)
        return view
    }

    func updateNSView(_ nsView: PDFThumbnailView, context: Context) {
        let doc = PDFDocument()
        doc.insert(page, at: 0)
        nsView.pdfView = {
            let pv = PDFView()
            pv.document = doc
            return pv
        }()
    }
}
