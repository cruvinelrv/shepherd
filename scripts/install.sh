#!/usr/bin/env bash
# Shepherd CLI Universal Installer for macOS and Linux
# Marmelotech - https://marmelo.tech
set -e

REPO="cruvinelrv/shepherd"
INSTALL_DIR="/usr/local/bin"
ALT_DIR="$HOME/.shepherd/bin"

echo "🐑 Installing Shepherd CLI..."

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
        echo "❌ Unsupported operating system: $OS"
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
        echo "❌ Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

TARGET="${OS_NAME}-${ARCH_NAME}"

# Fetch latest release tag
echo "🔍 Looking for the latest version..."
LATEST_TAG=$(curl -sSL "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
# If GitHub's API cannot be reached (rate limit, proxy), take the latest release anyway.
if [ -z "$LATEST_TAG" ]; then
    LATEST_TAG="latest"
    BASE_URL="https://github.com/${REPO}/releases/latest/download"
else
    BASE_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}"
fi

URL="${BASE_URL}/shepherd-${TARGET}.tar.gz"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "⬇️  Downloading Shepherd CLI (${LATEST_TAG}) for ${TARGET}..."
if ! curl -sSL -f -o "$TMP_DIR/shepherd.tar.gz" "$URL"; then
    # Fallback to linux-x64 or macos-x64 if specific arch is missing
    echo "⚠️  Trying the x64 build instead..."
    URL="${BASE_URL}/shepherd-${OS_NAME}-x64.tar.gz"
    curl -sSL -f -o "$TMP_DIR/shepherd.tar.gz" "$URL"
fi

echo "📦 Extracting the package..."
tar -xzf "$TMP_DIR/shepherd.tar.gz" -C "$TMP_DIR"

# Install into ~/.shepherd/bin and ~/.shepherd/lib
mkdir -p "$ALT_DIR"
if [ -d "$TMP_DIR/lib" ]; then
    mkdir -p "$HOME/.shepherd/lib"
    cp -rf "$TMP_DIR/lib"/* "$HOME/.shepherd/lib/" 2>/dev/null || true
fi

if [ -f "$TMP_DIR/bin/shepherd" ]; then
    cp -f "$TMP_DIR/bin/shepherd" "$ALT_DIR/shepherd"
elif [ -f "$TMP_DIR/shepherd" ]; then
    cp -f "$TMP_DIR/shepherd" "$ALT_DIR/shepherd"
fi
chmod +x "$ALT_DIR/shepherd"

# Choose install directory and link
TARGET_BIN="$ALT_DIR/shepherd"
if [ -w "$INSTALL_DIR" ]; then
    ln -sf "$ALT_DIR/shepherd" "$INSTALL_DIR/shepherd" 2>/dev/null && TARGET_BIN="$INSTALL_DIR/shepherd" || true
elif command -v sudo >/dev/null 2>&1; then
    echo "🔑 Asking for permission to create a link in $INSTALL_DIR..."
    sudo ln -sf "$ALT_DIR/shepherd" "$INSTALL_DIR/shepherd" 2>/dev/null && TARGET_BIN="$INSTALL_DIR/shepherd" || true
fi

if [ "$TARGET_BIN" = "$ALT_DIR/shepherd" ]; then
    echo "ℹ️  Shepherd installed in $ALT_DIR."
    echo "💡 Add it to your PATH in ~/.zshrc or ~/.bashrc:"
    echo '    export PATH="$HOME/.shepherd/bin:$PATH"'
fi

echo "✅ Shepherd CLI installed at $TARGET_BIN!"
"$TARGET_BIN" --version || true
echo "🚀 Run 'shepherd' in your terminal to start. Change the language with 'shepherd lang pt' or 'shepherd lang es'."
