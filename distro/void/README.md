# Void Linux packaging

XBPS templates for the Dux Labs tools that aren't yet in the Void repositories.
Each builds from source from its upstream release.

| Package | Binary | Upstream | Description |
| --- | --- | --- | --- |
| `dgop` | `dgop` | [duxlabs-dev/dux-gop](https://github.com/duxlabs-dev/dux-gop) | System monitor / telemetry CLI |
| `danksearch` | `dsearch` | [duxlabs-dev/dux-search](https://github.com/duxlabs-dev/dux-search) | Fast filesystem search |
| `dankcalendar` | `dcal` | [duxlabs-dev/dux-calendar](https://github.com/duxlabs-dev/dux-calendar) | Calendar app (Local, Google, CalDAV, iCloud) |
| `dux-files` | `dfiles` | [duxlabs-dev/dux-files](https://github.com/duxlabs-dev/dux-files) | File manager |
| `dms-greeter` | `dms-greeter` | [duxlabs-dev/dux-greeter](https://github.com/duxlabs-dev/dux-greeter) | greetd login screen (stable release) |
| `dms-greeter-git` | `dms-greeter` | [duxlabs-dev/dux-greeter](https://github.com/duxlabs-dev/dux-greeter) | greetd login screen (master snapshot) |

`dgop` and `danksearch` integrate with Dux Shell; `dankcalendar` is a
standalone app. The `dms` / `dms-git` Void packages live in the
[Dux Shell repo](https://github.com/duxlabs-dev/dux-shell/tree/master/distro/void).

`run-xbps.yml` builds every package here, the greeter from a fresh
`dux-greeter` clone (`distro/scripts/void/void-build.sh`), and publishes them
all to `https://void.duxlabs.dev/dux-repo/current`.

While `LEGACY_MIRROR` is on, the same run also republishes the tools to
`danklinux/current` and the greeter to `dms/current`, so installs from before
the rebrand keep updating. `dms/current` is shared with the Dux Shell
publisher; both use `publish-void-r2.sh` with an ETag guard so one cannot
overwrite the other's index.

## Distribution

Until these packages are officially merged upstream in the Void Linux
repositories, you can install them from our Cloudflare R2-backed XBPS
repository at `void.duxlabs.dev`.

> **Repository migration:** the former GitHub Pages repository will be frozen
> for 14 days at cutover. Its retirement date will be announced when the
> snapshot is frozen. Replace any existing `avengemedia.github.io` entry with
> the URL below.
>
> Existing installs: run `dms migrate dux`.

### Using the Self-Hosted Repository

Add the repository configuration to your system:

```sh
echo "repository=https://void.duxlabs.dev/dux-repo/current" | sudo tee /etc/xbps.d/dux.conf
```

Synchronize repositories and install the package(s):

```sh
sudo xbps-install -S dgop danksearch dankcalendar dux-files
```

The greeter comes from the same repository:

```sh
sudo xbps-install -S dms-greeter
```

*Note: On the first sync, `xbps-install` will output our signing key fingerprint and ask you to type `y` to trust and import it. Verify that the key matches our official signing fingerprint.*

## Build from Source

In a [void-packages](https://github.com/void-linux/void-packages) checkout, copy
each `srcpkgs/<pkg>` directory in, then:

```sh
./xbps-src pkg dgop
./xbps-src pkg danksearch
./xbps-src pkg dankcalendar
sudo xbps-install --repository=hostdir/binpkgs dankcalendar
```


To lint a template, use `xlint srcpkgs/dankcalendar/template` (from the `xtools`
package). These are Go packages and need Go ≥ 1.25 in the build environment.
