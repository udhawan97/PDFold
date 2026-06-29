import SwiftUI
import UniformTypeIdentifiers

struct EmptyStateView: View {
    var viewModel: WorkspaceViewModel
    @State private var isDropTargeted = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color(nsColor: .controlBackgroundColor)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                VStack(spacing: 16) {
                    AppIconMark(size: 88)

                    VStack(spacing: 7) {
                        Text("PDFold")
                            .font(.system(size: 34, weight: .semibold, design: .rounded))
                        Text("Combine, arrange, annotate, and export documents in one focused workspace.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .frame(maxWidth: 420)
                    }
                }

                VStack(spacing: 16) {
                    Image(systemName: isDropTargeted ? "tray.and.arrow.down.fill" : "doc.badge.plus")
                        .font(.system(size: 30, weight: .regular))
                        .foregroundStyle(Color.accentColor)
                        .symbolRenderingMode(.hierarchical)

                    VStack(spacing: 5) {
                        Text(isDropTargeted ? "Release to import" : "Drop files to begin")
                            .font(.title3.weight(.semibold))
                        Text("PDF, Word, HTML, text, CSV, JSON, XML, and images are supported.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        openFiles()
                    } label: {
                        Label("Choose Files", systemImage: "folder.badge.plus")
                            .frame(minWidth: 142)
                    }
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal, 42)
                .padding(.vertical, 34)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(
                            isDropTargeted ? Color.accentColor : Color.primary.opacity(0.08),
                            lineWidth: isDropTargeted ? 2 : 1
                        )
                }
                .shadow(color: .black.opacity(0.06), radius: 24, x: 0, y: 12)
            }
            .padding(56)

            GuideButton(autoShow: true)
                .buttonStyle(.borderless)
                .font(.title3)
                .padding(22)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    Color.accentColor,
                    lineWidth: isDropTargeted ? 1.5 : 0
                )
                .padding(12)
                .animation(.easeInOut(duration: 0.12), value: isDropTargeted)
        )
        .onDrop(of: WorkspaceDocument.importableContentTypes + [.fileURL], isTargeted: $isDropTargeted) { providers in
            resolveImportURLs(from: providers) { urls in
                viewModel.importFiles(urls: urls)
            }
            return true
        }
    }

    private func openFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = WorkspaceDocument.importableContentTypes
        if panel.runModal() == .OK {
            viewModel.importFiles(urls: panel.urls)
        }
    }
}
