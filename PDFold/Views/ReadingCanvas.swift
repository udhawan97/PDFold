import SwiftUI
import PDFKit

struct ReadingCanvas: View {
    var viewModel: WorkspaceViewModel

    var body: some View {
        PDFViewRepresentable(viewModel: viewModel)
            .ignoresSafeArea()
    }
}

struct PDFViewRepresentable: NSViewRepresentable {
    var viewModel: WorkspaceViewModel

    func makeNSView(context: Context) -> BoundaryPDFHostView {
        let host = BoundaryPDFHostView()
        host.configure(with: viewModel)
        return host
    }

    func updateNSView(_ nsView: BoundaryPDFHostView, context: Context) {
        nsView.configure(with: viewModel)
    }
}

final class BoundaryPDFHostView: NSView {
    private var pdfView: PDFView?
    private var overlayView: BoundaryOverlayView?
    private var lastDocumentCount = 0

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        let pv = PDFView()
        pv.displayMode = .singlePageContinuous
        pv.displayDirection = .vertical
        pv.autoScales = true
        pv.displaysPageBreaks = true
        pv.translatesAutoresizingMaskIntoConstraints = false
        addSubview(pv)
        NSLayoutConstraint.activate([
            pv.topAnchor.constraint(equalTo: topAnchor),
            pv.bottomAnchor.constraint(equalTo: bottomAnchor),
            pv.leadingAnchor.constraint(equalTo: leadingAnchor),
            pv.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        pdfView = pv
    }

    func configure(with viewModel: WorkspaceViewModel) {
        guard let pdfView else { return }
        let docCount = viewModel.document.workspace.documents.count
        guard pdfView.document !== viewModel.combinedPDF || lastDocumentCount != docCount else { return }
        lastDocumentCount = docCount
        pdfView.document = viewModel.combinedPDF
    }
}

final class BoundaryOverlayView: NSView {
    override var isFlipped: Bool { true }
}
