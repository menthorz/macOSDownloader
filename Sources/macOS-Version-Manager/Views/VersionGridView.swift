import SwiftUI

/// View que exibe as versões em formato de grid moderno
struct VersionGridView: View {
    let versions: [MacOSVersion]
    @Binding var searchText: String
    @StateObject private var downloadService = DownloadService.shared
    @State private var selectedVersion: MacOSVersion?
    @State private var showingDownloadSheet = false
    @State private var downloadDestination: URL?
    
    private let columns = [
        GridItem(.adaptive(minimum: 320, maximum: 400), spacing: 16)
    ]
    
    var body: some View {
        Group {
            if versions.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(versions) { version in
                            VersionCard(
                                version: version,
                                downloadStatus: downloadService.downloadStatus(for: version.id),
                                downloadProgress: downloadService.downloadProgress(for: version.id),
                                downloadInfo: downloadService.downloadInfo(for: version.id)
                            ) {
                                handleDownloadAction(for: version)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingDownloadSheet) {
            if let version = selectedVersion {
                DownloadConfigurationSheet(
                    version: version,
                    isPresented: $showingDownloadSheet
                )
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("Nenhuma versão encontrada")
                .font(.title2)
                .fontWeight(.semibold)
            
            if !searchText.isEmpty {
                Text("Tente ajustar os termos de busca")
                    .foregroundColor(.secondary)
                
                Button("Limpar busca") {
                    searchText = ""
                }
                .buttonStyle(.borderedProminent)
            } else {
                Text("Selecione uma categoria na barra lateral")
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func handleDownloadAction(for version: MacOSVersion) {
        let status = downloadService.downloadStatus(for: version.id)
        
        switch status {
        case .notStarted:
            selectedVersion = version
            showingDownloadSheet = true
            
        case .downloading:
            downloadService.pauseDownload(for: version.id)
            
        case .paused:
            downloadService.resumeDownload(for: version.id)
            
        case .completed:
            // Mostrar no Finder
            showInFinder(version: version)
            
        case .failed, .cancelled:
            // Tentar novamente
            selectedVersion = version
            showingDownloadSheet = true
        }
    }
    
    private func showInFinder(version: MacOSVersion) {
        // Implementar mostrar no Finder
        let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let versionURL = downloadsURL.appendingPathComponent("\(version.name).pkg")
        
        if FileManager.default.fileExists(atPath: versionURL.path) {
            NSWorkspace.shared.selectFile(versionURL.path, inFileViewerRootedAtPath: downloadsURL.path)
        }
    }
}

/// Card individual para cada versão do macOS
struct VersionCard: View {
    let version: MacOSVersion
    let downloadStatus: MacOSVersion.DownloadStatus
    let downloadProgress: Double
    let downloadInfo: DownloadInfo?
    let onDownloadAction: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and version info
            HStack {
                // Version Icon
                MacOSIcon(version.iconName, fallback: version.systemImage, size: 48)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(version.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    Text(version.version)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Build \(version.buildNumber)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status Badge
                statusBadge
            }
            
            // Version Details
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                        .frame(width: 16)
                    
                    Text(version.releaseDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "internaldrive")
                        .foregroundColor(.secondary)
                        .frame(width: 16)
                    
                    Text(version.fileSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if version.isBeta {
                    HStack {
                        Image(systemName: "flask")
                            .foregroundColor(.orange)
                            .frame(width: 16)
                        
                        Text("Versão Beta")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // Download Progress (if downloading)
            if downloadStatus == .downloading || downloadStatus == .paused {
                downloadProgressView
            }
            
            // Download Button
            downloadButton
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHovered ? .blue : .clear, lineWidth: 2)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: downloadStatus.systemImage)
                .font(.caption)
            
            Text(downloadStatus.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.2))
        .foregroundColor(statusColor)
        .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch downloadStatus {
        case .notStarted: return .secondary
        case .downloading: return .blue
        case .paused: return .orange
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .gray
        }
    }
    
    private var downloadProgressView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Progresso")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(downloadProgress * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            ProgressView(value: downloadProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            
            if let info = downloadInfo {
                HStack {
                    if info.speed > 0 {
                        Text(info.speedFormatted)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(info.estimatedTimeRemaining)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var downloadButton: some View {
        Button(action: onDownloadAction) {
            HStack {
                Image(systemName: downloadButtonIcon)
                Text(downloadButtonText)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.regular)
        .disabled(downloadStatus == .downloading && downloadProgress > 0)
    }
    
    private var downloadButtonIcon: String {
        switch downloadStatus {
        case .notStarted: return "arrow.down.circle"
        case .downloading: return "pause.circle"
        case .paused: return "play.circle"
        case .completed: return "folder"
        case .failed, .cancelled: return "arrow.clockwise"
        }
    }
    
    private var downloadButtonText: String {
        switch downloadStatus {
        case .notStarted: return "Baixar"
        case .downloading: return "Pausar"
        case .paused: return "Continuar"
        case .completed: return "Mostrar no Finder"
        case .failed: return "Tentar Novamente"
        case .cancelled: return "Baixar Novamente"
        }
    }
}

#Preview {
    VersionGridView(
        versions: MacOSVersionService.shared.versions,
        searchText: .constant("")
    )
    .frame(width: 800, height: 600)
}
