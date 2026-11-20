# Dux Labs Package Repository

<div align="center">
  <a href="https://duxlabs.dev">
    <img src="assets/duxlogo.svg" alt="Dux Labs" width="200">
  </a>

  ### Packages for DMS (Dux Modular Shell) and Dux Labs apps on Fedora, Debian, Ubuntu, openSUSE, Void and Arch

  Built with [Quickshell](https://quickshell.org/) and [Go](https://go.dev/)

[![GitHub stars](https://img.shields.io/github/stars/duxlabs-dev/dux-repo?style=for-the-badge&labelColor=101418&color=ffd700)](https://github.com/duxlabs-dev/dux-repo/stargazers)
[![GitHub License](https://img.shields.io/github/license/duxlabs-dev/dux-repo?style=for-the-badge&labelColor=101418&color=b9c8da)](https://github.com/duxlabs-dev/dux-repo/blob/master/LICENSE)
[![OBS Build](https://img.shields.io/badge/OBS-building-success?style=for-the-badge&labelColor=101418&color=73ba25&logo=opensuse)](https://build.opensuse.org/project/show/home:duxlabs-dev:dux-repo)
[![Ko-Fi donate](https://img.shields.io/badge/donate-kofi?style=for-the-badge&logo=ko-fi&logoColor=ffffff&label=ko-fi&labelColor=101418&color=f16061)](https://ko-fi.com/duxlabs)

</div>

## Channels

Each distro has a **dux-repo** channel (dependencies and apps) and a channel for DMS itself: **dms** (stable releases) or **dms-git** (nightly builds). Enable dux-repo plus one of the two DMS channels.

| Distro | dux-repo | DMS stable | DMS nightly |
| --- | --- | --- | --- |
| Fedora 43+ (Copr) | [`duxlabs/dux-repo`](https://copr.fedorainfracloud.org/coprs/duxlabs/dux-repo/) | [`duxlabs/dms`](https://copr.fedorainfracloud.org/coprs/duxlabs/dms/) | [`duxlabs/dms-git`](https://copr.fedorainfracloud.org/coprs/duxlabs/dms-git/) |
| Ubuntu 26.04 LTS / 26.10 (PPA) | [`ppa:duxlabs/dux-repo`](https://launchpad.net/~duxlabs/+archive/ubuntu/dux-repo) | [`ppa:duxlabs/dms`](https://launchpad.net/~duxlabs/+archive/ubuntu/dms) | [`ppa:duxlabs/dms-git`](https://launchpad.net/~duxlabs/+archive/ubuntu/dms-git) |
| Debian 13 / Testing / Unstable, openSUSE Tumbleweed / Slowroll / Leap 16.0 / 16.1 (OBS) | [`home:duxlabs-dev:dux-repo`](https://build.opensuse.org/project/show/home:duxlabs-dev:dux-repo) | [`home:duxlabs-dev:dms`](https://build.opensuse.org/project/show/home:duxlabs-dev:dms) | [`home:duxlabs-dev:dms-git`](https://build.opensuse.org/project/show/home:duxlabs-dev:dms-git) |
| Void Linux (XBPS) | `void.duxlabs.dev/dux-repo/current` | `void.duxlabs.dev/dms/current` (`dms`) | `void.duxlabs.dev/dms/current` (`dms-git`) |
| Arch Linux | [AUR](https://aur.archlinux.org/packages?K=dux-) | `dux-shell` (Arch `extra`) | `dux-shell-git` (AUR) |

All channels build for **x86_64** and **aarch64** (openSUSE Slowroll is x86_64 only).

## Available Packages

### Desktop Environment
- **DMS** - Dux Shell desktop environment

### Core Compositor
- **niri** - Scrollable-tiling Wayland compositor with smooth animations 

### Shell & Utilities
- **quickshell** - QtQuick-based Wayland desktop shell framework
- **dux-qt-base** / **dux-qt-base-git** - Quickshell QML runtime as a shared library (`libdux-qt-base.so.0`), the UI runtime for Dux Shell and Dux Labs apps
- **matugen** - Material Design 3 color palette generator for themes
- **cliphist** - Wayland clipboard manager with history support
- **dux-search** - Fast application launcher and file search tool (`dsearch`)
- **dux-calendar** - Calendar app with Local, Google, Microsoft, CalDAV, and iCloud support (`dcal`)
- **dux-calendar-git** - Dux Calendar built from upstream master
- **dux-files** - File manager with tabs, split panes, network shares and a portal file chooser (`dfiles`)
- **dux-files-git** - Dux Files built from upstream master
- **dux-edit** - Text and document editor with tabs, crash recovery, syntax highlighting and Markdown preview (`dux-edit`, `dedit`)
- **dux-edit-git** - Dux Edit built from upstream master
- **dux-gop** - System package manager integration tool (`dgop`)
- **dux-greeter** / **dux-greeter-git** - greetd greeter (`dms-greeter`)
- **ghostty** - GPU-accelerated terminal emulator

## Installation

> **📖 Full installation guide**: [duxlabs.dev/docs/dms/installation](https://duxlabs.dev/docs/dms/installation)

Adding dux-repo and a DMS channel is enough: installing `dms` (or `dms-git`) pulls in its dependencies. Add any of the apps above with the same package manager, e.g. `dux-files dux-edit dux-calendar dux-greeter ghostty`.

<details>
<summary><b>Fedora 43+ (Copr)</b></summary>

```bash
sudo dnf copr enable duxlabs/dux-repo
sudo dnf copr enable duxlabs/dms        # or duxlabs/dms-git for nightly builds
sudo dnf install dms niri
```

Both DMS projects ship the package as `dms`; enable only one of them.

</details>

<details>
<summary><b>Ubuntu 26.04 LTS / 26.10 (Launchpad PPA)</b></summary>

```bash
sudo add-apt-repository ppa:duxlabs/dux-repo
sudo add-apt-repository ppa:duxlabs/dms        # or ppa:duxlabs/dms-git
sudo apt update && sudo apt install dms niri   # or dms-git
```

> **Note**: Ubuntu 25.10 and older are not supported.

</details>

<details>
<summary><b>Debian 13 / Testing / Unstable (OBS)</b></summary>

```bash
DIST=Debian_13   # or Debian_Testing, Debian_Unstable
CHANNEL=dms      # or dms-git
OBS=https://download.opensuse.org/repositories/home:/duxlabs-dev:
for repo in dux-repo $CHANNEL; do
  curl -fsSL "$OBS/$repo/$DIST/Release.key" | sudo gpg --dearmor -o /etc/apt/keyrings/$repo.gpg
  echo "deb [signed-by=/etc/apt/keyrings/$repo.gpg] $OBS/$repo/$DIST/ /" | sudo tee /etc/apt/sources.list.d/$repo.list
done
sudo apt update && sudo apt install $CHANNEL niri
```

</details>

<details>
<summary><b>openSUSE Tumbleweed / Slowroll / Leap 16 (OBS)</b></summary>

```bash
DIST=openSUSE_Tumbleweed   # or openSUSE_Slowroll, 16.0, 16.1
CHANNEL=dms                # or dms-git
OBS=https://download.opensuse.org/repositories/home:duxlabs-dev:
sudo zypper addrepo $OBS/dux-repo/$DIST/home:duxlabs-dev:dux-repo.repo
sudo zypper addrepo $OBS/$CHANNEL/$DIST/home:duxlabs-dev:$CHANNEL.repo
sudo zypper refresh && sudo zypper install $CHANNEL
```

For a compositor, install `niri-git` from dux-repo (or `niri` from Tumbleweed).

</details>

<details>
<summary><b>Void Linux (XBPS)</b></summary>

```bash
echo "repository=https://void.duxlabs.dev/dux-repo/current" | sudo tee /etc/xbps.d/dux.conf
echo "repository=https://void.duxlabs.dev/dms/current" | sudo tee /etc/xbps.d/dms.conf
sudo xbps-install -S dms   # or dms-git
```

On the first sync `xbps-install` shows the repository signing key and asks you to trust it. See [distro/void](distro/void/README.md) for details.

</details>

<details>
<summary><b>Arch Linux</b></summary>

```bash
sudo pacman -S dux-shell          # DMS stable, from Arch extra
# or the nightly build and apps from the AUR, e.g. with paru:
paru -S dux-shell-git dux-files-bin dux-edit-bin dux-calendar-bin
```

</details>

> See [DMS](https://github.com/duxlabs-dev/dux-shell) for full documentation and configuration. To use niri, pick it from your display manager and configure it in `~/.config/niri/config.kdl`.

### Renamed packages

Some packages were renamed in the Dux Labs channels. There the old names remain as transitional/obsoleted packages, so your regular update command (`dnf upgrade`, `apt upgrade`, `xbps-install -Su`) moves you to the new name automatically. Binaries keep their names.

| Old name | New name |
| --- | --- |
| `danksearch` | `dux-search` |
| `dankcalendar` / `dankcalendar-git` | `dux-calendar` / `dux-calendar-git` |
| `dgop` | `dux-gop` |
| `dms-greeter` / `dms-greeter-git` | `dux-greeter` / `dux-greeter-git` |

### Migrating from AvengeMedia / danklinux

The legacy AvengeMedia channels (`avengemedia/danklinux`, `avengemedia/dms` and `avengemedia/dms-git` on Copr and Launchpad, `home:AvengeMedia:*` on OBS, and the old Void mirrors) are deprecated and frozen: their git builds no longer update, new packages such as `dux-qt-base` and `dux-edit` are never published there, and they will be retired. Switch to the channels above:

- **DMS 2.1.0 or newer**: run `dms migrate dux` (add `--dry-run` to preview). It adds the Dux Labs repositories, removes the legacy ones, switches installed packages over on openSUSE and installs renamed packages under their new names on Debian.
- **By hand**: remove the old repository files (`danklinux`, `dms`, `dms-git`), then follow [Installation](#installation).

## Automation

The Copr, OBS, PPA and Void workflows (`run-copr.yml`, `run-obs-v2.yml`, `run-ppa.yml`, `run-xbps.yml`) run every 6 hours: stable packages follow tagged upstream releases and `-git` packages rebuild when upstream changes. OBS package definitions live in `distro/config/obs-packages.yaml`.

#### Automatic rebuilds on Qt updates

quickshell, quickshell-git, dux-qt-base, dux-qt-base-git and qt6ct-kde link private Qt ABI and must be rebuilt whenever Fedora ships a new qt6-qtbase, qt6-qtdeclarative or qt6-qtwayland. The `Rebuild for Fedora Qt updates` workflow (`.github/workflows/run-qt-rebuild.yml`) runs hourly: it queries the Fedora repos for every Fedora chroot in the Copr project, compares against `distro/fedora/qt6-baseline.json`, bumps the Qt-linked specs once and triggers the Copr builds. Run it by hand from the Actions tab, or fire `repository_dispatch` with event type `fedora-qt-update` (an external watcher does this when a matching Bodhi update reaches stable).

Debian and Ubuntu get the same treatment from `Rebuild for Debian/Ubuntu Qt updates` (`.github/workflows/run-qt-rebuild-deb.yml`, hourly): it reads the published OBS Debian repos and the Ubuntu archive, keeps `distro/qt6-baseline-deb.json`, bumps `.dbN` on OBS (debian only, openSUSE rebuilds itself) and uploads `ppaN` for the affected Ubuntu series only. Void gets `Rebuild for Void Qt updates` (`.github/workflows/run-qt-rebuild-void.yml`, hourly): it reads the Void `current` repodata, keeps `distro/void/qt6-baseline.json`, bumps `revision` in the `dux-qt-base` template and dispatches `run-xbps.yml` for it. quickshell on Void is Void's own package and is rebuilt by Void.

Arch gets `Rebuild for Arch Qt updates` (`.github/workflows/run-qt-rebuild-arch.yml`, hourly): it reads the Arch x86_64 package API and the Arch Linux ARM `extra.db`, keeps `distro/arch/qt6-baseline.json`, and when a whole qt6 set moved it reruns the dux-qt-base `Create Release` workflow for the latest tag so fresh `dux-qt-base-<ver>-qt<qtver>-<arch>.tar.zst` assets exist, then dispatches `run-aur.yml` (`arch-qt-rebuild`) to repin `_qtver_<arch>` in `dux-qt-base-bin` and bump `pkgrel` on it and on `dux-qt-base`. An arch whose qt6 packages disagree is left for the next hour so a half-finished rollout is never pinned.

#### AUR

The AUR packages we maintain (`dux-*-bin`, `dux-qt-base`, `dux-qt-base-bin`, and the `-git` packages) are pushed by `Update AUR Packages` (`.github/workflows/run-aur.yml`) through `distro/scripts/aur/aur-update.sh`. Release packages follow the latest GitHub release every six hours and on `suite-release`, `greeter-release` and `qt-base-release` dispatches; git packages only move on a manual `pkgrel` bump. The script refreshes checksums with `updpkgsums`, regenerates `.SRCINFO`, and retries the AUR clone and push up to `AUR_RETRIES` (8) times with backoff, rebasing on the remote between attempts. It needs the `AUR_SSH_KEY` and `AUR_KNOWN_HOSTS` secrets.

## Upstream Projects

- [Dux Shell](https://github.com/duxlabs-dev/dux-shell) - DMS desktop environment
- [Dux Greeter](https://github.com/duxlabs-dev/dux-greeter) - greetd greeter (`dux-greeter` / `dux-greeter-git`); Copr, OBS, PPA and Void packages are built from this repo
- [Niri](https://github.com/YaLTeR/niri) - Scrollable-tiling Wayland compositor  
- [Quickshell](https://github.com/outfoxxed/quickshell) - QtQuick desktop shell toolkit  
- [Matugen](https://github.com/InioX/matugen) - Material You color generator  
- [Cliphist](https://github.com/sentriz/cliphist) - Wayland clipboard manager  
- [Dux Search](https://github.com/duxlabs-dev/dux-search) - Application launcher  
- [Dgop](https://github.com/duxlabs-dev/dux-gop) - Package manager integration

## Contributing

Packaging specs and automation are maintained in this repository.

- **Packaging issues**: [GitHub Issues](https://github.com/duxlabs-dev/dux-repo/issues)
- **Upstream bugs**: Report to the respective project repositories

## License

Packages retain their upstream licenses: Niri (GPL-3.0), Quickshell (LGPL-3.0), Matugen (GPL-2.0), Cliphist (GPL-3.0).
