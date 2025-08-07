import SwiftUI
import AppKit

/// Helper para carregar ícones .icns do bundle
struct IconHelper {
    /// Carrega uma imagem .icns do bundle de recursos
    static func loadIcon(named iconName: String) -> NSImage? {
        // Primeiro tenta carregar do bundle principal
        if let image = NSImage(named: iconName) {
            return image
        }
        
        // Tenta carregar diretamente do Resources
        if let resourcesURL = Bundle.main.resourceURL?.appendingPathComponent("\(iconName).icns"),
           let image = NSImage(contentsOf: resourcesURL) {
            return image
        }
        
        // Tenta carregar do bundle de recursos SwiftPM
        if let bundle = Bundle.main.url(forResource: "macOS-Version-Manager_macOS-Version-Manager", withExtension: "bundle"),
              let resourceBundle = Bundle(url: bundle),
              let imageURL = resourceBundle.url(forResource: iconName, withExtension: "icns"),
           let image = NSImage(contentsOf: imageURL) {
            return image
        }
        
        return nil
    }
}

/// Extensão para criar um View do SwiftUI a partir do NSImage
extension NSImage {
    func swiftUIImage() -> Image {
        return Image(nsImage: self)
    }
}

/// View customizada para exibir ícones do macOS
struct MacOSIcon: View {
    let iconName: String?
    let fallbackSystemImage: String
    let size: CGFloat
    
    init(_ iconName: String?, fallback: String = "desktopcomputer", size: CGFloat = 40) {
        self.iconName = iconName
        self.fallbackSystemImage = fallback
        self.size = size
    }
    
    var body: some View {
        Group {
            if let iconName = iconName,
               let nsImage = IconHelper.loadIcon(named: iconName) {
                nsImage.swiftUIImage()
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            } else {
                Image(systemName: fallbackSystemImage)
                    .font(.system(size: size * 0.6))
                    .foregroundColor(.white)
            }
        }
    }
}
