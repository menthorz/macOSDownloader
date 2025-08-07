import Foundation

/// Serviço responsável por fornecer as versões do macOS disponíveis
class MacOSVersionService: ObservableObject {
    static let shared = MacOSVersionService()
    
    @Published var versions: [MacOSVersion] = []
    @Published var isLoading = false
    
    private init() {
        loadVersions()
    }
    
    /// Carrega as versões do macOS disponíveis
    func loadVersions() {
        isLoading = true
        
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        
        versions = [
            MacOSVersion(
                id: UUID(),
                name: "macOS High Sierra",
                version: "10.13.6",
                buildNumber: "17G66",
                downloadURL: "http://swcdn.apple.com/content/downloads/06/50/041-91758-A_M8T44LH2AW/b5r4og05fhbgatve4agwy4kgkzv07mdid9/InstallESDDmg.pkg",
                fileSize: "6.2 GB",
                releaseDate: calendar.date(from: DateComponents(year: 2017, month: 9, day: 25)) ?? Date(),
                isSupported: false,
                isBeta: false,
                iconName: "high_sierra"
            ),
            MacOSVersion(
                id: UUID(),
                name: "macOS Mojave",
                version: "10.14.6",
                buildNumber: "18E2034",
                downloadURL: "https://swcdn.apple.com/content/downloads/34/54/041-88800-A_HLMBDM42FL/anrmoj880qkj0lbybqm0c3830p70nawjrv/InstallESDDmg.pkg",
                fileSize: "6.0 GB",
                releaseDate: calendar.date(from: DateComponents(year: 2018, month: 9, day: 24)) ?? Date(),
                isSupported: false,
                isBeta: false,
                iconName: "mojave"
            ),
            MacOSVersion(
                id: UUID(),
                name: "macOS Catalina",
                version: "10.15.7",
                buildNumber: "19H15",
                downloadURL: "https://swcdn.apple.com/content/downloads/26/37/001-68446/r1dbqtmf3mtpikjnd04cq31p4jk91dceh8/InstallESDDmg.pkg",
                fileSize: "8.1 GB",
                releaseDate: calendar.date(from: DateComponents(year: 2019, month: 10, day: 7)) ?? Date(),
                isSupported: false,
                isBeta: false,
                iconName: "catalina"
            ),
            MacOSVersion(
                id: UUID(),
                name: "macOS Big Sur",
                version: "11.7.10",
                buildNumber: "20G1427",
                downloadURL: "https://swcdn.apple.com/content/downloads/14/38/042-45246-A_NLFOFLCJFZ/jk992zbv98sdzz3rgc7mrccjl3l22ruk1c/InstallAssistant.pkg",
                fileSize: "12.2 GB",
                releaseDate: calendar.date(from: DateComponents(year: 2020, month: 11, day: 12)) ?? Date(),
                isSupported: true,
                isBeta: false,
                iconName: "bigsur"
            ),
            MacOSVersion(
                id: UUID(),
                name: "macOS Monterey",
                version: "12.7.6",
                buildNumber: "21H1317",
                downloadURL: "https://swcdn.apple.com/content/downloads/15/20/062-34032-A_DG93IYL5D1/jf48kftd5bwap0ksfodxuzwo5kba3kmkes/InstallAssistant.pkg",
                fileSize: "12.1 GB",
                releaseDate: calendar.date(from: DateComponents(year: 2021, month: 10, day: 25)) ?? Date(),
                isSupported: true,
                isBeta: false,
                iconName: "monterey"
            ),
            MacOSVersion(
                id: UUID(),
                name: "macOS Ventura",
                version: "13.7.7",
                buildNumber: "22H722",
                downloadURL: "https://swcdn.apple.com/content/downloads/12/28/082-87267-A_WGJHPIPC6Q/e982ujmntb0d6l44kjd20dc5thmk1ynorw/InstallAssistant.pkg",
                fileSize: "11.9 GB",
                releaseDate: calendar.date(from: DateComponents(year: 2022, month: 10, day: 24)) ?? Date(),
                isSupported: true,
                isBeta: false,
                iconName: "ventura"
            ),
            MacOSVersion(
                id: UUID(),
                name: "macOS Sonoma",
                version: "14.7.7",
                buildNumber: "23H623",
                downloadURL: "https://swcdn.apple.com/content/downloads/03/49/082-85709-A_OVYS4G5L94/y1wfe9zpaqu9mjnl3zjtq41n0qtb21kvcs/InstallAssistant.pkg",
                fileSize: "13.0 GB",
                releaseDate: calendar.date(from: DateComponents(year: 2023, month: 9, day: 26)) ?? Date(),
                isSupported: true,
                isBeta: false,
                iconName: "sonoma"
            ),
            MacOSVersion(
                id: UUID(),
                name: "macOS Sequoia",
                version: "15.6",
                buildNumber: "24G84",
                downloadURL: "https://swcdn.apple.com/content/downloads/05/14/082-08661-A_R3LJXRMIED/4ifxu7v20f45p4qectnt7r52qwt9vuzfw1/InstallAssistant.pkg",
                fileSize: "13.5 GB",
                releaseDate: calendar.date(from: DateComponents(year: 2024, month: 9, day: 16)) ?? Date(),
                isSupported: true,
                isBeta: false,
                iconName: "sequoia"
            )
        ]
        
        isLoading = false
    }
    
    /// Filtra versões por categoria
    func versions(for category: MacOSCategory) -> [MacOSVersion] {
        return versions.filter { $0.category == category }
    }
    
    /// Busca versões por nome
    func searchVersions(query: String) -> [MacOSVersion] {
        guard !query.isEmpty else { return versions }
        
        return versions.filter { version in
            version.name.localizedCaseInsensitiveContains(query) ||
            version.version.localizedCaseInsensitiveContains(query) ||
            version.buildNumber.localizedCaseInsensitiveContains(query)
        }
    }
    
    /// Retorna a versão mais recente
    var latestVersion: MacOSVersion? {
        return versions.filter { !$0.isBeta }.max(by: { $0.releaseDate < $1.releaseDate })
    }
    
    /// Retorna a versão beta mais recente
    var latestBetaVersion: MacOSVersion? {
        return versions.filter { $0.isBeta }.max(by: { $0.releaseDate < $1.releaseDate })
    }
}
