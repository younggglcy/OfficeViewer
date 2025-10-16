import SwiftUI

struct SettingsView: View {
  @EnvironmentObject var viewModel: OfficeViewerViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      Text("OfficeViewer Settings")
        .font(.title)
        .fontWeight(.bold)

      VStack(alignment: .leading, spacing: 10) {
        Text("Default App for Opening Decoded Folders")
          .font(.headline)

        if viewModel.availableApps.isEmpty {
          Text("Loading apps...")
            .foregroundColor(.gray)
        } else {
          Picker("Select App", selection: $viewModel.selectedApp) {
            ForEach(viewModel.availableApps) { app in
              Text(app.name).tag(app as AppInfo?)
            }
          }
          .pickerStyle(.menu)
        }
      }
      .padding()
      .background(Color(.controlBackgroundColor))
      .cornerRadius(8)

      VStack(alignment: .leading, spacing: 10) {
        Text("How to Use")
          .font(.headline)

        Text(
          """
          1. Right-click any .docx, .xlsx, or .pptx file in Finder
          2. Select "Open With" → "OfficeViewer"
          3. The file will be decoded and opened with your selected app
          """
        )
        .font(.caption)
        .lineLimit(nil)
      }
      .padding()
      .background(Color(.controlBackgroundColor))
      .cornerRadius(8)

      Spacer()

      HStack {
        Text("v1.0.0")
          .font(.caption)
          .foregroundColor(.gray)

        Spacer()

        Link("GitHub", destination: URL(string: "https://github.com/younggglcy/OfficeViewer")!)
      }
      .padding(.top)
    }
    .padding(20)
    .frame(minWidth: 500, minHeight: 400)
  }
}

struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    SettingsView()
      .environmentObject(OfficeViewerViewModel())
  }
}
