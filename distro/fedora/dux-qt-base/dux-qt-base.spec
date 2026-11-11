Name:           dux-qt-base
Version:        0.3.8
Release:        1%{?dist}
Summary:        Quickshell QML runtime as a shared library with a C entry point

License:        LGPL-3.0-only
URL:            https://github.com/duxlabs-dev/dux-qt-base
Source0:        %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

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

Conflicts:      %{name}-git

%description
Quickshell QML runtime, built as libdux-qt-base.so. Exposes the quickshell
command line as dqb_main() so Go and C programs can embed it. QML modules are
compiled into the library.

%package        devel
Summary:        Development files for %{name}
Requires:       %{name}%{?_isa} = %{version}-%{release}
Requires:       pkgconfig
Conflicts:      %{name}-git-devel

%description    devel
Header and pkg-config file for linking against libdux-qt-base. Go consumers
use `#cgo pkg-config: dux-qt-base`.

%prep
%autosetup -n %{name}-%{version} -p1

%build
%cmake -GNinja \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DCMAKE_INSTALL_LIBDIR=%{_lib} \
        -DDISTRIBUTOR="Fedora COPR (%{name})" \
        -DGIT_REVISION="v%{version}"
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
* Wed Nov 11 2026 github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com> - 0.3.8-1
- update to 0.3.8

* Tue Nov 10 2026 github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com> - 0.3.7-1
- update to 0.3.7

* Tue Nov 10 2026 github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com> - 0.3.6-1
- update to 0.3.6

* Tue Nov 10 2026 github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com> - 0.3.5-1
- update to 0.3.5

* Sun Nov 08 2026 github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com> - 0.3.4-1
- update to 0.3.4

* Fri Nov 06 2026 Avenge Media <AvengeMedia.US@gmail.com> - 0.3.2-1
- initial library packaging
