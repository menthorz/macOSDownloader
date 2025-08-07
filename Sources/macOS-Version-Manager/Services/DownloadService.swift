import Foundation
import Combine

/// Serviço responsável pelo gerenciamento de downloads das versões do macOS
@MainActor
class DownloadService: ObservableObject {
    static let shared = DownloadService()
    
    @Published var activeDownloads: [DownloadInfo] = []
    @Published var downloadHistory: [DownloadInfo] = []
    @Published var totalDownloadsCount: Int = 0
    @Published var activeDownloadsCount: Int = 0
    @Published var completedDownloadsCount: Int = 0
    
    private var urlSession: URLSession
    private var downloadTasks: [UUID: URLSessionDownloadTask] = [:]
    private var downloadInfos: [UUID: DownloadInfo] = [:]
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 0 // Sem timeout para downloads longos
        self.urlSession = URLSession(configuration: config)
    }
    
    /// Inicia o download de uma versão do macOS
    func startDownload(for version: MacOSVersion, to destination: URL) async throws {
        let downloadInfo = DownloadInfo(
            versionId: version.id,
            totalBytes: estimateFileSize(for: version)
        )
        
        downloadInfos[version.id] = downloadInfo
        activeDownloads.append(downloadInfo)
        updateCounters()
        
        guard let url = URL(string: version.downloadURL) else {
            throw DownloadError.invalidURL
        }
        
        let task = urlSession.downloadTask(with: url) { [weak self] localURL, response, error in
            Task { @MainActor in
                await self?.handleDownloadCompletion(
                    versionId: version.id,
                    localURL: localURL,
                    response: response,
                    error: error,
                    destination: destination
                )
            }
        }
        
        downloadTasks[version.id] = task
        downloadInfos[version.id]?.status = .downloading
        downloadInfos[version.id]?.startTime = Date()
        
        task.resume()
        
        // Monitorar progresso
        startProgressMonitoring(for: version.id, task: task)
    }
    
    /// Para o download de uma versão
    func pauseDownload(for versionId: UUID) {
        guard let task = downloadTasks[versionId] else { return }
        task.suspend()
        downloadInfos[versionId]?.status = .paused
        updateDownloadInfo(for: versionId)
    }
    
    /// Resume o download de uma versão
    func resumeDownload(for versionId: UUID) {
        guard let task = downloadTasks[versionId] else { return }
        task.resume()
        downloadInfos[versionId]?.status = .downloading
        updateDownloadInfo(for: versionId)
    }
    
    /// Cancela o download de uma versão
    func cancelDownload(for versionId: UUID) {
        guard let task = downloadTasks[versionId] else { return }
        task.cancel()
        downloadTasks.removeValue(forKey: versionId)
        
        if let index = activeDownloads.firstIndex(where: { $0.versionId == versionId }) {
            var downloadInfo = activeDownloads[index]
            downloadInfo.status = .cancelled
            downloadInfo.endTime = Date()
            
            activeDownloads.remove(at: index)
            downloadHistory.append(downloadInfo)
        }
        
        downloadInfos.removeValue(forKey: versionId)
        updateCounters()
    }
    
    /// Cancela todos os downloads ativos
    func cancelAllDownloads() {
        for versionId in downloadTasks.keys {
            cancelDownload(for: versionId)
        }
    }
    
    /// Retorna o status de download para uma versão específica
    func downloadStatus(for versionId: UUID) -> MacOSVersion.DownloadStatus {
        return downloadInfos[versionId]?.status ?? .notStarted
    }
    
    /// Retorna o progresso de download para uma versão específica
    func downloadProgress(for versionId: UUID) -> Double {
        return downloadInfos[versionId]?.progress ?? 0.0
    }
    
    /// Retorna informações detalhadas de download
    func downloadInfo(for versionId: UUID) -> DownloadInfo? {
        return downloadInfos[versionId]
    }
    
    // MARK: - Métodos Privados
    
    private func startProgressMonitoring(for versionId: UUID, task: URLSessionDownloadTask) {
        Task {
            while downloadTasks[versionId] != nil {
                await updateDownloadProgress(for: versionId)
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 segundos
            }
        }
    }
    
    private func updateDownloadProgress(for versionId: UUID) async {
        guard let downloadInfo = downloadInfos[versionId],
              let task = downloadTasks[versionId] else { return }
        
        let progress = task.progress
        let completedBytes = Int64(progress.completedUnitCount)
        let totalBytes = Int64(progress.totalUnitCount)
        
        downloadInfos[versionId]?.progress = progress.fractionCompleted
        downloadInfos[versionId]?.downloadedBytes = completedBytes
        
        if totalBytes > 0 {
            downloadInfos[versionId]?.totalBytes = totalBytes
        }
        
        // Calcular velocidade
        if let startTime = downloadInfo.startTime {
            let timeElapsed = Date().timeIntervalSince(startTime)
            if timeElapsed > 0 {
                downloadInfos[versionId]?.speed = Double(completedBytes) / timeElapsed
            }
        }
        
        updateDownloadInfo(for: versionId)
    }
    
    private func updateDownloadInfo(for versionId: UUID) {
        guard let downloadInfo = downloadInfos[versionId] else { return }
        
        if let index = activeDownloads.firstIndex(where: { $0.versionId == versionId }) {
            activeDownloads[index] = downloadInfo
        }
    }
    
    private func handleDownloadCompletion(
        versionId: UUID,
        localURL: URL?,
        response: URLResponse?,
        error: Error?,
        destination: URL
    ) async {
        defer {
            downloadTasks.removeValue(forKey: versionId)
            if let index = activeDownloads.firstIndex(where: { $0.versionId == versionId }) {
                let downloadInfo = activeDownloads[index]
                activeDownloads.remove(at: index)
                downloadHistory.append(downloadInfo)
            }
            updateCounters()
        }
        
        guard let downloadInfo = downloadInfos[versionId] else { return }
        
        if let error = error {
            downloadInfos[versionId]?.status = .failed
            downloadInfos[versionId]?.error = error.localizedDescription
            downloadInfos[versionId]?.endTime = Date()
            return
        }
        
        guard let localURL = localURL else {
            downloadInfos[versionId]?.status = .failed
            downloadInfos[versionId]?.error = "URL local não encontrada"
            downloadInfos[versionId]?.endTime = Date()
            return
        }
        
        do {
            // Criar diretório de destino se não existir
            try FileManager.default.createDirectory(
                at: destination.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            
            // Mover arquivo para destino final
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            
            try FileManager.default.moveItem(at: localURL, to: destination)
            
            downloadInfos[versionId]?.status = .completed
            downloadInfos[versionId]?.progress = 1.0
            downloadInfos[versionId]?.endTime = Date()
            
        } catch {
            downloadInfos[versionId]?.status = .failed
            downloadInfos[versionId]?.error = error.localizedDescription
            downloadInfos[versionId]?.endTime = Date()
        }
    }
    
    private func estimateFileSize(for version: MacOSVersion) -> Int64 {
        // Estimativas baseadas no tipo de instalador
        if version.name.contains("High Sierra") || version.name.contains("Mojave") || version.name.contains("Catalina") {
            return 6_000_000_000 // ~6GB para .dmg
        } else {
            return 12_000_000_000 // ~12GB para InstallAssistant.pkg
        }
    }
    
    private func updateCounters() {
        totalDownloadsCount = activeDownloads.count + downloadHistory.count
        activeDownloadsCount = activeDownloads.count
        completedDownloadsCount = downloadHistory.filter { $0.status == .completed }.count
    }
}

/// Erros relacionados ao download
enum DownloadError: LocalizedError {
    case invalidURL
    case fileNotFound
    case permissionDenied
    case networkError(String)
    case diskSpaceInsufficient
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL de download inválida"
        case .fileNotFound:
            return "Arquivo não encontrado"
        case .permissionDenied:
            return "Permissão negada para salvar o arquivo"
        case .networkError(let message):
            return "Erro de rede: \(message)"
        case .diskSpaceInsufficient:
            return "Espaço em disco insuficiente"
        }
    }
}
