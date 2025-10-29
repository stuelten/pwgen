#!/usr/bin/env bash
set -euo pipefail

# Prepare assets: copy wordlists from pwgen-java into pwgen-python assets
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ASSETS_DIR="$SCRIPT_DIR/src/pwgen_python/assets"
JAVA_RES_DIR="$ROOT_DIR/pwgen-java/src/main/resources"

# Ensure assets exist in the Python package
mkdir -p "$ASSETS_DIR"
cp -f "$JAVA_RES_DIR"/wordlist_{en,fr,de}.txt "$ASSETS_DIR"/

# Determine whether to use --user installs (avoid in virtualenv)
PIP_USER_FLAG="--user"
if [ -n "${VIRTUAL_ENV-}" ]; then
  PIP_USER_FLAG=""
fi

# Ensure the Python build module is available (ensure build.__main__ is available)
if ! python3 -c "import importlib; importlib.import_module('build.__main__')" >/dev/null 2>&1; then
  python3 -m pip install ${PIP_USER_FLAG} build
fi

# Build wheel/sdist using standard Python tools from the repo root to avoid local 'build' dir shadowing
(
  cd "$ROOT_DIR"
  python3 -m build "$SCRIPT_DIR"
)

# Create a native-like binary with PyInstaller (onefile)
# Ensure PyInstaller is available
if ! command -v pyinstaller >/dev/null 2>&1; then
  python3 -m pip install ${PIP_USER_FLAG} pyinstaller
fi

# Use --add-data to be explicit about including assets in the binary
# Format differs on Windows; we assume POSIX here per repo conventions
pyinstaller --onefile \
  --name pwgen-python \
  --add-data "$ASSETS_DIR/wordlist_en.txt:pwgen_python/assets" \
  --add-data "$ASSETS_DIR/wordlist_fr.txt:pwgen_python/assets" \
  --add-data "$ASSETS_DIR/wordlist_de.txt:pwgen_python/assets" \
  "$SCRIPT_DIR/src/pwgen_python/cli.py"

# Copy binary next to the project root for convenience
if [ -f dist/pwgen-python ]; then
  cp dist/pwgen-python "$ROOT_DIR/pwgen-python/pwgen-python"
fi

echo "Build complete. Wheel in pwgen-python/dist, binary at pwgen-python/pwgen-python"
