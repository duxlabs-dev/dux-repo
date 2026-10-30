Name:           dux-search
Version:        0.1.1
# Release prefix must sort above the last build under the old name
Release:        4.<CI_CNT>.<B_CNT>
Summary:        Fast file search utility for DMS

License:        MIT
URL:            https://github.com/duxlabs-dev/dux-search
Source0:        https://github.com/duxlabs-dev/dux-search/releases/download/v%{version}/dsearch-linux-amd64.gz
Source1:        https://github.com/duxlabs-dev/dux-search/releases/download/v%{version}/dsearch-linux-arm64.gz

Provides:       danksearch = %{?epoch:%{epoch}:}%{version}-%{release}
Obsoletes:      danksearch < %{?epoch:%{epoch}:}%{version}-%{release}

%description
Dux Search is a fast file search utility designed for Dux Shell.
It provides efficient file and content search capabilities with minimal
dependencies.

%prep
%ifarch x86_64
gunzip -c %{SOURCE0} > danksearch
%endif
%ifarch aarch64
gunzip -c %{SOURCE1} > danksearch
%endif
chmod +x danksearch

%build

%install
install -Dm755 danksearch %{buildroot}%{_bindir}/danksearch
ln -s danksearch %{buildroot}%{_bindir}/dsearch

%files
%{_bindir}/danksearch
%{_bindir}/dsearch

%changelog
* Fri Oct 30 2026 Purian23 <purian23@users.noreply.github.com> - 2.0.0
- Rename package from danksearch
* Sat Dec 13 2025 Avenge Media <AvengeMedia.US@gmail.com> - 0.1.0-1
- Update to upstream version 0.1.0
* Fri Nov 22 2025 Avenge Media <AvengeMedia.US@gmail.com> - 0.0.7-1
- Add dsearch symlink for compatibility
