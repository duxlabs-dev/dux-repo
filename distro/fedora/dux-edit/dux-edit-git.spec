%global debug_package %{nil}

%global commit      0105da4ad93b0eacc63247e5ad309b62e22a25ff
%global commits     24
%global snapdate    20261124
%global tag         0.1.1
# dux-qml-common submodule commit for %%{commit} (GitHub archives ship submodules empty)
%global common_commit 7f565cf3bebd9a60bb2ad9a908591853b5832566

Name:               dux-edit-git
Version:            %{tag}+git%{commits}.%(c=%{commit}; echo ${c:0:8})
Release:            1%{?dist}
Summary:            Text and document editor for the Dux Labs desktop (git)

License:            MIT
URL:                https://github.com/duxlabs-dev/dux-edit
Source0:            %{url}/archive/%{commit}/dux-edit-%{commit}.tar.gz
Source1:            https://github.com/duxlabs-dev/dux-qml-common/archive/%{common_commit}/dux-qml-common-%{common_commit}.tar.gz

BuildRequires:      golang
BuildRequires:      git-core
BuildRequires:      make

Requires:          dux-qt-base-git
Requires:          qt6-qtdeclarative
Recommends:        polkit
Recommends:        hunspell
Recommends:        hunspell-en-US

Conflicts:         dux-edit
Provides:          dedit = %{version}-%{release}

%description
Dux Edit is a text and document editor for Wayland that sits between a
scratchpad and an IDE: tabs, drafts that survive a restart, crash recovery,
syntax highlighting colored from the desktop theme, Markdown preview,
spellcheck and saving root-owned files through polkit. A Go core does the
document work and carries its own QML UI, run on dux-qt-base.

This is the git development package built from upstream master.

%prep
%autosetup -n dux-edit-%{commit} -p1
rm -rf dux-qml-common
tar -xzf %{SOURCE1}
mv dux-qml-common-%{common_commit} dux-qml-common

%build
export GOTOOLCHAIN=auto
export GOFLAGS="-buildmode=pie -trimpath -mod=readonly -modcacherw"
export VERSION="%{tag}+git%{commits}.%(c=%{commit}; echo ${c:0:8})"
export BUILD_TIME="$(date -u '+%%Y-%%m-%%d_%%H:%%M:%%S')"
export COMMIT="$(echo %{commit} | cut -c1-8)"

# Embed the quickshell UI and build it into the binary.
make -C core sync-shell

cd core
CGO_ENABLED=0 go build \
    -tags withshell \
    -ldflags="-s -w -X main.Version=${VERSION} -X main.BuildTime=${BUILD_TIME} -X main.Commit=${COMMIT}" \
    -o ../dux-edit ./cmd/dux-edit
cd ..

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
%doc README.md
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
* Wed Nov 18 2026 Dux Labs <DuxLabsDev@gmail.com> - 0.1.0+git15.67ad782e-1
- Initial git package (commit 67ad782e)
