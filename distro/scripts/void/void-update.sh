#!/usr/bin/env bash
# Bump Void release templates to the latest GitHub release: version, revision=1, checksum.
# Usage: void-update.sh [package...]
#   no arguments updates every template below; names match the template directory
#   transitional metas only follow the version
# Env: VOID_DIR (distro/void), GITHUB_TOKEN
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
FETCH_VERSION="$SCRIPT_DIR/../common/fetch-version.sh"
VOID_DIR="${VOID_DIR:-$REPO_ROOT/distro/void}"
GITHUB_OUTPUT="${GITHUB_OUTPUT:-/dev/null}"

# template directory under distro/void : upstream repo
TEMPLATES=(
    "srcpkgs/dux-gop:duxlabs-dev/dux-gop"
    "srcpkgs/dux-search:duxlabs-dev/dux-search"
    "srcpkgs/dux-calendar:duxlabs-dev/dux-calendar"
    "srcpkgs/dux-files:duxlabs-dev/dux-files"
    "srcpkgs/dux-qt-base:duxlabs-dev/dux-qt-base"
    "srcpkgs/dgop:duxlabs-dev/dux-gop"
    "srcpkgs/danksearch:duxlabs-dev/dux-search"
    "srcpkgs/dankcalendar:duxlabs-dev/dux-calendar"
    "legacy/srcpkgs/dgop:duxlabs-dev/dux-gop"
    "legacy/srcpkgs/danksearch:duxlabs-dev/dux-search"
    "legacy/srcpkgs/dankcalendar:duxlabs-dev/dux-calendar"
)

WANTED=("$@")
BUMPED=()
FAILED=()

info() { echo "[INFO] $*" >&2; }
warn() { echo "::warning::$*" >&2; }

is_wanted() {
    ((${#WANTED[@]})) || return 0
    local name
    for name in "${WANTED[@]}"; do
        [[ "$name" == "$1" ]] && return 0
    done
    return 1
}

template_var() {
    sed -nE "s/^$2=\"?([^\"]*)\"?\$/\1/p" "$1" | head -1
}

newer_than() {
    [[ "$1" != "$2" && "$(printf '%s\n' "$1" "$2" | sort -V | tail -1)" == "$1" ]]
}

distfile_checksum() {
    local tpl="$1" version="$2" url tarball
    url=$(template_var "$tpl" distfiles)
    url="${url//\$\{version\}/$version}"
    tarball=$(mktemp)
    if ! curl -fsSL --retry 3 -o "$tarball" "$url"; then
        rm -f "$tarball"
        return 1
    fi
    sha256sum "$tarball" | cut -d' ' -f1
    rm -f "$tarball"
}

bump_template() {
    local dir="$1" repo="$2" tpl="$VOID_DIR/$1/template" current tag latest checksum
    if [[ ! -f "$tpl" ]]; then
        warn "template missing: $tpl"
        return 1
    fi
    current=$(template_var "$tpl" version)
    if ! tag=$("$FETCH_VERSION" "$repo" release); then
        warn "$dir: could not resolve the latest release of $repo"
        return 1
    fi
    latest="${tag#v}"
    if [[ ! "$latest" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
        warn "$dir: unusable release tag '$tag' from $repo"
        return 1
    fi
    if ! newer_than "$latest" "$current"; then
        info "$dir is up to date ($current)"
        return 0
    fi
    if grep -q '^metapackage=yes' "$tpl"; then
        sed -i -E "s/^version=.*/version=$latest/" "$tpl"
        info "$dir $current -> $latest (meta)"
        BUMPED+=("$(basename "$dir") $latest")
        return 0
    fi
    if ! checksum=$(distfile_checksum "$tpl" "$latest"); then
        warn "$dir: could not download the $latest distfile"
        return 1
    fi
    sed -i -E \
        -e "s/^version=.*/version=$latest/" \
        -e "s/^revision=.*/revision=1/" \
        -e "s/^checksum=.*/checksum=$checksum/" "$tpl"
    info "$dir $current -> $latest"
    BUMPED+=("$(basename "$dir") $latest")
}

for entry in "${TEMPLATES[@]}"; do
    IFS=: read -r dir repo <<<"$entry"
    is_wanted "$(basename "$dir")" || continue
    bump_template "$dir" "$repo" || FAILED+=("$dir")
done

SUMMARY=""
if ((${#BUMPED[@]})); then
    SUMMARY=$(printf '%s\n' "${BUMPED[@]}" | sort -u | paste -sd, - | sed 's/,/, /g')
fi
echo "bumped=$SUMMARY" >>"$GITHUB_OUTPUT"
echo "Bumped: ${SUMMARY:-nothing}"

if ((${#FAILED[@]})); then
    echo "::error::could not update: ${FAILED[*]}" >&2
    exit 1
fi
