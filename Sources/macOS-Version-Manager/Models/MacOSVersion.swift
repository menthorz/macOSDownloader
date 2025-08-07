import Foundation

/// Representa uma versão do macOS disponível para download
struct MacOSVersion: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let version: String
    let buildNumber: String
    let downloadURL: String
    let fileSize: String
    let releaseDate: Date
    let isSupported: Bool
    let isBeta: Bool
    let iconName: String? // Nome do arquivo .icns na pasta Assets
    
    /// Status do download
    enum DownloadStatus: String, CaseIterable, Codable {
        case notStarted = "not_started"
        case downloading = "downloading"
        case paused = "paused"
        case completed = "completed"
        case failed = "failed"
        case cancelled = "cancelled"
        
        var displayName: String {
            switch self {
            case .notStarted: return "Não Iniciado"
            case .downloading: return "Baixando"
            case .paused: return "Pausado"
            case .completed: return "Concluído"
            case .failed: return "Falhou"
            case .cancelled: return "Cancelado"
            }
        }
        
        var systemImage: String {
            switch self {
            case .notStarted: return "circle"
            case .downloading: return "arrow.down.circle.fill"
            case .paused: return "pause.circle.fill"
            case .completed: return "checkmark.circle.fill"
            case .failed: return "xmark.circle.fill"
            case .cancelled: return "minus.circle.fill"
            }
        }
    }
    
    var downloadStatus: DownloadStatus = .notStarted
    var downloadProgress: Double = 0.0
    var downloadedBytes: Int64 = 0
    var totalBytes: Int64 = 0
    var downloadSpeed: String = ""
    var estimatedTimeRemaining: String = ""
    
    /// Categoria da versão
    var category: MacOSCategory {
        if isBeta {
            return .beta
        } else if name.contains("Tahoe") {
            return .latest
        } else {
            return .stable
        }
    }
    
    /// Ícone da versão
    var systemImage: String {
        switch name {
        case let name where name.contains("High Sierra"):
            return "mountain.2.fill"
        case let name where name.contains("Mojave"):
            return "sunset.fill"
        case let name where name.contains("Catalina"):
            return "location.fill"
        case let name where name.contains("Big Sur"):
            return "mountain.2.circle.fill"
        case let name where name.contains("Monterey"):
            return "water.waves"
        case let name where name.contains("Ventura"):
            return "beach.umbrella.fill"
        case let name where name.contains("Sonoma"):
            return "sun.max.fill"
        case let name where name.contains("Sequoia"):
            return "tree.fill"
        case let name where name.contains("Tahoe"):
            return "snowflake"
        default:
            return "desktopcomputer"
        }
    }
    
    /// Cor da versão
    var accentColor: String {
        switch category {
        case .latest: return "blue"
        case .beta: return "orange"
        case .stable: return "green"
        case .legacy: return "gray"
        }
    }
}

/// Categorias das versões do macOS
enum MacOSCategory: String, CaseIterable, Codable {
    case latest = "latest"
    case beta = "beta"
    case stable = "stable"
    case legacy = "legacy"
    
    var displayName: String {
        switch self {
        case .latest: return "Mais Recente"
        case .beta: return "Beta"
        case .stable: return "Estável"
        case .legacy: return "Legado"
        }
    }
    
    var systemImage: String {
        switch self {
        case .latest: return "star.fill"
        case .beta: return "flask.fill"
        case .stable: return "checkmark.shield.fill"
        case .legacy: return "clock.fill"
        }
    }
}

/// Informações de download em tempo real
struct DownloadInfo: Identifiable {
    let id = UUID()
    let versionId: UUID
    var progress: Double = 0.0
    var status: MacOSVersion.DownloadStatus = .notStarted
    var downloadedBytes: Int64 = 0
    var totalBytes: Int64 = 0
    var speed: Double = 0.0 // bytes per second
    var startTime: Date?
    var endTime: Date?
    var error: String?
    
    var speedFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(speed), countStyle: .binary) + "/s"
    }
    
    var estimatedTimeRemaining: String {
        guard speed > 0, totalBytes > downloadedBytes else { return "—" }
        let remainingBytes = totalBytes - downloadedBytes
        let timeRemaining = Double(remainingBytes) / speed
        
        if timeRemaining < 60 {
            return String(format: "%.0fs", timeRemaining)
        } else if timeRemaining < 3600 {
            return String(format: "%.0fm", timeRemaining / 60)
        } else {
            return String(format: "%.1fh", timeRemaining / 3600)
        }
    }
}
