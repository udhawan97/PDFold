import SwiftUI
import PDFKit
import Observation

@Observable
final class WorkspaceViewModel {
    var document: WorkspaceDocument
    var combinedPDF: PDFDocument = PDFDocument()
    var loadedPDFs: [(MemberDocument, PDFDocument)] = []
    var importError: ImportError? = nil
    var pendingPasswordURL: URL? = nil
    var isShowingPasswordPrompt = false

    private let engine: PDFEngine = PDFKitEngine()

    struct ImportError: Identifiable {
        var id = UUID()
        var fileName: String
        var message: String
    }

    init(document: WorkspaceDocument) {
        self.document = document
    }

    func importPDFs(urls: [URL]) {
        for url in urls {
            addPDF(from: url)
        }
        rebuild()
    }

    func addPDF(from url: URL) {
        let fileName = url.lastPathComponent
        guard let pdf = engine.loadDocument(from: url) else {
            importError = ImportError(fileName: fileName, message: "Could not open \"\(fileName)\". The file may be corrupt or in an unsupported format.")
            return
        }
        if pdf.isLocked {
            pendingPasswordURL = url
            isShowingPasswordPrompt = true
            return
        }
        attachPDF(pdf, from: url)
    }

    func unlock(pdf: PDFDocument, password: String, url: URL) -> Bool {
        guard pdf.unlock(withPassword: password) else { return false }
        attachPDF(pdf, from: url)
        rebuild()
        return true
    }

    private func attachPDF(_ pdf: PDFDocument, from url: URL) {
        let name = url.deletingPathExtension().lastPathComponent
        var member = MemberDocument(
            displayName: name,
            sourcePDFRef: url.lastPathComponent
        )
        var newRefs: [PageRef] = []
        for i in 0..<pdf.pageCount {
            let ref = PageRef(memberDocId: member.id, sourcePageIndex: i)
            newRefs.append(ref)
        }
        member.pageRefs = newRefs.map { $0.id }
        document.workspace.documents.append(member)
        document.workspace.pageOrder.append(contentsOf: newRefs)
        loadedPDFs.append((member, pdf))
    }

    func rebuild() {
        combinedPDF = engine.concatenate(documents: loadedPDFs)
    }

    func moveDocument(from source: IndexSet, to destination: Int) {
        document.workspace.documents.move(fromOffsets: source, toOffset: destination)
        reorderLoadedPDFs()
        rebuildPageOrder()
        rebuild()
    }

    func removeDocument(at offsets: IndexSet) {
        let removedIds = offsets.map { document.workspace.documents[$0].id }
        document.workspace.documents.remove(atOffsets: offsets)
        loadedPDFs.removeAll { removedIds.contains($0.0.id) }
        rebuildPageOrder()
        rebuild()
    }

    private func reorderLoadedPDFs() {
        let idOrder = document.workspace.documents.map { $0.id }
        loadedPDFs.sort { a, b in
            let ai = idOrder.firstIndex(of: a.0.id) ?? Int.max
            let bi = idOrder.firstIndex(of: b.0.id) ?? Int.max
            return ai < bi
        }
    }

    private func rebuildPageOrder() {
        var newOrder: [PageRef] = []
        for member in document.workspace.documents {
            let existing = document.workspace.pageOrder.filter { $0.memberDocId == member.id }
            newOrder.append(contentsOf: existing)
        }
        document.workspace.pageOrder = newOrder
    }
}
