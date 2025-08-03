//
//  ContentView.swift
//  macOSDownloader
//
//  Created by Raphael Souza on 02/08/25.
//

import SwiftUI
import Network

struct MacOSVersion: Identifiable {
    let id = UUID()
    let name: String
    let build: String
    let isBeta: Bool
    let installerVersion: String?
    let downloadURL: String?
    let size: String?
}

class SpeedTestManager: ObservableObject {
    @Published var isTestingSpeed = false
    @Published var downloadSpeed: Double = 0 // Mbps
    @Published var speedTestResult = ""
    
    func testDownloadSpeed() {
        isTestingSpeed = true
        speedTestResult = "Testando velocidade..."
        
        // URL de teste da Apple (arquivo pequeno para teste)
        guard let url = URL(string: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP751/macOS_big_sur.jpg") else {
            speedTestResult = "Erro: URL inválida"
            isTestingSpeed = false
            return
        }
        
        let startTime = Date()
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isTestingSpeed = false
                
                if let error = error {
                    self?.speedTestResult = "Erro: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self?.speedTestResult = "Erro: Nenhum dado recebido"
                    return
                }
                
                let endTime = Date()
                let timeInterval = endTime.timeIntervalSince(startTime)
                let bytesDownloaded = Double(data.count)
                let speedBytesPerSecond = bytesDownloaded / timeInterval
                let speedMbps = (speedBytesPerSecond * 8) / 1_000_000 // Convert to Mbps
                
                self?.downloadSpeed = speedMbps
                
                if speedMbps > 25 {
                    self?.speedTestResult = "🚀 Excelente: \(String(format: "%.2f", speedMbps)) Mbps - Ideal para downloads grandes"
                } else if speedMbps > 10 {
                    self?.speedTestResult = "✅ Boa: \(String(format: "%.2f", speedMbps)) Mbps - Adequada para downloads"
                } else if speedMbps > 5 {
                    self?.speedTestResult = "⚠️ Regular: \(String(format: "%.2f", speedMbps)) Mbps - Download pode ser lento"
                } else {
                    self?.speedTestResult = "🐌 Lenta: \(String(format: "%.2f", speedMbps)) Mbps - Considere usar uma conexão melhor"
                }
            }
        }.resume()
    }
}

class DownloadManager: NSObject, ObservableObject {
    @Published var isDownloading: Bool = false
    @Published var downloadProgress: Double = 0.0
    @Published var totalBytesExpected: Int64 = 0
    @Published var totalBytesWritten: Int64 = 0
    @Published var downloadSpeed: Double = 0 // bytes/sec
    @Published var estimatedTimeRemaining: Double = 0 // seconds
    @Published var downloadedFileURL: URL?
    @Published var log: String = ""
    
    private var downloadTask: URLSessionDownloadTask?
    private var session: URLSession?
    private var lastBytesWritten: Int64 = 0
    private var lastUpdateTime: Date = Date()

    func startDownload(from urlString: String, fileName: String) {
        guard let url = URL(string: urlString) else {
            log += "❌ URL inválida: \(urlString)\n"
            return
        }
        
        isDownloading = true
        downloadProgress = 0
        downloadedFileURL = nil
        totalBytesExpected = 0
        totalBytesWritten = 0
        downloadSpeed = 0
        estimatedTimeRemaining = 0
        lastBytesWritten = 0
        lastUpdateTime = Date()
        log += "🚀 Iniciando download de \(fileName)...\n"
        log += "📥 URL: \(urlString)\n"

        let config = URLSessionConfiguration.default
        session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
        downloadTask = session?.downloadTask(with: url)
        downloadTask?.resume()
    }
    
    func cancelDownload() {
        downloadTask?.cancel()
        isDownloading = false
        log += "\n🛑 Download cancelado pelo usuário\n"
    }
}

extension DownloadManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        
        downloadProgress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        self.totalBytesExpected = totalBytesExpectedToWrite
        self.totalBytesWritten = totalBytesWritten

        let now = Date()
        let timeInterval = now.timeIntervalSince(lastUpdateTime)
        if timeInterval > 1.0 { // update every second
            let bytesDelta = totalBytesWritten - lastBytesWritten
            downloadSpeed = Double(bytesDelta) / timeInterval
            if downloadSpeed > 0 {
                estimatedTimeRemaining = Double(totalBytesExpectedToWrite - totalBytesWritten) / downloadSpeed
            }
            lastBytesWritten = totalBytesWritten
            lastUpdateTime = now
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        
        // Criar nome mais específico baseado na versão baixada
        var fileName = "InstallAssistant.pkg"
        
        // Tentar extrair informações da resposta HTTP
        if let response = downloadTask.response as? HTTPURLResponse {
            // Usar Content-Disposition se disponível
            if let contentDisposition = response.allHeaderFields["Content-Disposition"] as? String,
               contentDisposition.contains("filename=") {
                let components = contentDisposition.components(separatedBy: "filename=")
                if components.count > 1 {
                    fileName = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: "\"", with: "")
                }
            }
            
            // Fallback: usar URL path
            if fileName == "InstallAssistant.pkg",
               let url = downloadTask.originalRequest?.url,
               url.lastPathComponent.hasSuffix(".pkg") {
                fileName = url.lastPathComponent
            }
        }
        
        // Se ainda for genérico, criar nome descritivo
        if fileName == "InstallAssistant.pkg" {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            fileName = "macOS_InstallAssistant_\(dateFormatter.string(from: Date())).pkg"
        }
        
        // Garantir extensão .pkg
        if !fileName.hasSuffix(".pkg") {
            fileName += ".pkg"
        }
        
        let destinationURL = downloadsURL.appendingPathComponent(fileName)
        
        do {
            // Verificar se é realmente um arquivo PKG válido
            let fileSize = try FileManager.default.attributesOfItem(atPath: location.path)[.size] as? Int64 ?? 0
            
            // Verificação mais rigorosa para arquivos pequenos
            if fileSize < 5000000 { // Menos de 5MB é suspeito para um instalador macOS
                let content = try? String(contentsOf: location, encoding: .utf8)
                if let content = content {
                    if content.contains("<!DOCTYPE") || content.contains("<html") || content.contains("404") {
                        throw NSError(domain: "DownloadError", code: 1, userInfo: [
                            NSLocalizedDescriptionKey: "❌ Link retornou página web em vez do instalador PKG.\n💡 O link pode estar expirado ou incorreto."
                        ])
                    }
                }
                
                // Se não conseguir ler como texto, ainda assim alerta sobre o tamanho
                if fileSize < 1000000 { // Menos de 1MB definitivamente não é um instalador
                    throw NSError(domain: "DownloadError", code: 2, userInfo: [
                        NSLocalizedDescriptionKey: "❌ Arquivo muito pequeno (\(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))).\n💡 Instaladores macOS têm pelo menos 10GB."
                    ])
                }
            }
            
            // Remover arquivo existente se houver
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            // Mover arquivo temporário para destino final
            try FileManager.default.moveItem(at: location, to: destinationURL)
            downloadedFileURL = destinationURL
            
            DispatchQueue.main.async {
                self.log += "\n✅ Download concluído com sucesso!\n"
                self.log += "📁 Arquivo salvo em: \(destinationURL.path)\n"
                self.log += "📦 Nome do arquivo: \(fileName)\n"
                self.log += "💾 Tamanho: \(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))\n"
                
                // Verificação de validez mais inteligente
                if fileSize > 5_000_000_000 { // Maior que 5GB
                    self.log += "✅ Arquivo PKG de instalador macOS válido detectado\n"
                    self.log += "🎉 Pronto para instalação!\n"
                } else if fileSize > 100_000_000 { // Maior que 100MB
                    self.log += "⚠️ Arquivo PKG pequeno - pode ser um instalador delta ou parcial\n"
                } else {
                    self.log += "❌ Arquivo muito pequeno - provavelmente não é um instalador válido\n"
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.log += "\n❌ Erro: \(error.localizedDescription)\n"
                self.log += "📍 Arquivo temporário em: \(location.path)\n"
                self.log += "💡 Dica: Verifique se o link está correto e não expirou\n"
                self.downloadedFileURL = nil
            }
        }
        
        DispatchQueue.main.async {
            self.isDownloading = false
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                self.log += "\n❌ Erro no download: \(error.localizedDescription)\n"
            }
            self.isDownloading = false
        }
    }
}

struct ContentView: View {
    @State private var versions: [MacOSVersion] = [
        MacOSVersion(
            name: "macOS Sequoia 15.6",
            build: "24G84",
            isBeta: false,
            installerVersion: "15.6",
            downloadURL: "https://swcdn.apple.com/content/downloads/05/14/082-08661-A_R3LJXRMIED/4ifxu7v20f45p4qectnt7r52qwt9vuzfw1/InstallAssistant.pkg",
            size: "~13.7 GB"
        ),
        MacOSVersion(
            name: "macOS Sonoma 14.7.7",
            build: "23G93",
            isBeta: false,
            installerVersion: "14.7.7",
            downloadURL: "https://swcdn.apple.com/content/downloads/03/49/082-85709-A_OVYS4G5L94/y1wfe9zpaqu9mjnl3zjtq41n0qtb21kvcs/InstallAssistant.pkg",
            size: "~13.1 GB"
        ),
        MacOSVersion(
            name: "macOS Ventura 13.7.7",
            build: "22G830",
            isBeta: false,
            installerVersion: "13.7.7",
            downloadURL:
                "https://swcdn.apple.com/content/downloads/12/28/082-87267-A_WGJHPIPC6Q/e982ujmntb0d6l44kjd20dc5thmk1ynorw/InstallAssistant.pkg",
            size: "~12.8 GB"
        ),
        MacOSVersion(
            name: "macOS Monterey 12.7.6",
            build: "21H1320",
            isBeta: false,
            installerVersion: "12.7.6",
            downloadURL: "https://swcdn.apple.com/content/downloads/34/21/062-40406-A_GZQ27OUQER/ggclib72ow1omcvfexvp84bc9x5ei5tyqu/InstallAssistant.pkg",
            size: "~12.2 GB"
        ),
        MacOSVersion(
            name: "macOS Big Sur 11.7.10",
            build: "20G1427",
            isBeta: false,
            installerVersion: "11.7.10",
            downloadURL: "ihttp://swcdn.apple.com/content/downloads/14/38/042-45246-A_NLFOFLCJFZ/jk992zbv98sdzz3rgc7mrccjl3l22ruk1c/InstallAssistant.pkg",
            size: "~12.2 GB"
        )
    ]
    @StateObject private var downloadManager = DownloadManager()
    @StateObject private var speedTestManager = SpeedTestManager()
    @State private var selectedVersion: MacOSVersion?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("macOS Versions Downloader")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Baixe instaladores completos do macOS diretamente dos servidores da Apple")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Botão de teste de velocidade
                Button("📊 Testar Velocidade da Conexão") {
                    speedTestManager.testDownloadSpeed()
                }
                .buttonStyle(.bordered)
                .disabled(speedTestManager.isTestingSpeed || downloadManager.isDownloading)
            }
            .padding(.top, 24)

            // Resultado do teste de velocidade
            if speedTestManager.isTestingSpeed || !speedTestManager.speedTestResult.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if speedTestManager.isTestingSpeed {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Testando velocidade da conexão...")
                                .font(.headline)
                        } else {
                            Text("Resultado do Teste de Velocidade:")
                                .font(.headline)
                        }
                    }
                    
                    if !speedTestManager.speedTestResult.isEmpty {
                        Text(speedTestManager.speedTestResult)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                speedTestManager.downloadSpeed > 10 ? 
                                Color.green.opacity(0.1) : 
                                speedTestManager.downloadSpeed > 5 ?
                                Color.orange.opacity(0.1) :
                                Color.red.opacity(0.1)
                            )
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }

            // Lista de versões
            List(versions) { version in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(version.name) (\(version.build))")
                            .font(.headline)
                        
                        HStack {
                            Text("Estável")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(4)
                            
                            if let size = version.size {
                                Text(size)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let installerVersion = version.installerVersion {
                                Text("v\(installerVersion)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        selectedVersion = version
                        if let downloadURL = version.downloadURL {
                            downloadManager.startDownload(from: downloadURL, fileName: version.name)
                        }
                    }) {
                        Text(downloadManager.isDownloading && selectedVersion?.id == version.id ? "Baixando..." : "Download")
                            .frame(minWidth: 80)
                    }
                    .disabled(downloadManager.isDownloading || speedTestManager.isTestingSpeed || version.downloadURL == nil)
                    .buttonStyle(.borderedProminent)
                }
                .padding(.vertical, 4)
            }
            .frame(minHeight: 250)

            // Progresso do download
            if downloadManager.isDownloading {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Baixando: \(selectedVersion?.name ?? "Instalador")")
                            .font(.headline)
                        Spacer()
                        Button("Cancelar") {
                            downloadManager.cancelDownload()
                        }
                        .foregroundColor(.red)
                    }
                    
                    ProgressView(value: downloadManager.downloadProgress)
                        .frame(maxWidth: .infinity)
                    
                    HStack {
                        Text(String(format: "%.1f%%", downloadManager.downloadProgress * 100))
                            .font(.caption)
                        Spacer()
                        if downloadManager.totalBytesExpected > 0 {
                            Text("\(ByteCountFormatter.string(fromByteCount: downloadManager.totalBytesWritten, countStyle: .file)) de \(ByteCountFormatter.string(fromByteCount: downloadManager.totalBytesExpected, countStyle: .file))")
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.secondary)
                    
                    HStack {
                        if downloadManager.downloadSpeed > 0 {
                            Text("Velocidade: \(ByteCountFormatter.string(fromByteCount: Int64(downloadManager.downloadSpeed), countStyle: .file))/s")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if downloadManager.estimatedTimeRemaining > 0 && downloadManager.estimatedTimeRemaining < 86400 {
                            Text("Tempo restante: \(formatTime(downloadManager.estimatedTimeRemaining))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }

            // Log
            if !downloadManager.log.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Log de Download:")
                            .font(.headline)
                        Spacer()
                        Button("Limpar Log") {
                            downloadManager.log = ""
                        }
                        .font(.caption)
                    }
                    
                    ScrollView {
                        ScrollViewReader { proxy in
                            Text(downloadManager.log)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id("logEnd")
                                .onChange(of: downloadManager.log) {
                                    proxy.scrollTo("logEnd", anchor: .bottom)
                                }
                        }
                    }
                    .frame(height: 120)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding()
        .frame(minWidth: 550, minHeight: 700)
    }
}

// Função auxiliar para formatar tempo
func formatTime(_ seconds: Double) -> String {
    let intSec = Int(seconds)
    let hours = intSec / 3600
    let minutes = (intSec % 3600) / 60
    let secs = intSec % 60
    
    if hours > 0 {
        return "\(hours)h \(minutes)m"
    } else if minutes > 0 {
        return "\(minutes)m \(secs)s"
    } else {
        return "\(secs)s"
    }
}
