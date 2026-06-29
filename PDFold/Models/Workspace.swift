import Foundation

struct Workspace: Codable {
    var id: UUID = UUID()
    var title: String = "Untitled Workspace"
    var createdAt: Date = Date()
    var modifiedAt: Date = Date()
    var documents: [MemberDocument] = []
    var pageOrder: [PageRef] = []
    var signatures: [SignaturePlacement] = []
    var schemaVersion: Int = 1
}
