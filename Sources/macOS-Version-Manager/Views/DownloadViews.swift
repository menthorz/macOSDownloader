import SwiftUI

/// View para configuração de download
struct DownloadConfigurationSheet: View {
    let version: MacOSVersion
    @Binding var isPresented: Bool
    @StateObject private var downloadService = DownloadService.shared
    @State private var selectedDestination: URL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
    @State private var showingFolderPicker = false
    @State private var isDownloading = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Configurar Download")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Cancelar") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(.quaternary.opacity(0.3))
            
            // Scrollable Content
            ScrollView {
                VStack(spacing: 20) {
                    // Version Info
                    versionInfoSection
                    
                    // Download Configuration
                    downloadConfigSection
                    
                    // Download Button
                    downloadButtonSection
                }
                .padding()
            }
        }
        .frame(minWidth: 480, maxWidth: 600, minHeight: 500, maxHeight: 700)
        .fileImporter(
            isPresented: $showingFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    selectedDestination = url
                }
            case .failure:
                break
            }
        }
    }
    
    private var versionInfoSection: some View {
        VStack(spacing: 12) {
            HStack {
                MacOSIcon(version.iconName, fallback: version.systemImage, size: 64)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(version.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(version.version)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Build \(version.buildNumber)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Version Details
            VStack(spacing: 8) {
                InfoRow(
                    icon: "calendar",
                    label: "Data de Lançamento",
                    value: version.releaseDate.formatted(date: .abbreviated, time: .omitted)
                )
                
                InfoRow(
                    icon: "internaldrive",
                    label: "Tamanho do Arquivo",
                    value: version.fileSize
                )
                
                if version.isBeta {
                    InfoRow(
                        icon: "flask",
                        label: "Tipo",
                        value: "Versão Beta",
                        valueColor: .orange
                    )
                }
                
                InfoRow(
                    icon: "checkmark.shield",
                    label: "Suporte",
                    value: version.isSupported ? "Suportado" : "Não Suportado",
                    valueColor: version.isSupported ? .green : .red
                )
            }
        }
        .padding()
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var downloadConfigSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Configurações de Download")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Pasta de Destino")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text(selectedDestination.path)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Spacer()
                    
                    Button("Escolher...") {
                        showingFolderPicker = true
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(.quaternary.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // File name preview
            VStack(alignment: .leading, spacing: 8) {
                Text("Nome do Arquivo")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(fileName)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // Warnings
            if !version.isSupported {
                WarningBox(
                    icon: "exclamationmark.triangle",
                    title: "Versão Não Suportada",
                    message: "Esta versão do macOS pode não receber mais atualizações de segurança.",
                    color: .orange
                )
            }
            
            if version.isBeta {
                WarningBox(
                    icon: "flask",
                    title: "Versão Beta",
                    message: "Esta é uma versão beta e pode conter bugs. Use apenas para testes.",
                    color: .blue
                )
            }
        }
    }
    
    private var downloadButtonSection: some View {
        VStack(spacing: 12) {
            Button(action: startDownload) {
                HStack {
                    if isDownloading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.down.circle.fill")
                    }
                    
                    Text(isDownloading ? "Iniciando Download..." : "Iniciar Download")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isDownloading)
            .controlSize(.large)
            
            Text("O download será salvo em: \(selectedDestination.lastPathComponent)")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var fileName: String {
        return "\(version.name.replacingOccurrences(of: " ", with: "_"))_\(version.buildNumber).pkg"
    }
    
    private func startDownload() {
        isDownloading = true
        
        let destination = selectedDestination.appendingPathComponent(fileName)
        
        Task {
            do {
                try await downloadService.startDownload(for: version, to: destination)
                await MainActor.run {
                    isPresented = false
                }
            } catch {
                await MainActor.run {
                    isDownloading = false
                    // Handle error
                }
            }
        }
    }
}

/// Row de informação reutilizável
struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            Text(label)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
        }
    }
}

/// Caixa de aviso reutilizável
struct WarningBox: View {
    let icon: String
    let title: String
    let message: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .imageScale(.medium)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

/// View de downloads ativos
struct DownloadsView: View {
    @StateObject private var downloadService = DownloadService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if downloadService.activeDownloads.isEmpty {
                emptyStateView
            } else {
                downloadsList
            }
        }
        .navigationTitle("Downloads Ativos")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if !downloadService.activeDownloads.isEmpty {
                    Button("Cancelar Todos") {
                        downloadService.cancelAllDownloads()
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("Nenhum download ativo")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Downloads aparecerão aqui quando iniciados")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var downloadsList: some View {
        List(downloadService.activeDownloads) { download in
            DownloadProgressCard(downloadInfo: download)
        }
        .listStyle(PlainListStyle())
    }
}

/// View de histórico de downloads
struct DownloadHistoryView: View {
    @StateObject private var downloadService = DownloadService.shared
    
    var body: some View {
        VStack {
            if downloadService.downloadHistory.isEmpty {
                emptyStateView
            } else {
                historyList
            }
        }
        .navigationTitle("Histórico de Downloads")
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("Nenhum download no histórico")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Downloads concluídos aparecerão aqui")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var historyList: some View {
        List(downloadService.downloadHistory) { download in
            DownloadHistoryCard(downloadInfo: download)
        }
        .listStyle(PlainListStyle())
    }
}

/// Card de progresso de download
struct DownloadProgressCard: View {
    let downloadInfo: DownloadInfo
    @StateObject private var downloadService = DownloadService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Download ID: \(downloadInfo.versionId.uuidString.prefix(8))")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(downloadInfo.status.displayName)
                        .font(.subheadline)
                        .foregroundColor(statusColor)
                }
                
                Spacer()
                
                // Action buttons
                HStack {
                    if downloadInfo.status == .downloading {
                        Button("Pausar") {
                            downloadService.pauseDownload(for: downloadInfo.versionId)
                        }
                        .buttonStyle(.bordered)
                    } else if downloadInfo.status == .paused {
                        Button("Continuar") {
                            downloadService.resumeDownload(for: downloadInfo.versionId)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    Button("Cancelar") {
                        downloadService.cancelDownload(for: downloadInfo.versionId)
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
            }
            
            // Progress
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Progresso")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(downloadInfo.progress * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                ProgressView(value: downloadInfo.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                
                HStack {
                    Text(downloadInfo.speedFormatted)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(downloadInfo.estimatedTimeRemaining)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var statusColor: Color {
        switch downloadInfo.status {
        case .downloading: return .blue
        case .paused: return .orange
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .gray
        case .notStarted: return .secondary
        }
    }
}

/// Card de histórico de download
struct DownloadHistoryCard: View {
    let downloadInfo: DownloadInfo
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Download ID: \(downloadInfo.versionId.uuidString.prefix(8))")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(downloadInfo.status.displayName)
                    .font(.subheadline)
                    .foregroundColor(statusColor)
                
                if let startTime = downloadInfo.startTime {
                    Text("Iniciado: \(startTime, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if downloadInfo.status == .completed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .imageScale(.large)
            } else if downloadInfo.status == .failed {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .imageScale(.large)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var statusColor: Color {
        switch downloadInfo.status {
        case .downloading: return .blue
        case .paused: return .orange
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .gray
        case .notStarted: return .secondary
        }
    }
}

#Preview {
    DownloadConfigurationSheet(
        version: MacOSVersionService.shared.versions.first!,
        isPresented: .constant(true)
    )
}

/// View de downloads ativos melhorada para o content principal
struct ActiveDownloadsView: View {
    @StateObject private var downloadService = DownloadService.shared
    @StateObject private var versionService = MacOSVersionService.shared
    @Binding var selectedView: ContentView.MainView
    
    private let columns = [
        GridItem(.adaptive(minimum: 320, maximum: 400), spacing: 16)
    ]
    
    init(selectedView: Binding<ContentView.MainView> = .constant(.downloads)) {
        self._selectedView = selectedView
    }

    var body: some View {
        Group {
            if downloadService.activeDownloads.isEmpty {
                emptyDownloadsView
            } else {
                activeDownloadsList
            }
        }
        .onAppear {
            print("🚀 ActiveDownloadsView carregada com \(downloadService.activeDownloads.count) downloads")
        }
    }
    
    private var emptyDownloadsView: some View {
        VStack(spacing: 24) {
            // Ícone grande
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.blue.opacity(0.6))
            }
            
            VStack(spacing: 12) {
                Text("Nenhum download ativo")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Vá para a seção 'Navegar' e clique em qualquer versão do macOS para iniciar um download")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, 40)
            }
            
            Button(action: {
                selectedView = .browse
            }) {
                HStack {
                    Image(systemName: "square.grid.2x2")
                    Text("Ir para Navegar")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: 200)
                .padding()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var activeDownloadsList: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Downloads Ativos")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("\(downloadService.activeDownloads.count) download\(downloadService.activeDownloads.count == 1 ? "" : "s") em andamento")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Limpar Concluídos") {
                    // Ação para limpar downloads concluídos
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(.quaternary.opacity(0.3))
            
            // Lista de downloads
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(downloadService.activeDownloads) { download in
                        ActiveDownloadCard(downloadInfo: download)
                    }
                }
                .padding()
            }
        }
    }
}

/// Card moderno para downloads ativos com estilo similar à aba de navegação
struct ActiveDownloadCard: View {
    let downloadInfo: DownloadInfo
    @StateObject private var downloadService = DownloadService.shared
    @StateObject private var versionService = MacOSVersionService.shared
    
    var version: MacOSVersion? {
        versionService.versions.first { $0.id == downloadInfo.versionId }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header com informações da versão
            HStack(spacing: 12) {
                // Ícone da versão
                MacOSIcon(version?.iconName, fallback: version?.systemImage ?? "desktopcomputer", size: 64)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(version?.name ?? "macOS Download")
                        .font(.title2)
                        .fontWeight(.bold)
                        .lineLimit(1)
                    
                    if let version = version {
                        Text("\(version.version)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Build \(version.buildNumber)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Status badge
                statusBadge
            }
            .padding()
            
            Divider()
            
            // Progress section
            VStack(spacing: 12) {
                // Progress bar
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Progresso")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(Int(downloadInfo.progress * 100))%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    
                    ProgressView(value: downloadInfo.progress)
                        .progressViewStyle(.linear)
                        .tint(.blue)
                }
                
                // Download info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Velocidade")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(downloadSpeed)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Tamanho")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(version?.fileSize ?? "Calculando...")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                
                // Action buttons
                HStack(spacing: 8) {
                    Button(action: pauseResumeAction) {
                        HStack(spacing: 4) {
                            Image(systemName: downloadInfo.status == .downloading ? "pause.circle" : "play.circle")
                            Text(downloadInfo.status == .downloading ? "Pausar" : "Retomar")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: cancelAction) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle")
                            Text("Cancelar")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
            }
            .padding()
        }
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
    
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.1))
        .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch downloadInfo.status {
        case .downloading: return .blue
        case .paused: return .orange
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .gray
        default: return .gray
        }
    }
    
    private var statusText: String {
        switch downloadInfo.status {
        case .downloading: return "Baixando"
        case .paused: return "Pausado"
        case .completed: return "Concluído"
        case .failed: return "Erro"
        case .cancelled: return "Cancelado"
        default: return "Aguardando"
        }
    }
    
    private var downloadSpeed: String {
        // Simulação de velocidade - pode ser implementado no DownloadService
        if downloadInfo.status == .downloading {
            return "2.5 MB/s"
        } else {
            return "-- MB/s"
        }
    }
    
    private func pauseResumeAction() {
        // Implementar ação de pausar/retomar
        if downloadInfo.status == .downloading {
            downloadService.pauseDownload(for: downloadInfo.versionId)
        } else {
            downloadService.resumeDownload(for: downloadInfo.versionId)
        }
    }
    
    private func cancelAction() {
        downloadService.cancelDownload(for: downloadInfo.versionId)
    }
}

/// Card de download melhorado com mais informações
struct EnhancedDownloadCard: View {
    let downloadInfo: DownloadInfo
    @StateObject private var downloadService = DownloadService.shared
    @StateObject private var versionService = MacOSVersionService.shared
    
    var version: MacOSVersion? {
        versionService.versions.first { $0.id == downloadInfo.versionId }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header com informações da versão
            HStack {
                // Ícone da versão
                MacOSIcon(version?.iconName, fallback: version?.systemImage ?? "desktopcomputer", size: 48)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(version?.name ?? "macOS Download")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let version = version {
                        Text("\(version.version) - Build \(version.buildNumber)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        statusBadge
                        
                        if downloadInfo.speed > 0 {
                            Text(downloadInfo.speedFormatted)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .clipShape(Capsule())
                        }
                    }
                }
                
                Spacer()
                
                // Botões de ação
                actionButtons
            }
            
            // Barra de progresso
            progressSection
            
            // Informações detalhadas
            if downloadInfo.status == .downloading || downloadInfo.status == .paused {
                detailsSection
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(progressColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: downloadInfo.status.systemImage)
                .font(.caption)
            
            Text(downloadInfo.status.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(progressColor.opacity(0.2))
        .foregroundColor(progressColor)
        .clipShape(Capsule())
    }
    
    private var progressColor: Color {
        switch downloadInfo.status {
        case .notStarted: return .secondary
        case .downloading: return .blue
        case .paused: return .orange
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .gray
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 8) {
            if downloadInfo.status == .downloading {
                Button("Pausar") {
                    downloadService.pauseDownload(for: downloadInfo.versionId)
                }
                .buttonStyle(.bordered)
            } else if downloadInfo.status == .paused {
                Button("Continuar") {
                    downloadService.resumeDownload(for: downloadInfo.versionId)
                }
                .buttonStyle(.borderedProminent)
            }
            
            Button("Cancelar") {
                downloadService.cancelDownload(for: downloadInfo.versionId)
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
        }
    }
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Progresso")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(downloadInfo.progress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(progressColor)
            }
            
            ProgressView(value: downloadInfo.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                .scaleEffect(x: 1, y: 1.5, anchor: .center)
        }
    }
    
    private var detailsSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Baixado")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(ByteCountFormatter.string(fromByteCount: downloadInfo.downloadedBytes, countStyle: .binary))
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            VStack(alignment: .center, spacing: 4) {
                Text("Total")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(ByteCountFormatter.string(fromByteCount: downloadInfo.totalBytes, countStyle: .binary))
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Tempo Restante")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(downloadInfo.estimatedTimeRemaining)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .padding(.top, 8)
    }
}

/// View de histórico melhorada
struct DownloadHistoryContentView: View {
    @StateObject private var downloadService = DownloadService.shared
    @StateObject private var versionService = MacOSVersionService.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Histórico de Downloads")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("\(downloadService.downloadHistory.count) downloads no histórico")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !downloadService.downloadHistory.isEmpty {
                    Button("Limpar Histórico") {
                        downloadService.downloadHistory.removeAll()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
            }
            .padding()
            .background(.regularMaterial)
            
            Divider()
            
            // Content
            if downloadService.downloadHistory.isEmpty {
                emptyHistoryView
            } else {
                historyList
            }
        }
    }
    
    private var emptyHistoryView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock")
                .font(.system(size: 80))
                .foregroundColor(.secondary.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("Nenhum download no histórico")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Downloads concluídos aparecerão aqui")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var historyList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(downloadService.downloadHistory) { download in
                    HistoryDownloadCard(downloadInfo: download)
                }
            }
            .padding()
        }
    }
}

/// Card para histórico de downloads
struct HistoryDownloadCard: View {
    let downloadInfo: DownloadInfo
    @StateObject private var versionService = MacOSVersionService.shared
    
    var version: MacOSVersion? {
        versionService.versions.first { $0.id == downloadInfo.versionId }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Ícone de status
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: downloadInfo.status.systemImage)
                    .foregroundColor(statusColor)
                    .font(.title3)
            }
            
            // Informações
            VStack(alignment: .leading, spacing: 4) {
                Text(version?.name ?? "macOS Download")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if let version = version {
                    Text("\(version.version) - Build \(version.buildNumber)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(downloadInfo.status.displayName)
                        .font(.caption)
                        .foregroundColor(statusColor)
                    
                    if let endTime = downloadInfo.endTime {
                        Text("• \(endTime, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Progresso final
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(downloadInfo.progress * 100))%")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(statusColor)
                
                if downloadInfo.totalBytes > 0 {
                    Text(ByteCountFormatter.string(fromByteCount: downloadInfo.totalBytes, countStyle: .binary))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(statusColor.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var statusColor: Color {
        switch downloadInfo.status {
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .gray
        default: return .secondary
        }
    }
}
