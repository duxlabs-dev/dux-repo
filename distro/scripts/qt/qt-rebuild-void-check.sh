#!/usr/bin/env bash
# Bump Void templates that link private Qt ABI when Void ships a new qt6 in its current repo
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$REPO_ROOT"

QT_WATCH_PACKAGES="${QT_WATCH_PACKAGES:-qt6-base qt6-declarative qt6-wayland}"
QT_ARCHES="${QT_ARCHES:-x86_64}"
QT_REBUILD_TEMPLATES="${QT_REBUILD_TEMPLATES:-distro/void/srcpkgs/dux-qt-base/template}"
QT_BASELINE="${QT_BASELINE:-distro/void/qt6-baseline.json}"
VOID_REPO="${VOID_REPO:-https://repo-default.voidlinux.org/current}"
GITHUB_OUTPUT="${GITHUB_OUTPUT:-/dev/null}"

read -ra PACKAGES <<<"$QT_WATCH_PACKAGES"
read -ra ARCHES <<<"$QT_ARCHES"
read -ra TEMPLATES <<<"$QT_REBUILD_TEMPLATES"

for tool in curl jq bsdtar python3; do
    if ! command -v "$tool" >/dev/null; then
        echo "::error::$tool not found" >&2
        exit 1
    fi
done
for tpl in "${TEMPLATES[@]}"; do
    if [[ ! -f "$tpl" ]]; then
        echo "::error::template missing: $tpl" >&2
        exit 1
    fi
done

# prints "<pkgname> <version_revision>" per watched package from the repo index
query_repo() {
    local arch="$1" repodata
    repodata=$(mktemp)
    curl -fsSL -o "$repodata" "$VOID_REPO/$arch-repodata"
    bsdtar -xOf "$repodata" index.plist | python3 -c '
import plistlib, sys
index = plistlib.loads(sys.stdin.buffer.read())
for name in sys.argv[1:]:
    pkgver = index.get(name, {}).get("pkgver", "")
    print(name, pkgver[len(name) + 1:] if pkgver else "")
' "${PACKAGES[@]}"
    rm -f "$repodata"
}

# "6.11.2_1" sorts as 6.11.2.1; a revision-only bump counts, Void may have rebuilt qt against new deps
newer_than() {
    local a="${1//_/.}" b="${2//_/.}"
    [[ "$a" != "$b" && "$(printf '%s\n' "$a" "$b" | sort -V | tail -1)" == "$a" ]]
}

bump_template() {
    local tpl="$1" rev
    rev=$(sed -nE 's/^revision=([0-9]+).*/\1/p' "$tpl")
    sed -i -E "s/^revision=.*/revision=$((rev + 1))/" "$tpl"
    echo "  $tpl revision $rev -> $((rev + 1))"
}

BASELINE='{}'
if [[ -f "$QT_BASELINE" ]]; then
    BASELINE=$(cat "$QT_BASELINE")
fi
NEXT="$BASELINE"
SEEDED=false
CHANGES=()

for arch in "${ARCHES[@]}"; do
    found=$(query_repo "$arch") || { echo "::error::could not read Void $arch repodata" >&2; exit 1; }
    for pkg in "${PACKAGES[@]}"; do
        ver=$(awk -v p="$pkg" '$1 == p { print $2; exit }' <<<"$found")
        if [[ -z "$ver" ]]; then
            echo "::error::$pkg not found in Void $arch repodata" >&2
            exit 1
        fi
        old=$(jq -r --arg a "$arch" --arg p "$pkg" '.[$a][$p] // empty' <<<"$BASELINE")
        if [[ -z "$old" ]]; then
            NEXT=$(jq --arg a "$arch" --arg p "$pkg" --arg v "$ver" '.[$a][$p] = $v' <<<"$NEXT")
            SEEDED=true
            echo "  $arch $pkg seeded at $ver"
            continue
        fi
        if [[ "$old" == "$ver" ]]; then
            echo "  $arch $pkg unchanged at $ver"
            continue
        fi
        if ! newer_than "$ver" "$old"; then
            echo "  $arch $pkg repo has $ver, older than baseline $old, ignoring"
            continue
        fi
        NEXT=$(jq --arg a "$arch" --arg p "$pkg" --arg v "$ver" '.[$a][$p] = $v' <<<"$NEXT")
        CHANGES+=("$pkg-$ver ($arch)")
        echo "  $arch $pkg $old -> $ver"
    done
done

SUMMARY=""
BUMPED=false
PACKAGES_OUT=""
if ((${#CHANGES[@]})); then
    SUMMARY=$(printf '%s, ' "${CHANGES[@]}")
    SUMMARY=${SUMMARY%, }
    for tpl in "${TEMPLATES[@]}"; do
        bump_template "$tpl"
        PACKAGES_OUT+="$(basename "$(dirname "$tpl")") "
    done
    BUMPED=true
fi

DIRTY=false
if [[ "$SEEDED" == true || "$BUMPED" == true ]]; then
    jq -S . <<<"$NEXT" >"$QT_BASELINE"
    DIRTY=true
fi

{
    echo "bumped=$BUMPED"
    echo "dirty=$DIRTY"
    echo "summary=$SUMMARY"
    echo "packages=${PACKAGES_OUT% }"
} >>"$GITHUB_OUTPUT"

if [[ "$BUMPED" == true ]]; then
    echo "Rebuild needed: $SUMMARY"
elif [[ "$SEEDED" == true ]]; then
    echo "Baseline seeded, no rebuild"
else
    echo "No qt6 changes"
fi
