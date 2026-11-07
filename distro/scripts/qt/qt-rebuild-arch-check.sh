#!/usr/bin/env bash
# Detect Arch (x86_64) and Arch Linux ARM (aarch64) qt6 bumps for the prebuilt dux-qt-base-bin library
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$REPO_ROOT"

QT_WATCH_PACKAGES="${QT_WATCH_PACKAGES:-qt6-base qt6-declarative qt6-wayland}"
QT_ARCHES="${QT_ARCHES:-x86_64 aarch64}"
QT_BASELINE="${QT_BASELINE:-distro/arch/qt6-baseline.json}"
ARCH_PACKAGES_API="${ARCH_PACKAGES_API:-https://archlinux.org/packages/extra/x86_64}"
ALARM_EXTRA_DB="${ALARM_EXTRA_DB:-http://mirror.archlinuxarm.org/aarch64/extra/extra.db}"
GITHUB_OUTPUT="${GITHUB_OUTPUT:-/dev/null}"

read -ra PACKAGES <<<"$QT_WATCH_PACKAGES"
read -ra ARCHES <<<"$QT_ARCHES"

for tool in curl jq vercmp bsdtar; do
    if ! command -v "$tool" >/dev/null; then
        echo "::error::$tool not found" >&2
        exit 1
    fi
done

# prints "<pkgname> <pkgver>" per watched package, pkgrel dropped: the private ABI only follows pkgver
query_x86_64() {
    local pkg
    for pkg in "${PACKAGES[@]}"; do
        curl -fsSL "$ARCH_PACKAGES_API/$pkg/json/" | jq -r '"\(.pkgname) \(.pkgver)"'
    done
}

query_aarch64() {
    local db listing pkg
    db=$(mktemp)
    curl -fsSL -o "$db" "$ALARM_EXTRA_DB"
    listing=$(bsdtar -tf "$db" | cut -d/ -f1 | sort -u)
    rm -f "$db"
    for pkg in "${PACKAGES[@]}"; do
        sed -nE "s/^(${pkg})-([^-]+)-[0-9.]+$/\1 \2/p" <<<"$listing" | head -1
    done
}

BASELINE='{}'
if [[ -f "$QT_BASELINE" ]]; then
    BASELINE=$(cat "$QT_BASELINE")
fi
NEXT="$BASELINE"
SEEDED=false
CHANGES=()
PINS=()

for arch in "${ARCHES[@]}"; do
    found=$("query_$arch")
    arch_changed=false
    declare -A versions=()
    for pkg in "${PACKAGES[@]}"; do
        ver=$(awk -v p="$pkg" '$1 == p { print $2; exit }' <<<"$found")
        if [[ -z "$ver" ]]; then
            echo "::error::$pkg not found for $arch" >&2
            exit 1
        fi
        versions[$pkg]="$ver"
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
        if (( $(vercmp "$ver" "$old") <= 0 )); then
            echo "  $arch $pkg repo has $ver, older than baseline $old, ignoring"
            continue
        fi
        echo "  $arch $pkg $old -> $ver"
        arch_changed=true
    done
    [[ "$arch_changed" == true ]] || continue
    # the pin is one Qt version per arch; wait for the repo to finish a partial Qt rollout
    pin=$(printf '%s\n' "${versions[@]}" | sort -u)
    if (( $(wc -l <<<"$pin") != 1 )); then
        echo "  $arch qt6 packages disagree ($(tr '\n' ' ' <<<"$pin")), waiting for the rollout to finish"
        continue
    fi
    for pkg in "${PACKAGES[@]}"; do
        NEXT=$(jq --arg a "$arch" --arg p "$pkg" --arg v "${versions[$pkg]}" '.[$a][$p] = $v' <<<"$NEXT")
    done
    CHANGES+=("$arch qt $pin")
    PINS+=("$arch:$pin")
done

DIRTY=false
if [[ "$SEEDED" == true || ${#CHANGES[@]} -gt 0 ]]; then
    jq -S . <<<"$NEXT" >"$QT_BASELINE"
    DIRTY=true
fi

SUMMARY=""
if ((${#CHANGES[@]})); then
    SUMMARY=$(printf '%s, ' "${CHANGES[@]}")
    SUMMARY=${SUMMARY%, }
fi
QTVER=$(IFS=,; echo "${PINS[*]:-}")
ARCHES_CHANGED=$(printf '%s\n' "${PINS[@]:-}" | sed 's/:.*//' | tr '\n' ' ')

{
    echo "dirty=$DIRTY"
    echo "rebuild=$([[ ${#CHANGES[@]} -gt 0 ]] && echo true || echo false)"
    echo "summary=$SUMMARY"
    echo "qtver=$QTVER"
    echo "arches=${ARCHES_CHANGED% }"
} >>"$GITHUB_OUTPUT"

if ((${#CHANGES[@]})); then
    echo "Rebuild needed: $SUMMARY"
elif [[ "$SEEDED" == true ]]; then
    echo "Baseline seeded, no rebuild"
else
    echo "No qt6 changes"
fi
