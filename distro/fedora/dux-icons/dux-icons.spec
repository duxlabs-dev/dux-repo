Name:               dux-icons
Version:            0.1.3
Release:            1%{?dist}
Summary:            Icon theme generator that follows your Material colors

# Material Symbols marks in src/own/ are Apache-2.0 (see NOTICE)
License:            MIT AND Apache-2.0
URL:                https://github.com/duxlabs-dev/dux-icons
Source0:            %{url}/archive/v%{version}/dux-icons-%{version}.tar.gz

BuildArch:          noarch

BuildRequires:      make
BuildRequires:      python3

Requires:           python3
Requires:           hicolor-icon-theme

%description
Dux Icons builds a standard icon theme of SVG icons from the desktop's
Material colors: each installed app's own icon framed on a common badge, plus
folders, places and file types drawn for the theme. DMS rebuilds it on every
wallpaper or theme change; elsewhere run dux-icons with the colors to use.

%prep
%autosetup -n dux-icons-%{version} -p1

%build
# Nothing to build: the generator is a standard-library Python script

%install
%make_install PREFIX=%{_prefix}
sed -i '1s|^#!/usr/bin/env python3|#!%{python3}|' %{buildroot}%{_datadir}/dux-icons/scripts/build.py

%check
%{python3} -m unittest

%files
%license LICENSE NOTICE
%doc README.md
%{_bindir}/dux-icons
%{_datadir}/dux-icons

%changelog
* Fri Nov 20 2026 Dux Labs <DuxLabsDev@gmail.com> - 0.1.3-1
- Initial stable package
