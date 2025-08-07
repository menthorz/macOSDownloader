import SwiftUI

/// Teste simples de navegação
struct TestNavigationView: View {
    @State private var selectedView: String = "browse"
    
    var body: some View {
        NavigationSplitView {
            List {
                Button("Navegar") {
                    selectedView = "browse"
                }
                .foregroundColor(selectedView == "browse" ? .blue : .primary)
                
                Button("Downloads") {
                    selectedView = "downloads"
                }
                .foregroundColor(selectedView == "downloads" ? .blue : .primary)
                
                Button("Histórico") {
                    selectedView = "history"
                }
                .foregroundColor(selectedView == "history" ? .blue : .primary)
            }
            .navigationTitle("Teste")
        } detail: {
            VStack {
                Text("View Selecionada: \(selectedView)")
                    .font(.largeTitle)
                    .padding()
                
                switch selectedView {
                case "browse":
                    Text("🔍 BROWSE VIEW")
                        .font(.title)
                        .foregroundColor(.green)
                case "downloads":
                    Text("📥 DOWNLOADS VIEW")
                        .font(.title)
                        .foregroundColor(.blue)
                case "history":
                    Text("📚 HISTORY VIEW")
                        .font(.title)
                        .foregroundColor(.orange)
                default:
                    Text("❓ UNKNOWN VIEW")
                        .font(.title)
                        .foregroundColor(.red)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    TestNavigationView()
}
