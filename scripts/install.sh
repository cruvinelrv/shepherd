#!/usr/bin/env bash
# Shepherd CLI Universal Installer for macOS and Linux
# Marmelotech - https://marmelotech.com.br
set -e

REPO="cruvinelrv/shepherd"
INSTALL_DIR="/usr/local/bin"
ALT_DIR="$HOME/.shepherd/bin"

echo "🐑 Instalando Shepherd CLI..."

# Detect OS
OS="$(uname -s)"
case "$OS" in
    Darwin)
        OS_NAME="macos"
        ;;
    Linux)
        OS_NAME="linux"
        ;;
    *)
        echo "❌ Sistema operacional não suportado: $OS"
        exit 1
        ;;
esac

# Detect Architecture
ARCH="$(uname -m)"
case "$ARCH" in
    x86_64|amd64)
        ARCH_NAME="x64"
        ;;
    arm64|aarch64)
        ARCH_NAME="arm64"
        ;;
    *)
        echo "❌ Arquitetura não suportada: $ARCH"
        exit 1
        ;;
esac

TARGET="${OS_NAME}-${ARCH_NAME}"

# Fetch latest release tag
echo "🔍 Buscando versão mais recente..."
LATEST_TAG=$(curl -sSL "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
if [ -z "$LATEST_TAG" ]; then
    LATEST_TAG="v0.11.2"
fi

URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/shepherd-${TARGET}.tar.gz"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "⬇️  Baixando Shepherd CLI (${LATEST_TAG}) para ${TARGET}..."
if ! curl -sSL -f -o "$TMP_DIR/shepherd.tar.gz" "$URL"; then
    # Fallback to linux-x64 or macos-x64 if specific arch is missing
    echo "⚠️  Tentando binário alternativo x64..."
    URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/shepherd-${OS_NAME}-x64.tar.gz"
    curl -sSL -f -o "$TMP_DIR/shepherd.tar.gz" "$URL"
fi

echo "📦 Extraindo pacote..."
tar -xzf "$TMP_DIR/shepherd.tar.gz" -C "$TMP_DIR"
chmod +x "$TMP_DIR/shepherd"

# Choose install directory
TARGET_BIN="$INSTALL_DIR/shepherd"
if [ -w "$INSTALL_DIR" ]; then
    mv "$TMP_DIR/shepherd" "$TARGET_BIN"
else
    if command -v sudo >/dev/null 2>&1; then
        echo "🔑 Solicitando permissão para instalar em $INSTALL_DIR..."
        sudo mv "$TMP_DIR/shepherd" "$TARGET_BIN"
    else
        mkdir -p "$ALT_DIR"
        mv "$TMP_DIR/shepherd" "$ALT_DIR/shepherd"
        TARGET_BIN="$ALT_DIR/shepherd"
        echo "⚠️  Instalado em $ALT_DIR. Certifique-se de adicionar ao seu PATH:"
        echo '    export PATH="$HOME/.shepherd/bin:$PATH"'
    fi
fi

echo "✅ Shepherd CLI instalado com sucesso em $TARGET_BIN!"
"$TARGET_BIN" --version || true
echo "🚀 Execute 'shepherd' no seu terminal para começar."
