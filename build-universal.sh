#!/bin/bash

# macOS Version Manager - Script de Build Universal
# Compila para arquitetura universal e gera app bundle

set -e

echo "🍎 macOS Version Manager - Build Universal"
echo "==========================================="

PROJECT_DIR="$(dirname "$0")"
cd "$PROJECT_DIR"

APP_NAME="macOS Version Manager"
BUNDLE_NAME="$APP_NAME.app"
EXECUTABLE_NAME="macOS-Version-Manager"

echo "📦 Limpando builds anteriores..."
rm -rf .build
rm -rf "$BUNDLE_NAME"

echo "🔨 Compilando para arquitetura universal (ARM64 + x86_64)..."
swift build -c release --arch arm64 --arch x86_64

if [ $? -ne 0 ]; then
    echo "❌ Erro na compilação!"
    exit 1
fi

echo "✅ Compilação concluída!"

echo "📱 Criando app bundle..."

# Criar estrutura do app bundle
mkdir -p "$BUNDLE_NAME/Contents/MacOS"
mkdir -p "$BUNDLE_NAME/Contents/Resources"

# Copiar binário universal
cp ".build/apple/Products/Release/$EXECUTABLE_NAME" "$BUNDLE_NAME/Contents/MacOS/"

# Verificar se é realmente universal
echo "🔍 Verificando arquiteturas..."
file "$BUNDLE_NAME/Contents/MacOS/$EXECUTABLE_NAME"

# Definir permissões corretas
chmod +x "$BUNDLE_NAME/Contents/MacOS/$EXECUTABLE_NAME"

# Criar Info.plist
cat > "$BUNDLE_NAME/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleDisplayName</key>
	<string>$APP_NAME</string>
	<key>CFBundleExecutable</key>
	<string>$EXECUTABLE_NAME</string>
	<key>CFBundleIdentifier</key>
	<string>com.developer.macos-version-manager</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>$APP_NAME</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>LSMinimumSystemVersion</key>
	<string>13.0</string>
	<key>LSRequiresNativeExecution</key>
	<true/>
	<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSAllowsArbitraryLoads</key>
		<true/>
		<key>NSExceptionDomains</key>
		<dict>
			<key>swcdn.apple.com</key>
			<dict>
				<key>NSExceptionAllowsInsecureHTTPLoads</key>
				<true/>
				<key>NSExceptionMinimumTLSVersion</key>
				<string>TLSv1.0</string>
			</dict>
		</dict>
	</dict>
	<key>NSHighResolutionCapable</key>
	<true/>
	<key>NSHumanReadableCopyright</key>
	<string>Copyright © 2025. All rights reserved.</string>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
	<key>NSSupportsAutomaticGraphicsSwitching</key>
	<true/>
	<key>NSDesktopFolderUsageDescription</key>
	<string>Esta app precisa acessar a pasta Desktop para salvar downloads de versões do macOS.</string>
	<key>NSDownloadsFolderUsageDescription</key>
	<string>Esta app precisa acessar a pasta Downloads para salvar as versões do macOS baixadas.</string>
	<key>NSDocumentsFolderUsageDescription</key>
	<string>Esta app precisa acessar a pasta Documents para salvar downloads de versões do macOS.</string>
	<key>NSRemovableVolumesUsageDescription</key>
	<string>Esta app precisa acessar volumes removíveis para salvar downloads de versões do macOS.</string>
</dict>
</plist>
EOF

echo "✅ App bundle criado com sucesso!"

# Informações do build
echo ""
echo "📊 Informações do Build:"
echo "------------------------"
echo "📱 App: $BUNDLE_NAME"
echo "💾 Tamanho: $(du -h "$BUNDLE_NAME" | cut -f1)"
echo "🏗️ Arquiteturas: Universal (ARM64 + x86_64)"
echo "🎯 Mínimo: macOS 13.0+"
echo "📍 Local: $(pwd)/$BUNDLE_NAME"

echo ""
echo "🚀 Para testar o app:"
echo "open '$BUNDLE_NAME'"

echo ""
echo "📦 Para distribuir:"
echo "1. Comprima o app: zip -r 'macOS-Version-Manager-v1.0.0.zip' '$BUNDLE_NAME'"
echo "2. Ou crie um DMG para distribuição profissional"

echo ""
echo "🎉 Build universal concluído com sucesso!"
