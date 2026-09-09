#!/bin/sh
# Installs the FinOpsly CLI on macOS or Linux.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/finopsly/finopsly-pulse-cli/development/install.sh | sh
#   curl -fsSL https://raw.githubusercontent.com/finopsly/finopsly-pulse-cli/development/install.sh | sh -s -- v1.2.0
set -eu

REPO="finopsly/finopsly-pulse-cli"
INSTALL_DIR="${FINOPSLY_INSTALL_DIR:-$HOME/.local/bin}"
VERSION="${1:-latest}"

os=$(uname -s)
case "$os" in
  Darwin) os="darwin" ;;
  Linux) os="linux" ;;
  *)
    echo "error: unsupported OS: $os (this script supports macOS and Linux only)" >&2
    exit 1
    ;;
esac

arch=$(uname -m)
case "$arch" in
  x86_64 | amd64) arch="amd64" ;;
  arm64 | aarch64) arch="arm64" ;;
  *)
    echo "error: unsupported architecture: $arch" >&2
    exit 1
    ;;
esac

archive_name="finopsly_${os}_${arch}.tar.gz"

if [ "$VERSION" = "latest" ]; then
  url="https://github.com/${REPO}/releases/latest/download/${archive_name}"
  checksums_url="https://github.com/${REPO}/releases/latest/download/checksums.txt"
else
  url="https://github.com/${REPO}/releases/download/${VERSION}/${archive_name}"
  checksums_url="https://github.com/${REPO}/releases/download/${VERSION}/checksums.txt"
fi

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

echo "Downloading $url"
curl -fsSL "$url" -o "$tmpdir/finopsly.tar.gz"

echo "Verifying checksum"
curl -fsSL "$checksums_url" -o "$tmpdir/checksums.txt"

expected_sum=$(awk -v f="$archive_name" '$2 == f { print $1 }' "$tmpdir/checksums.txt")
if [ -z "$expected_sum" ]; then
  echo "error: no checksum entry found for $archive_name in checksums.txt" >&2
  exit 1
fi

if command -v sha256sum >/dev/null 2>&1; then
  actual_sum=$(sha256sum "$tmpdir/finopsly.tar.gz" | awk '{ print $1 }')
elif command -v shasum >/dev/null 2>&1; then
  actual_sum=$(shasum -a 256 "$tmpdir/finopsly.tar.gz" | awk '{ print $1 }')
else
  echo "error: neither sha256sum nor shasum is available to verify the download" >&2
  exit 1
fi

if [ "$actual_sum" != "$expected_sum" ]; then
  echo "error: checksum mismatch for $archive_name (expected $expected_sum, got $actual_sum)" >&2
  exit 1
fi

tar -xzf "$tmpdir/finopsly.tar.gz" -C "$tmpdir" finopsly

mkdir -p "$INSTALL_DIR"
mv "$tmpdir/finopsly" "$INSTALL_DIR/finopsly"
chmod +x "$INSTALL_DIR/finopsly"

echo "Installed finopsly to $INSTALL_DIR/finopsly"

case ":$PATH:" in
  *":$INSTALL_DIR:"*)
    ;;
  *)
    shell_name=$(basename "${SHELL:-sh}")
    case "$shell_name" in
      zsh) rcfile="$HOME/.zshrc" ;;
      bash) rcfile="$HOME/.bashrc" ;;
      *) rcfile="$HOME/.profile" ;;
    esac
    path_line="export PATH=\"$INSTALL_DIR:\$PATH\""
    if [ -f "$rcfile" ] && grep -qF "$path_line" "$rcfile" 2>/dev/null; then
      echo "$INSTALL_DIR is already configured in $rcfile — restart your shell or run: source $rcfile"
    else
      echo "" >> "$rcfile"
      echo "# Added by the FinOpsly CLI installer" >> "$rcfile"
      echo "$path_line" >> "$rcfile"
      echo "Added $INSTALL_DIR to PATH in $rcfile — restart your shell or run: source $rcfile"
    fi
    ;;
esac

"$INSTALL_DIR/finopsly" version
