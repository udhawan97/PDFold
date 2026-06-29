import PDFKit
import Foundation

final class PDFKitEngine: PDFEngine {
    func loadDocument(from url: URL) -> PDFDocument? {
        PDFDocument(url: url)
    }

    func concatenate(documents: [(MemberDocument, PDFDocument)]) -> PDFDocument {
        let combined = PDFDocument()
        var insertIndex = 0
        for (_, pdf) in documents {
            for i in 0..<pdf.pageCount {
                if let page = pdf.page(at: i) {
                    combined.insert(page, at: insertIndex)
                    insertIndex += 1
                }
            }
        }
        return combined
    }
}
