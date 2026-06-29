import SwiftUI

struct InspectorView: View {
    var viewModel: WorkspaceViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Inspector")
                .font(.headline)
                .padding(.horizontal)

            Divider()

            Text("Select a page or annotation to inspect.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Spacer()
        }
        .padding(.top)
        .frame(minWidth: 220)
    }
}
