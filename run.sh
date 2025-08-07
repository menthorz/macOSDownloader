#!/bin/bash

# macOS Version Manager - Script de Execução
# Compila e executa o aplicativo

echo "🍎 macOS Version Manager"
echo "========================"

# Navegar para o diretório do projeto
cd "$(dirname "$0")"

echo "📦 Compilando aplicação..."
swift build

if [ $? -eq 0 ]; then
    echo "✅ Compilação concluída com sucesso!"
    echo "🚀 Iniciando aplicação..."
    echo ""
    
    # Executar a aplicação
    ./.build/arm64-apple-macosx/debug/macOS-Version-Manager
else
    echo "❌ Erro na compilação!"
    exit 1
fi
