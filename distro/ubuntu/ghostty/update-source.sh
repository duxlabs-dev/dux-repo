#!/bin/bash
# Script to update Ghostty source, bundle Zig, and vendor dependencies for Launchpad builds
# Usage: ./update-source.sh [version-tag]

set -e

PACKAGE_DIR="$(cd "$(dirname "$0")" && pwd)"
PACKAGE_NAME="ghostty"
DEBIAN_DIR="$PACKAGE_DIR/debian"

# Default to latest stable from GitHub if not specified
if [ -z "$1" ]; then
    echo "Getting latest version tag from GitHub..."
    VERSION=$(git ls-remote --tags --refs --sort='-v:refname' https://github.com/ghostty-org/ghostty.git | head -n1 | awk -F/ '{print $NF}' | sed 's/^v//')
else
    VERSION="$1"
fi

echo "Updating to Ghostty version: $VERSION"

# Setup temp directory
WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

echo "Working in: $WORK_DIR"
cd "$WORK_DIR"

# Download Ghostty Source from official release
echo "Downloading Ghostty source..."
RELEASE_URL="https://release.files.ghostty.org/${VERSION}/ghostty-${VERSION}.tar.gz"
wget -q -O ghostty-source.tar.gz "$RELEASE_URL"

if [ ! -f ghostty-source.tar.gz ]; then
    echo "ERROR: Failed to download Ghostty source from $RELEASE_URL"
    exit 1
fi

echo "Extracting Ghostty source..."
mkdir -p ghostty-source
tar -xzf ghostty-source.tar.gz -C ghostty-source --strip-components=1
rm ghostty-source.tar.gz

cd ghostty-source

# Bundle Zig 0.17.0 (Ghostty 1.4 minimum_zig_version) so Launchpad does not depend on archive zig versions.
ZIG_VERSION="0.17.0"
ZIG_URL_X86_64="https://ziglang.org/download/${ZIG_VERSION}/zig-x86_64-linux-${ZIG_VERSION}.tar.xz"
ZIG_URL_AARCH64="https://ziglang.org/download/${ZIG_VERSION}/zig-aarch64-linux-${ZIG_VERSION}.tar.xz"

echo "Bundling Zig version: $ZIG_VERSION"
mkdir -p zig/x86_64 zig/aarch64

echo "Downloading Zig for x86_64..."
wget -q -O zig-x86_64.tar.xz "$ZIG_URL_X86_64"
tar --no-same-owner -xf zig-x86_64.tar.xz --strip-components=1 -C zig/x86_64
rm zig-x86_64.tar.xz
chmod +x zig/x86_64/zig

echo "Downloading Zig for aarch64..."
wget -q -O zig-aarch64.tar.xz "$ZIG_URL_AARCH64"
tar --no-same-owner -xf zig-aarch64.tar.xz --strip-components=1 -C zig/aarch64
rm zig-aarch64.tar.xz
chmod +x zig/aarch64/zig

# Prefer system Zig for vendoring when it is new enough; otherwise use bundled Zig.
REQUIRED_ZIG_VERSION="0.17.0"
ZIG_BIN="${ZIG_BIN:-}"
HOST_ARCH="$(uname -m)"

case "$HOST_ARCH" in
    x86_64)
        BUNDLED_ZIG="./zig/x86_64/zig"
        ;;
    aarch64|arm64)
        BUNDLED_ZIG="./zig/aarch64/zig"
        ;;
    *)
        BUNDLED_ZIG=""
        ;;
esac

if [ -z "$ZIG_BIN" ]; then
    for candidate in /usr/bin/zig-0.17 /usr/bin/zig zig-0.17 zig17 zig; do
        if command -v "$candidate" >/dev/null 2>&1; then
            candidate_bin=$(command -v "$candidate")
            candidate_ver=$("$candidate_bin" version 2>/dev/null | head -1)
            if [[ "$candidate_ver" =~ ^0\.(1[7-9]|[2-9][0-9])\. ]]; then
                ZIG_BIN="$candidate_bin"
                break
            fi
        fi
    done
fi

if [ -z "$ZIG_BIN" ]; then
    if [ -n "$BUNDLED_ZIG" ] && [ -x "$BUNDLED_ZIG" ]; then
        ZIG_BIN="$BUNDLED_ZIG"
    else
        echo "ERROR: Compatible Zig not found. Install Zig ${REQUIRED_ZIG_VERSION}+ or set ZIG_BIN."
        exit 1
    fi
fi

echo "Using Zig binary: $ZIG_BIN ($("$ZIG_BIN" version 2>/dev/null | head -1))"

# The themes dependency is fetched like every other build.zig.zon entry;
# record its hash so the vendored package directory can be checked afterwards.
THEME_HASH=""
if [ -f "build.zig.zon" ]; then
    THEME_HASH=$(sed -n '/\.iterm2_themes = /,/}/ s/.*\.hash = "\([^"]*\)".*/\1/p' build.zig.zon | head -1)
    echo "iterm2_themes hash: ${THEME_HASH:-unknown}"
fi

# 3. Vendor Zig Dependencies
# Zig 0.17 keeps its global cache as p/<hash>.tar.gz archives that `zig build
# --system` cannot read (it panics), so fetch-zig-cache.sh is not used.
# `zig build --fetch=all` unpacks every dependency, lazy ones included, into
# ./zig-pkg/<hash>/; debian/rules then builds offline with `--system zig-pkg`.
echo "Vendoring Zig dependencies into zig-pkg/..."
export ZIG_GLOBAL_CACHE_DIR="$PWD/zig-deps"
mkdir -p "$ZIG_GLOBAL_CACHE_DIR"

if ! "$ZIG_BIN" build --fetch=all 2>&1; then
    echo "ERROR: 'zig build --fetch=all' failed"
    exit 1
fi

unset ZIG_GLOBAL_CACHE_DIR

if [ ! -d "zig-pkg" ]; then
    echo "ERROR: zig-pkg/ was not created by 'zig build --fetch=all'"
    exit 1
fi

if [ -n "$THEME_HASH" ] && [ ! -d "zig-pkg/$THEME_HASH" ]; then
    echo "ERROR: themes dependency $THEME_HASH missing from zig-pkg/"
    exit 1
fi

# Every hash pinned in build.zig.zon must be present for the offline build.
MISSING_PKGS=0
for pkg_hash in $(sed -n 's/.*\.hash = "\([^"]*\)".*/\1/p' build.zig.zon pkg/*/build.zig.zon 2>/dev/null | sort -u); do
    if [ ! -d "zig-pkg/$pkg_hash" ]; then
        echo "ERROR: dependency $pkg_hash missing from zig-pkg/"
        MISSING_PKGS=$((MISSING_PKGS + 1))
    fi
done
if [ "$MISSING_PKGS" -gt 0 ]; then
    exit 1
fi

DEP_COUNT=$(find zig-pkg -mindepth 1 -maxdepth 1 -type d | wc -l)
if [ "$DEP_COUNT" -eq 0 ]; then
    echo "ERROR: zig-pkg/ is empty"
    exit 1
fi
echo "Vendored $DEP_COUNT dependencies in zig-pkg/"

# Only zig-pkg/ is shipped. The global cache holds the same packages again as
# archives, and .zig-cache/ is build scratch.
rm -rf zig-deps .zig-cache

# Create Orig Tarball
cd ..
echo "Creating source tarball..."
rm -rf ghostty-source/.git
rm -rf ghostty-source/.gitignore

mv ghostty-source "ghostty-${VERSION}"

# Tarball naming: ghostty_1.2.3.orig.tar.xz
TARBALL_NAME="${PACKAGE_NAME}_${VERSION}.orig.tar.xz"
tar -cJf "$TARBALL_NAME" "ghostty-${VERSION}"

# Move to Destination
echo "Moving artifacts..."
mv "$TARBALL_NAME" "$PACKAGE_DIR/../"
echo "Created: $PACKAGE_DIR/../$TARBALL_NAME"

# Update changelog if needed
echo "Done. Don't forget to update debian/changelog if this is a new version."
