%global sover 0
%global libname libdux-qt-base%{sover}

Name:           dux-qt-base
Version:        0.3.2
Release:        1%{?dist}
Summary:        Quickshell QML runtime as a shared library with a C entry point

License:        LGPL-3.0-only
URL:            https://github.com/duxlabs-dev/dux-qt-base
Source0:        %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

BuildRequires:  cmake
BuildRequires:  gcc-c++
BuildRequires:  ninja
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
BuildRequires:  qt6-base-private-devel
BuildRequires:  qt6-declarative-private-devel
BuildRequires:  qt6-waylandclient-private-devel
BuildRequires:  cli11-devel
BuildRequires:  spirv-tools
BuildRequires:  vulkan-headers
BuildRequires:  wayland-devel
BuildRequires:  wayland-protocols-devel >= 1.41
BuildRequires:  Mesa-libEGL-devel
BuildRequires:  libgbm-devel
BuildRequires:  pkgconfig(glib-2.0)
BuildRequires:  pkgconfig(gobject-2.0)
BuildRequires:  pkgconfig(libdrm)
BuildRequires:  pkgconfig(libpipewire-0.3)
BuildRequires:  pkgconfig(pam)
BuildRequires:  pkgconfig(polkit-agent-1)
BuildRequires:  pkgconfig(polkit-gobject-1)
BuildRequires:  pkgconfig(wayland-client)
BuildRequires:  pkgconfig(xcb)
BuildRequires:  pkgconfig(xkbcommon)

%description
Quickshell QML runtime, built as libdux-qt-base.so. Exposes the quickshell
command line as dqb_main() so Go and C programs can embed it. QML modules are
compiled into the library.

%package -n %{libname}
Summary:        Quickshell QML runtime shared library
Requires:       qt6-wayland
Recommends:     qt6-svg-imports

%description -n %{libname}
Quickshell QML runtime, built as libdux-qt-base.so. Exposes the quickshell
command line as dqb_main() so Go and C programs can embed it. QML modules are
compiled into the library.

%package        devel
Summary:        Development files for %{name}
Requires:       %{libname} = %{version}-%{release}
Requires:       pkgconfig

%description    devel
Header and pkg-config file for linking against libdux-qt-base. Go consumers
use `#cgo pkg-config: dux-qt-base`.

%prep
%setup -q -n %{name}-%{version}

%build
cmake -GNinja -B build \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX=%{_prefix} \
    -DCMAKE_INSTALL_LIBDIR=%{_lib} \
    -DDISTRIBUTOR="openSUSE OBS (%{name})" \
    -DGIT_REVISION="v%{version}"
cmake --build build

%install
DESTDIR=%{buildroot} cmake --install build

%post -n %{libname} -p /sbin/ldconfig
%postun -n %{libname} -p /sbin/ldconfig

%files -n %{libname}
%license LICENSE LICENSE-GPL
%doc README.md UPSTREAM.md
%{_libdir}/libdux-qt-base.so.%{sover}
%{_libdir}/libdux-qt-base.so.%{sover}.*

%files devel
%doc BUILD.md
%{_includedir}/dux-qt-base/
%{_libdir}/libdux-qt-base.so
%{_libdir}/pkgconfig/dux-qt-base.pc

%changelog
* Fri Nov 06 2026 Avenge Media <AvengeMedia.US@gmail.com> - 0.3.2-1
- initial library packaging
