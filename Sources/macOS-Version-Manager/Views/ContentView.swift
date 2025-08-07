import SwiftUI

/// View principal da aplicação com design moderno
struct ContentView: View {
    @StateObject private var versionService = MacOSVersionService.shared
    @StateObject private var downloadService = DownloadService.shared
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var selectedCategory: MacOSCategory? = nil
    @State private var showingDownloadFolder = false
    @State private var selectedView: MainView = .browse
    
    enum MainView: String, CaseIterable {
        case browse = "browse"
        case downloads = "downloads"
        case history = "history"
        
        var displayName: String {
            switch self {
            case .browse: return "Navegar"
            case .downloads: return "Downloads"
            case .history: return "Histórico"
            }
        }
        
        var systemImage: String {
            switch self {
            case .browse: return "square.grid.2x2"
            case .downloads: return "arrow.down.circle"
            case .history: return "clock"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Header da Sidebar
                sidebarHeader
                
                // Lista de Categorias
                List {
                    Section("Categorias") {
                        ForEach(MacOSCategory.allCases, id: \.self) { category in
                            Button(action: { 
                                selectedCategory = category
                                selectedView = .browse 
                            }) {
                                CategoryRow(
                                    category: category,
                                    count: versionService.versions(for: category).count,
                                    isSelected: selectedCategory == category
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Button("Todas as Categorias") {
                            selectedCategory = nil
                            selectedView = .browse
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(selectedCategory == nil && selectedView == .browse ? .primary : .secondary)
                    }
                    
                    Section("Downloads") {
                        Button(action: { 
                            print("🔄 Clicando em Downloads Ativos")
                            selectedView = .downloads 
                            selectedCategory = nil
                        }) {
                            HStack {
                                Image(systemName: "arrow.down.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Downloads Ativos")
                                Spacer()
                                if downloadService.activeDownloadsCount > 0 {
                                    Text("\(downloadService.activeDownloadsCount)")
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.blue)
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(selectedView == .downloads ? .primary : .secondary)
                        
                        Button(action: { 
                            print("🔄 Clicando em Histórico")
                            selectedView = .history 
                            selectedCategory = nil
                        }) {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.secondary)
                                Text("Histórico")
                                Spacer()
                                if downloadService.completedDownloadsCount > 0 {
                                    Text("\(downloadService.completedDownloadsCount)")
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.secondary)
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(selectedView == .history ? .primary : .secondary)
                    }
                }
                .listStyle(SidebarListStyle())
            }
        } detail: {
            TabView(selection: $selectedView) {
                VStack(spacing: 0) {
                    toolbar
                    
                    if versionService.isLoading {
                        ProgressView("Carregando versões...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        VersionGridView(
                            versions: filteredVersions,
                            searchText: $searchText
                        )
                    }
                }
                .tabItem { Label("Navegar", systemImage: "square.grid.2x2") }
                .tag(MainView.browse)
                
                ActiveDownloadsView(selectedView: $selectedView)
                    .tabItem { Label("Downloads", systemImage: "arrow.down.circle") }
                    .tag(MainView.downloads)
                
                DownloadHistoryContentView()
                    .tabItem { Label("Histórico", systemImage: "clock") }
                    .tag(MainView.history)
            }
            .tabViewStyle(.automatic)
        }
        .navigationSplitViewColumnWidth(ideal: 220)
        .navigationTitle("macOS Download Manager")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { showingDownloadFolder.toggle() }) {
                    Image(systemName: "folder")
                }
                .help("Abrir pasta de downloads")
                
                Button(action: versionService.loadVersions) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Atualizar lista")
            }
        }
        .fileImporter(
            isPresented: $showingDownloadFolder,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            // Handle folder selection
        }
    }
    
    // MARK: - Subviews
    
    private var sidebarHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "laptopcomputer")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("macOS Manager")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(versionService.versions.count) versões")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Status de Downloads
            if downloadService.activeDownloadsCount > 0 {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.blue)
                        .imageScale(.small)
                    
                    Text("\(downloadService.activeDownloadsCount) downloads ativos")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.blue.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
    }
    
    private var toolbar: some View {
        HStack {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Buscar versões...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.quaternary)
            .cornerRadius(10)
            
            Spacer()
            
            // Filter Menu
            Menu {
                Button("Todas as Categorias") {
                    selectedCategory = nil
                }
                
                Divider()
                
                ForEach(MacOSCategory.allCases, id: \.self) { category in
                    Button(category.displayName) {
                        selectedCategory = category
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    Text(selectedCategory?.displayName ?? "Todas")
                }
            }
        }
        .padding()
        .background(.regularMaterial)
    }
    
    private var filteredVersions: [MacOSVersion] {
        var versions = versionService.versions
        
        // Filter by category
        if let category = selectedCategory {
            versions = versions.filter { $0.category == category }
        }
        
        // Filter by search
        if !searchText.isEmpty {
            versions = versionService.searchVersions(query: searchText)
        }
        
        return versions
    }
}

/// Row para categorias na sidebar
struct CategoryRow: View {
    let category: MacOSCategory
    let count: Int
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: category.systemImage)
                .foregroundColor(color)
                .frame(width: 16)
            
            Text(category.displayName)
                .fontWeight(isSelected ? .semibold : .regular)
            
            Spacer()
            
            if count > 0 {
                Text("\(count)")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.2))
                    .foregroundColor(color)
                    .clipShape(Capsule())
            }
        }
    }
    
    private var color: Color {
        switch category {
        case .latest: return .blue
        case .beta: return .orange
        case .stable: return .green
        case .legacy: return .gray
        }
    }
}

#Preview {
    ContentView()
}
