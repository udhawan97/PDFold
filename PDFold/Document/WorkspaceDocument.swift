import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let pdfoldproj = UTType(exportedAs: "com.ud.PDFold.pdfoldproj")
}

final class WorkspaceDocument: ReferenceFileDocument {
    static var readableContentTypes: [UTType] { [.pdfoldproj] }
    static var writableContentTypes: [UTType] { [.pdfoldproj] }

    var workspace: Workspace
    var undoManager: UndoManager?

    init() {
        workspace = Workspace()
    }

    required init(configuration: ReadConfiguration) throws {
        guard let wrapper = configuration.file.fileWrappers else {
            workspace = Workspace()
            return
        }
        if let manifestWrapper = wrapper["workspace.json"],
           let data = manifestWrapper.regularFileContents {
            workspace = (try? JSONDecoder().decode(Workspace.self, from: data)) ?? Workspace()
        } else {
            workspace = Workspace()
        }
    }

    func fileWrapper(snapshot: Workspace, configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder().encode(snapshot)
        let manifestWrapper = FileWrapper(regularFileWithContents: data)
        manifestWrapper.preferredFilename = "workspace.json"
        let dirWrapper = FileWrapper(directoryWithFileWrappers: ["workspace.json": manifestWrapper])
        return dirWrapper
    }

    func snapshot(contentType: UTType) throws -> Workspace {
        workspace
    }
}
