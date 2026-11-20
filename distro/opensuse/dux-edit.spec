%global debug_package %{nil}

Name:           dux-edit
Version:        0.1.0
Release:        1%{?dist}
Summary:        Text and document editor for the Dux Labs desktop

License:        MIT
URL:            https://github.com/duxlabs-dev/dux-edit
Source0:        dux-edit-%{version}.tar.gz
Source1:        https://github.com/duxlabs-dev/dux-edit/releases/download/v%{version}/dux-edit-linux-amd64.gz
Source2:        https://github.com/duxlabs-dev/dux-edit/releases/download/v%{version}/dux-edit-linux-arm64.gz

Requires:       libdux-qt-base0 >= 0.4.3
Requires:       libQt6Quick6
Recommends:     polkit
Recommends:     hunspell
Recommends:     myspell-en_US

Conflicts:      dux-edit-git
Provides:       dedit = %{version}-%{release}

%description
Dux Edit is a text and document editor for Wayland that sits between a
scratchpad and an IDE: tabs, drafts that survive a restart, crash recovery,
syntax highlighting colored from the desktop theme, Markdown preview,
spellcheck and saving root-owned files through polkit. A Go core does the
document work and carries its own QML UI, run on dux-qt-base.

%prep
%setup -q -n dux-edit-%{version}
%ifarch x86_64
gunzip -c %{SOURCE1} > dux-edit
%endif
%ifarch aarch64
gunzip -c %{SOURCE2} > dux-edit
%endif
chmod +x dux-edit

%build
mkdir -p completions
./dux-edit completion bash > completions/dux-edit
./dux-edit completion zsh > completions/_dux-edit
./dux-edit completion fish > completions/dux-edit.fish

%install
install -Dm755 dux-edit %{buildroot}%{_bindir}/dux-edit
ln -sf dux-edit %{buildroot}%{_bindir}/dedit

install -Dm644 assets/dev.duxlabs.edit.svg \
    %{buildroot}%{_datadir}/icons/hicolor/scalable/apps/dev.duxlabs.edit.svg

install -Dm644 assets/dev.duxlabs.edit.desktop \
    %{buildroot}%{_datadir}/applications/dev.duxlabs.edit.desktop

install -Dm644 assets/dev.duxlabs.edit.metainfo.xml \
    %{buildroot}%{_datadir}/metainfo/dev.duxlabs.edit.metainfo.xml

install -Dm644 assets/dev.duxlabs.edit.policy \
    %{buildroot}%{_datadir}/polkit-1/actions/dev.duxlabs.edit.policy

install -Dm644 completions/dux-edit \
    %{buildroot}%{_datadir}/bash-completion/completions/dux-edit
install -Dm644 completions/_dux-edit \
    %{buildroot}%{_datadir}/zsh/site-functions/_dux-edit
install -Dm644 completions/dux-edit.fish \
    %{buildroot}%{_datadir}/fish/vendor_completions.d/dux-edit.fish

%files
%license LICENSE
%{_bindir}/dux-edit
%{_bindir}/dedit
%{_datadir}/applications/dev.duxlabs.edit.desktop
%{_datadir}/metainfo/dev.duxlabs.edit.metainfo.xml
%dir %{_datadir}/polkit-1
%dir %{_datadir}/polkit-1/actions
%{_datadir}/polkit-1/actions/dev.duxlabs.edit.policy
%dir %{_datadir}/icons/hicolor
%dir %{_datadir}/icons/hicolor/scalable
%dir %{_datadir}/icons/hicolor/scalable/apps
%{_datadir}/icons/hicolor/scalable/apps/dev.duxlabs.edit.svg
%dir %{_datadir}/bash-completion
%dir %{_datadir}/bash-completion/completions
%{_datadir}/bash-completion/completions/dux-edit
%dir %{_datadir}/zsh
%dir %{_datadir}/zsh/site-functions
%{_datadir}/zsh/site-functions/_dux-edit
%dir %{_datadir}/fish
%dir %{_datadir}/fish/vendor_completions.d
%{_datadir}/fish/vendor_completions.d/dux-edit.fish

%changelog
* Tue Nov 17 2026 Dux Labs <DuxLabsDev@gmail.com> - 0.1.0-1
- Initial stable package
