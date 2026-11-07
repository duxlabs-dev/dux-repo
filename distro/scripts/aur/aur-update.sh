#!/usr/bin/env bash
# Update one AUR package: bump pkgver/pkgrel/_qtver, refresh checksums and .SRCINFO, push.
# Usage: aur-update.sh <package> [--version=X] [--pkgrel=N|--bump-pkgrel] [--qtver=[ARCH:]X]... [--message=TEXT] [--dry-run]
#   release packages track the latest GitHub release when --version is absent
#   git packages only take --pkgrel (their pkgver() runs at build time)
#   --qtver=X pins every _qtver* line, --qtver=aarch64:X only _qtver_aarch64; repeatable
#   --bump-pkgrel adds one to the current pkgrel (rebuilds)
# Env: AUR_GIT_BASE (ssh://aur@aur.archlinux.org), AUR_RETRIES (8), GITHUB_TOKEN
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FETCH_VERSION="$SCRIPT_DIR/../common/fetch-version.sh"

AUR_GIT_BASE="${AUR_GIT_BASE:-ssh://aur@aur.archlinux.org}"
AUR_RETRIES="${AUR_RETRIES:-8}"
COMMIT_AUTHOR_NAME="${COMMIT_AUTHOR_NAME:-github-actions[bot]}"
COMMIT_AUTHOR_EMAIL="${COMMIT_AUTHOR_EMAIL:-41898282+github-actions[bot]@users.noreply.github.com}"
# the runner's output file belongs to root; an unprivileged makepkg user cannot write it
GITHUB_OUTPUT="${GITHUB_OUTPUT:-/dev/null}"
[[ -w "$GITHUB_OUTPUT" ]] || GITHUB_OUTPUT=/dev/null

# name:repo:kind (release: pkgver follows GitHub releases; git: manual pkgrel only)
PACKAGES=(
    "dux-calendar-bin:duxlabs-dev/dux-calendar:release"
    "dux-files-bin:duxlabs-dev/dux-files:release"
    "dux-greeter-bin:duxlabs-dev/dux-greeter:release"
    "dux-search-bin:duxlabs-dev/dux-search:release"
    "dux-qt-base:duxlabs-dev/dux-qt-base:release"
    "dux-qt-base-bin:duxlabs-dev/dux-qt-base:release"
    "dux-shell-git:duxlabs-dev/dux-shell:git"
    "dux-calendar-git:duxlabs-dev/dux-calendar:git"
    "dux-files-git:duxlabs-dev/dux-files:git"
    "dux-greeter-git:duxlabs-dev/dux-greeter:git"
    "dux-search-git:duxlabs-dev/dux-search:git"
    "dux-gop-git:duxlabs-dev/dux-gop:git"
    "dux-qt-base-git:duxlabs-dev/dux-qt-base:git"
)

info() { echo "[INFO] $*" >&2; }
warn() { echo "[WARN] $*" >&2; }
fail() { echo "::error::$*" >&2; exit 1; }

list_packages() {
    local kind="${1:-all}" entry
    for entry in "${PACKAGES[@]}"; do
        IFS=: read -r name _ k <<<"$entry"
        [[ "$kind" == all || "$kind" == "$k" ]] && echo "$name"
    done
}

PACKAGE=""
VERSION=""
PKGREL=""
BUMP_PKGREL=false
QTVERS=()
MESSAGE=""
DRY_RUN=false
for arg in "$@"; do
    case "$arg" in
    --version=*) VERSION="${arg#*=}"; VERSION="${VERSION#v}" ;;
    --pkgrel=*) PKGREL="${arg#*=}" ;;
    --bump-pkgrel) BUMP_PKGREL=true ;;
    --qtver=*) QTVERS+=("${arg#*=}") ;;
    --message=*) MESSAGE="${arg#*=}" ;;
    --dry-run) DRY_RUN=true ;;
    --list) list_packages all; exit 0 ;;
    --list-release) list_packages release; exit 0 ;;
    -h|--help) sed -n '2,6p' "$0"; exit 0 ;;
    -*) fail "unknown option: $arg" ;;
    *) PACKAGE="$arg" ;;
    esac
done
[[ -n "$PACKAGE" ]] || fail "package name required"
[[ -z "$PKGREL" || "$PKGREL" =~ ^[1-9][0-9]*$ ]] || fail "--pkgrel must be a positive integer"
[[ -z "$PKGREL" || "$BUMP_PKGREL" == false ]] || fail "--pkgrel and --bump-pkgrel are exclusive"

REPO=""
KIND=""
for entry in "${PACKAGES[@]}"; do
    IFS=: read -r name repo kind <<<"$entry"
    [[ "$name" == "$PACKAGE" ]] || continue
    REPO="$repo"
    KIND="$kind"
done
[[ -n "$KIND" ]] || fail "unknown package: $PACKAGE (see --list)"

for tool in git makepkg updpkgsums; do
    command -v "$tool" >/dev/null || fail "$tool not found"
done
[[ "$(id -u)" != 0 ]] || fail "makepkg refuses to run as root; run as an unprivileged user"

backoff() {
    local attempt="$1"
    local delay=$((5 * (1 << (attempt - 1))))
    (( delay > 60 )) && delay=60
    echo "$delay"
}

# AUR drops connections often enough that one try is never enough
retry() {
    local what="$1" attempt
    shift
    for ((attempt = 1; attempt <= AUR_RETRIES; attempt++)); do
        if "$@"; then
            return 0
        fi
        if (( attempt < AUR_RETRIES )); then
            warn "$what failed (attempt $attempt/$AUR_RETRIES), retrying in $(backoff "$attempt")s"
            sleep "$(backoff "$attempt")"
        fi
    done
    fail "$what failed after $AUR_RETRIES attempts"
}

WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aur-${PACKAGE}-XXXXXX")
trap 'rm -rf "$WORK_DIR"' EXIT
CLONE="$WORK_DIR/$PACKAGE"

info "Cloning $AUR_GIT_BASE/$PACKAGE.git"
retry "clone" git clone -q "$AUR_GIT_BASE/$PACKAGE.git" "$CLONE"
cd "$CLONE"
[[ -f PKGBUILD ]] || fail "$PACKAGE has no PKGBUILD on AUR (first push is manual)"
git config user.name "$COMMIT_AUTHOR_NAME"
git config user.email "$COMMIT_AUTHOR_EMAIL"

CURRENT_VERSION=$(sed -nE 's/^pkgver=([^ ]+).*/\1/p' PKGBUILD | head -1)
CURRENT_PKGREL=$(sed -nE 's/^pkgrel=([0-9]+).*/\1/p' PKGBUILD | head -1)
CURRENT_QTVER=$(sed -nE 's/^_qtver(_[a-z0-9_]+)?=([^ ]+).*/\1=\2/p' PKGBUILD | tr '\n' ' ')
info "Current: $PACKAGE $CURRENT_VERSION-$CURRENT_PKGREL${CURRENT_QTVER:+ (qt $CURRENT_QTVER)}"

NEW_VERSION="$CURRENT_VERSION"
if [[ "$KIND" == release ]]; then
    if [[ -z "$VERSION" ]]; then
        TAG=$("$FETCH_VERSION" "$REPO" release 2>/dev/null || true)
        [[ -n "$TAG" ]] || fail "could not resolve the latest release of $REPO"
        VERSION="${TAG#v}"
    fi
    NEW_VERSION="$VERSION"
    if [[ "$NEW_VERSION" != "$CURRENT_VERSION" ]] && command -v vercmp >/dev/null && (( $(vercmp "$NEW_VERSION" "$CURRENT_VERSION") < 0 )); then
        fail "$NEW_VERSION is older than the published $CURRENT_VERSION; refusing to downgrade"
    fi
elif [[ -n "$VERSION" ]]; then
    fail "$PACKAGE is a git package; its pkgver comes from pkgver(), use --pkgrel"
fi

VERSION_CHANGED=false
[[ "$NEW_VERSION" == "$CURRENT_VERSION" ]] || VERSION_CHANGED=true
QTVER_CHANGED=false
QTVER_SUMMARY=""
declare -A QTVER_FOR=()
for spec in "${QTVERS[@]}"; do
    [[ -n "$CURRENT_QTVER" ]] || fail "$PACKAGE has no _qtver to pin"
    pattern='^_qtver(_[a-z0-9_]+)?='
    value="$spec"
    if [[ "$spec" == *:* ]]; then
        pattern="^_qtver_${spec%%:*}="
        value="${spec#*:}"
        grep -qE "$pattern" PKGBUILD || fail "$PACKAGE has no ${pattern#^}"
    fi
    QTVER_FOR[$pattern]="$value"
    grep -E "$pattern" PKGBUILD | grep -qv "=$value\$" && QTVER_CHANGED=true
    QTVER_SUMMARY+="${QTVER_SUMMARY:+, }${spec}"
done

NEW_PKGREL="$CURRENT_PKGREL"
if [[ -n "$PKGREL" ]]; then
    NEW_PKGREL="$PKGREL"
elif [[ "$BUMP_PKGREL" == true ]]; then
    NEW_PKGREL=$((CURRENT_PKGREL + 1))
elif [[ "$VERSION_CHANGED" == true ]]; then
    NEW_PKGREL=1
elif [[ "$QTVER_CHANGED" == true ]]; then
    NEW_PKGREL=$((CURRENT_PKGREL + 1))
fi

if [[ "$VERSION_CHANGED" == false && "$QTVER_CHANGED" == false && "$NEW_PKGREL" == "$CURRENT_PKGREL" ]]; then
    info "$PACKAGE is up to date ($CURRENT_VERSION-$CURRENT_PKGREL)"
    echo "updated=false" >>"$GITHUB_OUTPUT"
    exit 0
fi

sed -i -E "s/^pkgver=.*/pkgver=$NEW_VERSION/" PKGBUILD
sed -i -E "s/^pkgrel=.*/pkgrel=$NEW_PKGREL/" PKGBUILD
for pattern in "${!QTVER_FOR[@]}"; do
    sed -i -E "s/($pattern).*/\1${QTVER_FOR[$pattern]}/" PKGBUILD
done

if [[ "$VERSION_CHANGED" == true || "$QTVER_CHANGED" == true ]]; then
    info "Refreshing checksums"
    retry "updpkgsums" updpkgsums
fi
makepkg --printsrcinfo >.SRCINFO

if [[ -z "$MESSAGE" ]]; then
    if [[ "$VERSION_CHANGED" == true ]]; then
        MESSAGE="update to $NEW_VERSION"
    elif [[ "$QTVER_CHANGED" == true ]]; then
        MESSAGE="rebuild for qt $QTVER_SUMMARY"
    else
        MESSAGE="bump pkgrel to $NEW_PKGREL"
    fi
fi

info "Change: $CURRENT_VERSION-$CURRENT_PKGREL -> $NEW_VERSION-$NEW_PKGREL ($MESSAGE)"
git --no-pager diff --stat
if [[ "$DRY_RUN" == true ]]; then
    git --no-pager diff
    info "Dry run, not pushing"
    echo "updated=false" >>"$GITHUB_OUTPUT"
    exit 0
fi

git add PKGBUILD .SRCINFO
git commit -q -m "$MESSAGE"

push_once() {
    git fetch -q origin master || return 1
    if ! git merge-base --is-ancestor origin/master HEAD; then
        git rebase -q origin/master || { git rebase --abort; return 1; }
    fi
    git push -q origin HEAD:master
}
retry "push" push_once
info "Pushed $PACKAGE $NEW_VERSION-$NEW_PKGREL"
{
    echo "updated=true"
    echo "version=$NEW_VERSION-$NEW_PKGREL"
} >>"$GITHUB_OUTPUT"
