Name:           dux-gop
Version:        0.1.12
# Release prefix must sort above the last build under the old name
Release:        2.<CI_CNT>.<B_CNT>
Summary:        Stateless CPU/GPU monitor for Dux Shell

License:        MIT
URL:            https://github.com/duxlabs-dev/dux-gop
Source0:        https://github.com/duxlabs-dev/dux-gop/releases/download/v%{version}/dgop-linux-amd64.gz
Source1:        https://github.com/duxlabs-dev/dux-gop/releases/download/v%{version}/dgop-linux-arm64.gz

Provides:       dgop = %{?epoch:%{epoch}:}%{version}-%{release}
Obsoletes:      dgop < %{?epoch:%{epoch}:}%{version}-%{release}

%description
DGOP is a stateless system monitoring tool that provides CPU, GPU, memory, and 
network statistics. Designed for integration with Dux Shell but can be 
used standalone.

%prep
%ifarch x86_64
gunzip -c %{SOURCE0} > dgop
%endif
%ifarch aarch64
gunzip -c %{SOURCE1} > dgop
%endif
chmod +x dgop

%build

%install
install -Dm755 dgop %{buildroot}%{_bindir}/dgop

%files
%{_bindir}/dgop

%changelog
* Fri Oct 30 2026 Purian23 <purian23@users.noreply.github.com> - 2.0.0
- Rename package from dgop
* Tue Nov 18 2025 AvengeMedia <maintainer@avengemedia.com> - 0.1.11-1
- Initial OpenSUSE package
