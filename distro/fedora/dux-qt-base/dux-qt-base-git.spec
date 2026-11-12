# dux-qt-base git snapshots (Fedora/Copr). Conflicts with stable, never Obsoletes dux-qt-base.
# %%global commit/commits/snapdate/tag are rewritten by copr-update.sh; tag is one patch above the latest stable release.

%global commit      53c28300add0c28df0d4c765a6c70263d8c02b63
%global commits     941
%global snapdate    20261112
%global tag         0.4.3

Name:           dux-qt-base-git
Version:        %{tag}^%{commits}.git%(c=%{commit}; echo ${c:0:7})
Release:        1%{?dist}
Summary:        Quickshell QML runtime as a shared library with a C entry point (git)

License:        LGPL-3.0-only
URL:            https://github.com/duxlabs-dev/dux-qt-base
Source0:        %{url}/archive/%{commit}/dux-qt-base-%{commit}.tar.gz

BuildRequires:  cmake
BuildRequires:  gcc-c++
BuildRequires:  ninja-build
BuildRequires:  pkgconfig
BuildRequires:  cmake(Qt6Core) >= 6.8.0
BuildRequires:  cmake(Qt6DBus)
BuildRequires:  cmake(Qt6Network)
BuildRequires:  cmake(Qt6Qml)
BuildRequires:  cmake(Qt6Quick)
BuildRequires:  cmake(Qt6QuickControls2)
BuildRequires:  cmake(Qt6ShaderTools)
BuildRequires:  cmake(Qt6WaylandClient)
BuildRequires:  cmake(Qt6Widgets)
BuildRequires:  qt6-qtbase-private-devel
BuildRequires:  pkgconfig(CLI11)
BuildRequires:  pkgconfig(egl)
BuildRequires:  pkgconfig(gbm)
BuildRequires:  pkgconfig(glib-2.0)
BuildRequires:  pkgconfig(gobject-2.0)
BuildRequires:  pkgconfig(libdrm)
BuildRequires:  pkgconfig(libpipewire-0.3)
BuildRequires:  pkgconfig(pam)
BuildRequires:  pkgconfig(polkit-agent-1)
BuildRequires:  pkgconfig(polkit-gobject-1)
BuildRequires:  pkgconfig(wayland-client)
BuildRequires:  pkgconfig(wayland-protocols) >= 1.41
BuildRequires:  pkgconfig(xcb)
BuildRequires:  pkgconfig(xkbcommon)
BuildRequires:  spirv-tools
BuildRequires:  vulkan-headers
BuildRequires:  wayland-devel

Requires:       qt6-qtwayland%{?_isa}
Recommends:     qt6-qtsvg%{?_isa}

Provides:       dux-qt-base = %{version}-%{release}
Conflicts:      dux-qt-base

%description
Quickshell QML runtime, built as libdux-qt-base.so from the master branch.
Exposes the quickshell command line as dqb_main() so Go and C programs can
embed it. QML modules are compiled into the library.

%package        devel
Summary:        Development files for %{name}
Requires:       %{name}%{?_isa} = %{version}-%{release}
Requires:       pkgconfig
Provides:       dux-qt-base-devel = %{version}-%{release}
Conflicts:      dux-qt-base-devel

%description    devel
Header and pkg-config file for linking against libdux-qt-base. Go consumers
use `#cgo pkg-config: dux-qt-base`.

%prep
%autosetup -n dux-qt-base-%{commit} -p1

%build
%cmake -GNinja \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DCMAKE_INSTALL_LIBDIR=%{_lib} \
        -DDISTRIBUTOR="Fedora COPR (%{name})" \
        -DGIT_REVISION="%{commit}"
%cmake_build

%install
%cmake_install

%files
%license LICENSE LICENSE-GPL
%doc README.md UPSTREAM.md
%{_libdir}/libdux-qt-base.so.0
%{_libdir}/libdux-qt-base.so.0.*

%files devel
%doc BUILD.md
%{_includedir}/dux-qt-base/
%{_libdir}/libdux-qt-base.so
%{_libdir}/pkgconfig/dux-qt-base.pc

%changelog
* Thu Nov 12 2026 github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com> - 0.4.3^941.git53c2830-1
- update to 0.4.3^941.git53c2830

* Thu Nov 12 2026 github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com> - 0.4.2^939.gitc15e6fc-2
- rebuild for qt6-qtdeclarative-6.11.2-3.fc45 (f45)

* Wed Nov 11 2026 github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com> - 0.4.2^939.gitc15e6fc-1
- update to 0.4.2^939.gitc15e6fc

* Wed Nov 11 2026 github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com> - 0.4.1^938.gite201265-2
- rebuild for qt6-qtdeclarative-6.12.0-2.fc46 (rawhide)

* Wed Nov 11 2026 github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com> - 0.4.1^938.gite201265-1
- update to 0.4.1^938.gite201265

* Wed Nov 11 2026 github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com> - 0.3.10^936.git5f41fd5-1
- update to 0.3.10^936.git5f41fd5

* Wed Nov 11 2026 github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com> - 0.3.9^935.git549921b-1
- update to 0.3.9^935.git549921b

* Tue Nov 10 2026 github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com> - 0.3.8^934.git2015943-1
- update to 0.3.8^934.git2015943

* Tue Nov 10 2026 github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com> - 0.3.8^933.gitcabe723-1
- update to 0.3.8^933.gitcabe723

* Tue Nov 10 2026 github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com> - 0.3.6^930.git6a3a736-1
- update to 0.3.6^930.git6a3a736

* Tue Nov 10 2026 github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com> - 0.3.6^927.git93a1772-1
- update to 0.3.6^927.git93a1772

* Mon Nov 09 2026 github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com> - 0.3.5^921.git73f963e-1
- update to 0.3.5^921.git73f963e

* Sun Nov 08 2026 github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com> - 0.3.5^920.gitdbeec85-1
- update to 0.3.5^920.gitdbeec85

* Sun Nov 08 2026 github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com> - 0.3.5^919.gita496d89-1
- update to 0.3.5^919.gita496d89

* Sat Nov 07 2026 github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com> - 0.3.3^917.git64ec3a8-1
- update to 0.3.3^917.git64ec3a8

* Sat Nov 07 2026 github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com> - 0.3.3^916.git67f3cc6-1
- update to 0.3.3^916.git67f3cc6

* Sat Nov 07 2026 Avenge Media <AvengeMedia.US@gmail.com> - 0.3.3^897.git032cf5e-1
- initial git snapshot packaging
