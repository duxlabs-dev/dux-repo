# Zig Binary Repackaging for OBS

## Overview

The Zig packages (zig16, zig17) are **fundamentally different** from other packages in the danklinux repository:

- **Other packages**: Clone source code, compile, vendor dependencies
- **Zig packages**: Download pre-built official binaries, repackage them

This approach is necessary because:
1. Zig requires itself to build (bootstrap problem)
2. Official binaries are optimized and tested
3. Faster builds (no compilation)
4. Consistent with how most distros package Zig

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Zig Build Workflow                        │
└─────────────────────────────────────────────────────────────┘

1. Download Official Binaries (ziglang.org)
   ├─ zig-x86_64-linux-0.17.0.tar.xz (50MB)
   └─ zig-aarch64-linux-0.17.0.tar.xz (50MB)

2. Create Distribution-Specific Packages
   ├─ Debian (3.0 quilt format)
   │  ├─ orig.tar.xz (100MB with both binaries)
   │  ├─ debian.tar.xz (packaging files)
   │  └─ .dsc (auto-generated checksums)
   │
   └─ OpenSUSE (RPM format)
      ├─ .tar.gz (100MB with both binaries)
      ├─ .spec (build instructions)
      └─ -rpmlintrc (suppress false positives)

3. Upload to OBS

4. OBS Builds for Each Platform
   ├─ Extracts binary for current architecture
   ├─ Installs to /usr/lib/zig-VERSION/
   └─ Creates symlink /usr/bin/zig-VERSION
```

## Build Scripts

### build-zig-debian.sh

**Purpose**: Create Debian source packages with proper 3.0 (quilt) format

**How it works**:
```bash
# 1. Download binaries
curl ziglang.org/download/0.17.0/zig-x86_64-linux-0.17.0.tar.xz
curl ziglang.org/download/0.17.0/zig-aarch64-linux-0.17.0.tar.xz

# 2. Create orig.tar.xz (upstream source)
tar -cJf zig17_0.17.0.orig.tar.xz \
    zig17-0.17.0/
    ├─ zig-x86_64-linux-0.17.0.tar.xz
    └─ zig-aarch64-linux-0.17.0.tar.xz

# 3. Add debian/ directory and run dpkg-source
cd zig17-0.17.0/
cp -r distro/debian/zig/zig17/debian .
dpkg-source -b .

# 4. Output files ready for upload
zig17_0.17.0.orig.tar.xz       # Both arch binaries
zig17_0.17.0-1.debian.tar.xz   # Packaging files
zig17_0.17.0-1.dsc             # Checksums (auto-generated)
```

**Key concepts**:
- **3.0 (quilt)** format separates upstream (orig.tar.xz) from Debian (debian.tar.xz)
- **Both architectures** in single orig.tar.xz
- **debian/rules** extracts appropriate binary based on DEB_HOST_ARCH
- **dpkg-source** automatically generates correct checksums
- **No network** needed during OBS build (binaries included)

### build-zig-opensuse.sh

**Purpose**: Create OpenSUSE RPM source packages

**How it works**:
```bash
# 1. Download binaries
curl ziglang.org/download/0.17.0/zig-x86_64-linux-0.17.0.tar.xz
curl ziglang.org/download/0.17.0/zig-aarch64-linux-0.17.0.tar.xz

# 2. Create simple tarball at root level
tar -czf zig17-0.17.0.tar.gz \
    zig-x86_64-linux-0.17.0.tar.xz \
    zig-aarch64-linux-0.17.0.tar.xz

# 3. Copy .spec and -rpmlintrc files
cp distro/opensuse/zig/zig17.spec .
cp distro/opensuse/zig/zig17-rpmlintrc .

# 4. Output files ready for upload
zig17-0.17.0.tar.gz    # Both arch binaries at root
zig17.spec             # Build instructions
zig17-rpmlintrc        # Suppress linter warnings
```

**Key concepts**:
- **Simple .tar.gz** with binaries at root level
- **%setup -q -c** creates directory and extracts
- **%prep** section extracts binary for current %{_arch}
- **No compilation** in %build section
- **rpmlintrc** suppresses false positives about stdlib .h/.cpp files

## Comparison with Normal Packages

### Normal Package Build Flow
```
obs-build-debian.sh/obs-build-opensuse.sh
↓
Clone from GitHub
↓
Vendor dependencies (Rust/Go)
↓
Create source tarball
↓
Upload to OBS
↓
OBS compiles from source
```

### Zig Package Build Flow
```
build-zig-debian.sh/build-zig-opensuse.sh
↓
Download official binaries from ziglang.org
↓
Repackage with both architectures
↓
Upload to OBS
↓
OBS extracts appropriate binary (no compilation)
```

## Why Not Integrate with obs-orchestrator.sh?

The zig packages are intentionally **separate** from the main automation:

1. **Different source**: ziglang.org instead of GitHub
2. **Infrequent updates**: Zig releases slowly (months between versions)
3. **Manual verification**: Want to test each Zig release before packaging
4. **Dependency for other packages**: Ghostty 1.4.0+ depends on zig17
   (minimum_zig_version = 0.17.0)
5. **Multiple versions**: each Zig minor gets its own package (zig16, zig17)
   so they can coexist. zig15 was retired with Ghostty 1.4.0

## File Organization

```
distro/
├─ debian/zig/
│  ├─ zig16/debian/
│  │  ├─ source/format      # "3.0 (quilt)"
│  │  ├─ control            # Package metadata
│  │  ├─ rules              # Build instructions
│  │  ├─ changelog          # Version history
│  │  └─ copyright          # License info
│  └─ zig17/debian/         # Same structure
│
├─ opensuse/zig/
│  ├─ zig16.spec            # RPM build instructions
│  ├─ zig16-rpmlintrc       # Suppress false positives
│  ├─ zig17.spec
│  └─ zig17-rpmlintrc
│
└─ scripts/obs/zig/
   ├─ build-zig-debian.sh   # Build Debian packages
   ├─ build-zig-opensuse.sh # Build OpenSUSE packages
   └─ README.md            # This file
```

## Usage

### Building Packages

```bash
cd distro/scripts/obs/zig

# Build Debian packages
./build-zig-debian.sh zig16 /tmp/zig16-debian
./build-zig-debian.sh zig17 /tmp/zig17-debian

# Build OpenSUSE packages
./build-zig-opensuse.sh zig16 /tmp/zig16-opensuse
./build-zig-opensuse.sh zig17 /tmp/zig17-opensuse
```

### Uploading to OBS

**Option 1**: Upload both distros together
```bash
cd distro/scripts/obs

# Copy both Debian and OpenSUSE files into one directory
mkdir /tmp/zig17-complete
cp /tmp/zig17-debian/* /tmp/zig17-complete/
cp /tmp/zig17-opensuse/* /tmp/zig17-complete/

# Upload with --distro=both
./obs-upload.sh --distro=both zig17 /tmp/zig17-complete
```

**Option 2**: Upload separately (not recommended - files get removed)
```bash
# Don't do this - uploading one distro removes the other's files!
./obs-upload.sh --distro=debian zig17 /tmp/zig17-debian
./obs-upload.sh --distro=opensuse zig17 /tmp/zig17-opensuse
```

### Checking Build Status

```bash
# Check all builds
osc results home:AvengeMedia:danklinux zig16
osc results home:AvengeMedia:danklinux zig17

# Check specific build log
osc buildlog home:AvengeMedia:danklinux zig17 Debian_Unstable x86_64
osc buildlog home:AvengeMedia:danklinux zig17 openSUSE_Tumbleweed x86_64
```

## Updating to New Zig Versions

When a new Zig version is released:

### For Minor Updates (e.g., 0.17.0 → 0.17.1)
```bash
# 1. Update version in scripts (build-zig-debian.sh, build-zig-opensuse.sh)
zig17) ZIG_VERSION="0.17.1" ;;

# 2. Update distro packaging
# - debian/zig/zig17/debian/changelog + rules (ZIG_VERSION, install paths)
# - opensuse/zig/zig17.spec + zig17-rpmlintrc

# 3. Rebuild and test locally
./build-zig-debian.sh zig17 /tmp/test
tar -tf /tmp/test/zig17_0.17.1.orig.tar.xz  # Verify structure

# 4. Upload to OBS
./obs-upload.sh --distro=both zig17 /tmp/test
```

### For Major Updates (e.g., 0.18.0)
```bash
# 1. Create new package directories
mkdir -p distro/debian/zig/zig18/debian
mkdir -p distro/opensuse/zig/

# 2. Copy and modify from zig16/zig17
# - Update version numbers
# - Update package names (zig18)
# - Update install paths (/usr/lib/zig-0.18.0)

# 3. Update build scripts to support zig18
# 4. Build and upload as new package
```

## Troubleshooting

### Debian: "Cannot open: No such file or directory"
**Problem**: Binary tarballs not found during build

**Cause**: debian/rules clean removed the .tar.xz files

**Solution**: Ensure override_dh_auto_clean only removes extracted directories:
```makefile
override_dh_auto_clean:
	# Don't remove *.tar.xz files!
	rm -rf zig-x86_64-linux-$(ZIG_VERSION) zig-cache
	dh_auto_clean
```

### OpenSUSE: rpmlint errors about devel files
**Problem**: "devel-file-in-non-devel-package" errors

**Cause**: Zig stdlib includes .h and .cpp files

**Solution**: rpmlintrc file filters these:
```
addFilter("zig17.* devel-file-in-non-devel-package .*/zig-0.17.0/lib/")
```

### .dsc checksum mismatches
**Problem**: "MD5 sum mismatch" or "Size mismatch"

**Cause**: Manually editing files after dpkg-source generated .dsc

**Solution**: Never edit files after dpkg-source runs. Always let dpkg-source generate the .dsc

## Integration with Ghostty

Ghostty currently uses the zig17 package instead of downloading Zig:

### Debian
```debian
Build-Depends: zig17
```

### OpenSUSE
```spec
BuildRequires: zig17
```

Ghostty 1.4.0 requires `minimum_zig_version = 0.17.0`, so the Ghostty
packaging uses `zig17` and `/usr/bin/zig-0.17`. zig17 must be published on OBS
before Ghostty 1.4.0 is uploaded, or Ghostty sits in `unresolvable`.

This removes the need for wget/curl in Ghostty builds and ensures consistent Zig versions.

## Related Documentation

- `distro/opensuse/GHOSTTY-BUILD-NOTES.md` - Ghostty's integration with the zig packages
- `distro/scripts/obs/usage.md` - General OBS workflow
- `distro/OBS-REPOSITORY-SETUP.md` - OBS project configuration
