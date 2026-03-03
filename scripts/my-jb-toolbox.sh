#!/bin/sh

set -eu

# Symlink distrobox shims
./distrobox-shims.sh

# Keep package list for first-enter setup
install -d /usr/share/boxkit
cp /my-jb-toolbox.packages /usr/share/boxkit/my-jb-toolbox.packages

# Install first-enter setup script
cat > /usr/local/bin/boxkit-first-enter-jetbrains.sh << 'EOF'
#!/bin/sh

set -eu

STATE_DIR="${HOME}/.local/state/boxkit"
MARKER_FILE="${STATE_DIR}/jetbrains-first-enter.done"
LOCK_FILE="${STATE_DIR}/jetbrains-first-enter.lock"
PACKAGES_FILE="/usr/share/boxkit/my-jb-toolbox.packages"

mkdir -p "${STATE_DIR}"

[ -f "${MARKER_FILE}" ] && exit 0
[ -f "${LOCK_FILE}" ] && exit 0

touch "${LOCK_FILE}"
trap 'rm -f "${LOCK_FILE}"' EXIT

echo "[boxkit] First enter detected. Installing JetBrains apps..."

sudo dnf -y copr enable medzik/jetbrains
grep -v '^#' "${PACKAGES_FILE}" | xargs sudo dnf install -y

distrobox-export --app pycharm-professional || true
distrobox-export --app goland || true
distrobox-export --app intellij-idea-ultimate || true

touch "${MARKER_FILE}"

echo "[boxkit] First-enter setup complete."
EOF

chmod +x /usr/local/bin/boxkit-first-enter-jetbrains.sh

# Run first-enter setup automatically for interactive shells
cat > /etc/profile.d/boxkit-first-enter-jetbrains.sh << 'EOF'
#!/bin/sh

case "$-" in
	*i*) ;;
	*) return 0 ;;
esac

if command -v distrobox-export >/dev/null 2>&1; then
	/usr/local/bin/boxkit-first-enter-jetbrains.sh
fi
EOF

chmod +x /etc/profile.d/boxkit-first-enter-jetbrains.sh
