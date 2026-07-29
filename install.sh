#!/bin/bash

set -euo pipefail

COMPONENT=${1:-all}
DOTFILES_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

ensure_homebrew() {
    local brew_bin
    local brew_env

    if command -v brew &>/dev/null; then
        brew_bin=$(command -v brew)
    else
        echo "Homebrew가 없습니다. 설치 중..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        if [ -n "${HOMEBREW_PREFIX:-}" ] &&
            [ -x "$HOMEBREW_PREFIX/bin/brew" ]; then
            brew_bin="$HOMEBREW_PREFIX/bin/brew"
        else
            case "$(uname -m)" in
                arm64)
                    brew_bin="/opt/homebrew/bin/brew"
                    ;;
                x86_64)
                    brew_bin="/usr/local/bin/brew"
                    ;;
                *)
                    echo "지원하지 않는 아키텍처입니다: $(uname -m)" >&2
                    return 1
                    ;;
            esac
        fi
    fi

    if [ ! -x "$brew_bin" ]; then
        echo "Homebrew 실행 파일을 찾을 수 없습니다: $brew_bin" >&2
        return 1
    fi

    brew_env=$("$brew_bin" shellenv)
    eval "$brew_env"
}

install_zsh() {
    echo "=== zsh 설정 시작 ==="

    ensure_homebrew

    # oh-my-zsh 설치
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "oh-my-zsh 설치 중..."
        RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi

    # powerlevel9k 설치
    if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel9k" ]; then
        echo "powerlevel9k 테마 설치 중..."
        git clone https://github.com/Powerlevel9k/powerlevel9k.git \
            "$HOME/.oh-my-zsh/custom/themes/powerlevel9k"
    fi

    # fzf 설치
    if ! command -v fzf &>/dev/null; then
        echo "fzf 설치 중..."
        brew install fzf
    fi

    # zoxide 설치
    if ! command -v zoxide &>/dev/null; then
        echo "zoxide 설치 중..."
        brew install zoxide
    fi

    # bat 설치 (cat alias 대체)
    if ! command -v bat &>/dev/null; then
        echo "bat 설치 중..."
        brew install bat
    fi

    # 심볼릭 링크 생성
    echo "심볼릭 링크 생성 중..."
    ln -sf "$DOTFILES_DIR/zsh/zshrc" "$HOME/.zshrc"
    ln -sf "$DOTFILES_DIR/zsh/zprofile" "$HOME/.zprofile"

    # 머신별 설정 파일 생성 (없는 경우만)
    if [ ! -f "$HOME/.zshrc.local" ]; then
        echo "~/.zshrc.local 템플릿 복사 중..."
        cp "$DOTFILES_DIR/zsh/local.zsh.example" "$HOME/.zshrc.local"
        echo "~/.zshrc.local 을 환경에 맞게 수정하세요."
    fi

    echo "=== zsh 설정 완료! ==="
    echo "터미널을 재시작하거나 'source ~/.zshrc' 를 실행하세요."
}

install_vim() {
    echo "=== vim 설치 시작 ==="

    if [ ! -d "$HOME/.vim_runtime" ]; then
        echo "amix/vimrc 설치 중..."
        git clone --depth=1 https://github.com/amix/vimrc.git "$HOME/.vim_runtime"
        sh "$HOME/.vim_runtime/install_awesome_vimrc.sh"
    fi

    echo "심볼릭 링크 생성 중..."
    ln -sf "$DOTFILES_DIR/vim/my_configs.vim" "$HOME/.vim_runtime/my_configs.vim"

    if command -v swiftc &>/dev/null; then
        echo "macOS 입력 소스 전환 도구 빌드 중..."
        mkdir -p "$HOME/.local/bin"
        swiftc "$DOTFILES_DIR/vim/select-input-source.swift" -framework Carbon \
            -o "$HOME/.local/bin/select-input-source"
    else
        echo "swiftc가 없어 macOS 입력 소스 전환 도구 빌드를 건너뜁니다."
    fi

    echo "=== vim 설치 완료! ==="
}

install_tmux() {
    echo "=== tmux 설치 시작 ==="

    ensure_homebrew

    # tmux 설치
    if ! command -v tmux &>/dev/null; then
        echo "tmux 설치 중..."
        brew install tmux
    fi

    # yazi 설치
    if ! command -v yazi &>/dev/null; then
        echo "yazi 설치 중..."
        brew install yazi
    fi

    # Nerd Font 설치
    if ! fc-list 2>/dev/null | grep -i "JetBrainsMono Nerd" >/dev/null && \
       ! ls "$HOME/Library/Fonts/" 2>/dev/null | grep -i "JetBrainsMonoNerdFont" >/dev/null; then
        echo "JetBrains Mono Nerd Font 설치 중..."
        brew install --cask font-jetbrains-mono-nerd-font
    fi

    # TPM 설치
    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        echo "TPM(Tmux Plugin Manager) 설치 중..."
        git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    fi

    # catppuccin 플러그인 설치 및 업데이트
    if [ ! -d "$HOME/.tmux/plugins/tmux" ]; then
        echo "catppuccin 테마 설치 중..."
        git clone https://github.com/catppuccin/tmux "$HOME/.tmux/plugins/tmux"
    else
        echo "catppuccin 테마 업데이트 중..."
        git -C "$HOME/.tmux/plugins/tmux" pull
    fi

    # 심볼릭 링크 생성
    echo "심볼릭 링크 생성 중..."
    ln -sf "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"

    echo ""
    echo "=== tmux 설치 완료! ==="
    echo "터미널 폰트를 'JetBrainsMono Nerd Font'로 변경하세요."
    echo "tmux 실행 후 Prefix + I 를 눌러 나머지 플러그인을 설치하세요."
}

install_karabiner() {
    echo "=== Karabiner-Elements 설치 시작 ==="

    ensure_homebrew

    if ! brew list --cask karabiner-elements &>/dev/null; then
        echo "Karabiner-Elements 설치 중..."
        brew install --cask karabiner-elements
    else
        echo "Karabiner-Elements 이미 설치되어 있습니다."
    fi

    echo "심볼릭 링크 생성 중..."
    mkdir -p "$HOME/.config/karabiner"
    ln -sf "$DOTFILES_DIR/karabiner/karabiner.json" \
        "$HOME/.config/karabiner/karabiner.json"

    echo "=== Karabiner-Elements 설치 완료! ==="
    echo "Karabiner-Elements를 재시작하면 설정이 적용됩니다."
}

install_ghostty() {
    echo "=== Ghostty 설치 시작 ==="

    ensure_homebrew

    if ! brew list --cask ghostty &>/dev/null; then
        echo "Ghostty 설치 중..."
        brew install --cask ghostty
    else
        echo "Ghostty 이미 설치되어 있습니다."
    fi

    # D2Coding 폰트 설치
    if ! fc-list 2>/dev/null | grep -i "D2Coding" >/dev/null && \
       ! ls "$HOME/Library/Fonts/" 2>/dev/null | grep -i "D2Coding" >/dev/null; then
        echo "D2Coding 폰트 설치 중..."
        brew install --cask font-d2coding
    else
        echo "D2Coding 폰트 이미 설치되어 있습니다."
    fi

    echo "심볼릭 링크 생성 중..."
    mkdir -p "$HOME/.config/ghostty"
    ln -sf "$DOTFILES_DIR/ghostty/config" "$HOME/.config/ghostty/config"

    echo "=== Ghostty 설치 완료! ==="
}

install_claude() {
    echo "=== Claude 설치 시작 ==="

    ensure_homebrew

    # Claude 데스크탑 앱
    if ! brew list --cask claude &>/dev/null; then
        echo "Claude 데스크탑 앱 설치 중..."
        brew install --cask claude
    else
        echo "Claude 데스크탑 앱 이미 설치되어 있습니다."
    fi

    # Claude Code CLI
    if ! brew list --cask claude-code &>/dev/null; then
        echo "Claude Code CLI 설치 중..."
        brew install --cask claude-code
    else
        echo "Claude Code CLI 이미 설치되어 있습니다."
    fi

    if command -v npm &>/dev/null &&
        npm list -g --depth=0 2>/dev/null |
            grep -F "@anthropic-ai/claude-code" >/dev/null; then
        echo "⚠️  npm으로 설치한 Claude Code가 남아 있습니다." >&2
        echo "    충돌 방지: npm uninstall -g @anthropic-ai/claude-code" >&2
    fi

    echo "=== Claude 설치 완료! ==="
}

install_obsidian() {
    echo "=== Obsidian 설치 시작 ==="

    ensure_homebrew

    if ! brew list --cask obsidian &>/dev/null; then
        echo "Obsidian 설치 중..."
        brew install --cask obsidian
    else
        echo "Obsidian 이미 설치되어 있습니다."
    fi

    # vault 경로 설정
    VAULT_DIR="$HOME/obsidianVaults/my_vault"
    OBSIDIAN_CONFIG="$VAULT_DIR/.obsidian"
    DOTFILES_OBSIDIAN="$DOTFILES_DIR/obsidian/my_vault"

    if [ ! -d "$VAULT_DIR" ]; then
        echo "Vault 디렉토리 생성 중: $VAULT_DIR"
        mkdir -p "$VAULT_DIR"
    fi

    echo "Obsidian 설정 파일 복사 중..."
    mkdir -p "$OBSIDIAN_CONFIG/plugins"
    for f in app.json appearance.json community-plugins.json core-plugins.json graph.json types.json; do
        [ -f "$DOTFILES_OBSIDIAN/$f" ] && cp "$DOTFILES_OBSIDIAN/$f" "$OBSIDIAN_CONFIG/$f"
    done

    # 커뮤니티 플러그인 목록 다운로드 (repo 조회용)
    echo "플러그인 설치 중..."
    COMMUNITY_JSON=$(curl -fsSL "https://raw.githubusercontent.com/obsidianmd/obsidian-releases/master/community-plugins.json")

    for plugin_dir in "$DOTFILES_OBSIDIAN/plugins"/*/; do
        plugin_id=$(basename "$plugin_dir")
        target="$OBSIDIAN_CONFIG/plugins/$plugin_id"
        mkdir -p "$target"

        # 설정 파일 복사
        [ -f "$plugin_dir/manifest.json" ] && cp "$plugin_dir/manifest.json" "$target/"
        [ -f "$plugin_dir/data.json" ]     && cp "$plugin_dir/data.json" "$target/"

        # GitHub repo 조회 후 main.js 다운로드
        repo=$(echo "$COMMUNITY_JSON" | python3 -c "
import json, sys
plugins = json.load(sys.stdin)
for p in plugins:
    if p.get('id') == '$plugin_id':
        print(p.get('repo', ''))
        break
" 2>/dev/null)

        if [ -n "$repo" ]; then
            version=$(python3 -c "import json; print(json.load(open('$target/manifest.json'))['version'])" 2>/dev/null)
            base_url="https://github.com/$repo/releases/download/$version"
            echo "  [$plugin_id] $version 다운로드 중..."
            curl -fsSL "$base_url/main.js" -o "$target/main.js"
            if ! curl -fsSL "$base_url/styles.css" -o "$target/styles.css" 2>/dev/null; then
                rm -f "$target/styles.css"
            fi
        else
            echo "  [$plugin_id] 커뮤니티 목록에서 repo를 찾을 수 없습니다." >&2
            return 1
        fi
    done

    echo "=== Obsidian 설치 완료! ==="
    echo "Obsidian 실행 후 vault 경로를 '$VAULT_DIR' 로 열어주세요."
}

install_vscode() {
    echo "=== Visual Studio Code 설치 시작 ==="

    ensure_homebrew

    if ! brew list --cask visual-studio-code &>/dev/null; then
        echo "Visual Studio Code 설치 중..."
        brew install --cask visual-studio-code
    else
        echo "Visual Studio Code 이미 설치되어 있습니다."
    fi

    echo "VSCode 확장 설치 중..."
    extensions=(
        # AI
        anthropic.claude-code
        continue.continue
        kilocode.kilo-code
        google.geminicodeassist
        google.gemini-cli-vscode-ide-companion
        cosmowifi.gemini-code-assistant-korean-cosmowifi

        # Java / Spring
        redhat.java
        oracle.oracle-java
        vscjava.vscode-java-pack
        vscjava.vscode-java-debug
        vscjava.vscode-java-test
        vscjava.vscode-java-dependency
        vscjava.vscode-java-upgrade
        vscjava.migrate-java-to-azure
        vscjava.vscode-maven
        vscjava.vscode-gradle
        vscjava.vscode-spring-boot-dashboard
        vscjava.vscode-spring-initializr
        vmware.vscode-boot-dev-pack
        vmware.vscode-spring-boot

        # Python
        ms-python.python
        ms-python.debugpy
        ms-python.vscode-pylance
        ms-python.vscode-python-envs

        # Remote / Container
        ms-vscode-remote.remote-ssh
        ms-vscode-remote.remote-ssh-edit
        ms-vscode-remote.remote-containers
        ms-vscode.remote-explorer
        ms-azuretools.vscode-containers

        # DB
        cweijan.vscode-database-client2
        cweijan.dbclient-jdbc

        # 편의
        eamodio.gitlens
        humao.rest-client
        vscodevim.vim
        k--kato.intellij-idea-keybindings
        mechatroner.rainbow-csv
        bierner.markdown-mermaid
        yzhang.markdown-all-in-one
        ms-ceintl.vscode-language-pack-ko
    )

    for ext in "${extensions[@]}"; do
        [[ "$ext" == \#* ]] && continue
        code --install-extension "$ext" --force
    done

    echo "=== Visual Studio Code 설치 완료! ==="
}

install_intellij() {
    echo "=== IntelliJ IDEA Ultimate 설치 시작 ==="

    INTELLIJ_VERSION="2025.3.5"
    INTELLIJ_APP_NAME="IntelliJ IDEA Ultimate ${INTELLIJ_VERSION}.app"
    INTELLIJ_APP_PATH="/Applications/${INTELLIJ_APP_NAME}"
    INTELLIJ_LAUNCHER="$HOME/.local/bin/idea"

    if [ -d "$INTELLIJ_APP_PATH" ]; then
        installed_version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" \
            "$INTELLIJ_APP_PATH/Contents/Info.plist" 2>/dev/null || true)

        if [ "$installed_version" = "$INTELLIJ_VERSION" ]; then
            echo "IntelliJ IDEA Ultimate $INTELLIJ_VERSION 이미 설치되어 있습니다."
            mkdir -p "$HOME/.local/bin"
            ln -sf "$INTELLIJ_APP_PATH/Contents/MacOS/idea" "$INTELLIJ_LAUNCHER"
            echo "CLI launcher: $INTELLIJ_LAUNCHER"
            echo "=== IntelliJ IDEA Ultimate 설치 완료! ==="
            return
        fi

        echo "$INTELLIJ_APP_PATH 에 다른 버전($installed_version)이 있어 다시 설치합니다."
        rm -rf "$INTELLIJ_APP_PATH"
    fi

    case "$(uname -m)" in
        arm64)
            intellij_dmg="ideaIU-${INTELLIJ_VERSION}-aarch64.dmg"
            ;;
        x86_64)
            intellij_dmg="ideaIU-${INTELLIJ_VERSION}.dmg"
            ;;
        *)
            echo "지원하지 않는 아키텍처입니다: $(uname -m)"
            return 1
            ;;
    esac

    intellij_url="https://download.jetbrains.com/idea/${intellij_dmg}"
    tmp_dir=$(mktemp -d)
    mount_dir="$tmp_dir/mount"
    dmg_path="$tmp_dir/$intellij_dmg"
    mounted=0

    cleanup_intellij_install() {
        if [ "$mounted" -eq 1 ]; then
            hdiutil detach "$mount_dir" -quiet 2>/dev/null || true
        fi
        rm -rf "$tmp_dir"
    }

    mkdir -p "$mount_dir"
    echo "IntelliJ IDEA Ultimate $INTELLIJ_VERSION 다운로드 중..."
    if ! curl -fL "$intellij_url" -o "$dmg_path"; then
        echo "IntelliJ IDEA 다운로드에 실패했습니다: $intellij_url"
        cleanup_intellij_install
        return 1
    fi

    echo "DMG 마운트 중..."
    if ! hdiutil attach "$dmg_path" -mountpoint "$mount_dir" -nobrowse -quiet; then
        echo "IntelliJ IDEA DMG 마운트에 실패했습니다."
        cleanup_intellij_install
        return 1
    fi
    mounted=1

    source_app=$(find "$mount_dir" -maxdepth 1 -name "*.app" -print -quit)
    if [ -z "$source_app" ]; then
        echo "DMG에서 IntelliJ IDEA 앱 번들을 찾을 수 없습니다."
        cleanup_intellij_install
        return 1
    fi

    echo "앱 설치 중: $INTELLIJ_APP_PATH"
    if ! ditto "$source_app" "$INTELLIJ_APP_PATH"; then
        echo "IntelliJ IDEA 앱 복사에 실패했습니다."
        cleanup_intellij_install
        return 1
    fi

    mkdir -p "$HOME/.local/bin"
    ln -sf "$INTELLIJ_APP_PATH/Contents/MacOS/idea" "$INTELLIJ_LAUNCHER"
    cleanup_intellij_install

    echo "=== IntelliJ IDEA Ultimate 설치 완료! ==="
    echo "설치 경로: $INTELLIJ_APP_PATH"
    echo "CLI launcher: $INTELLIJ_LAUNCHER"
}

install_java() {
    echo "=== Java 설치 시작 ==="

    ensure_homebrew

    # Amazon Corretto 21 (기본값)
    if ! brew list --cask corretto@21 &>/dev/null; then
        echo "Amazon Corretto 21 설치 중..."
        brew install --cask corretto@21
    else
        echo "Amazon Corretto 21 이미 설치되어 있습니다."
    fi

    # Amazon Corretto 17
    if ! brew list --cask corretto@17 &>/dev/null; then
        echo "Amazon Corretto 17 설치 중..."
        brew install --cask corretto@17
    else
        echo "Amazon Corretto 17 이미 설치되어 있습니다."
    fi

    echo "=== Java 설치 완료! ==="
    echo "설치된 버전 확인: /usr/libexec/java_home -V"
}

install_maven() {
    echo "=== Maven 설치 시작 ==="

    ensure_homebrew

    if ! command -v mvn &>/dev/null; then
        echo "Maven 설치 중..."
        brew install maven
    else
        echo "Maven 이미 설치되어 있습니다. ($(mvn -v 2>/dev/null | sed -n '1p'))"
    fi

    # settings.xml 템플릿 복사 (없는 경우만)
    if [ ! -f "$HOME/.m2/settings.xml" ]; then
        echo "Maven settings.xml 템플릿 복사 중..."
        mkdir -p "$HOME/.m2"
        cp "$DOTFILES_DIR/maven/settings.example.xml" "$HOME/.m2/settings.xml"
        echo "⚠️  ~/.m2/settings.xml 에서 아래 항목을 실제 값으로 수정하세요:"
        echo "    - REPLACE_NEXUS_USERNAME / REPLACE_NEXUS_PASSWORD"
        echo "    - REPLACE_NVD_API_KEY"
    else
        echo "Maven settings.xml 이 이미 존재합니다. 템플릿: $DOTFILES_DIR/maven/settings.example.xml"
    fi

    echo "=== Maven 설치 완료! ==="
}

install_dbeaver() {
    echo "=== DBeaver 설치 시작 ==="

    ensure_homebrew

    if ! brew list --cask dbeaver-community &>/dev/null; then
        echo "DBeaver 설치 중..."
        brew install --cask dbeaver-community
    else
        echo "DBeaver 이미 설치되어 있습니다."
    fi

    # 접속 설정 템플릿 복사 (없는 경우만)
    DBEAVER_CONFIG="$HOME/Library/DBeaverData/workspace6/General/.dbeaver"
    if [ ! -f "$DBEAVER_CONFIG/data-sources.json" ]; then
        echo "DBeaver 접속 설정 템플릿 복사 중..."
        mkdir -p "$DBEAVER_CONFIG"
        cp "$DOTFILES_DIR/dbeaver/data-sources.example.json" "$DBEAVER_CONFIG/data-sources.json"
        echo "⚠️  $DBEAVER_CONFIG/data-sources.json 에서 REPLACE_HOST를 실제 호스트로 수정하세요."
    else
        echo "DBeaver 접속 설정이 이미 존재합니다. 템플릿: $DOTFILES_DIR/dbeaver/data-sources.example.json"
    fi

    echo "=== DBeaver 설치 완료! ==="
}

install_localsend() {
    echo "=== LocalSend 설치 시작 ==="

    ensure_homebrew

    if ! brew list --cask localsend &>/dev/null; then
        echo "LocalSend 설치 중..."
        brew install --cask localsend
    else
        echo "LocalSend 이미 설치되어 있습니다."
    fi

    echo "=== LocalSend 설치 완료! ==="
}

install_tailscale() {
    echo "=== Tailscale 설치 시작 ==="

    ensure_homebrew

    if ! brew list --cask tailscale &>/dev/null; then
        echo "Tailscale 설치 중..."
        brew install --cask tailscale
    else
        echo "Tailscale 이미 설치되어 있습니다."
    fi

    echo "=== Tailscale 설치 완료! ==="
}

install_linearmouse() {
    echo "=== LinearMouse 설치 시작 ==="

    ensure_homebrew

    if ! brew list --cask linearmouse &>/dev/null; then
        echo "LinearMouse 설치 중..."
        brew install --cask linearmouse
    else
        echo "LinearMouse 이미 설치되어 있습니다."
    fi

    if brew list --cask discretescroll &>/dev/null; then
        echo "⚠️  DiscreteScroll이 함께 설치되어 있습니다." >&2
        echo "    충돌 방지: brew uninstall --cask discretescroll" >&2
    fi

    echo "=== LinearMouse 설치 완료! ==="
    echo "시스템 설정 > 개인 정보 보호 및 보안 > 손쉬운 사용에서 LinearMouse 권한을 허용하세요."
}

install_1password() {
    echo "=== 1Password 설치 시작 ==="

    ensure_homebrew

    if ! brew list --cask 1password &>/dev/null; then
        echo "1Password 설치 중..."
        brew install --cask 1password
    else
        echo "1Password 이미 설치되어 있습니다."
    fi

    if ! brew list --cask 1password-cli &>/dev/null; then
        echo "1Password CLI 설치 중..."
        brew install --cask 1password-cli
    else
        echo "1Password CLI 이미 설치되어 있습니다."
    fi

    echo "=== 1Password 설치 완료! ==="
    echo "1Password 앱에서 설정 > 개발자 > CLI와 통합을 활성화하세요."
}

case "$COMPONENT" in
    zsh)
        install_zsh
        ;;
    vim)
        install_vim
        ;;
    tmux)
        install_tmux
        ;;
    karabiner)
        install_karabiner
        ;;
    ghostty)
        install_ghostty
        ;;
    localsend)
        install_localsend
        ;;
    tailscale)
        install_tailscale
        ;;
    claude)
        install_claude
        ;;
    obsidian)
        install_obsidian
        ;;
    vscode)
        install_vscode
        ;;
    intellij)
        install_intellij
        ;;
    java)
        install_java
        ;;
    maven)
        install_maven
        ;;
    dbeaver)
        install_dbeaver
        ;;
    linearmouse)
        install_linearmouse
        ;;
    1password)
        install_1password
        ;;
    all)
        install_zsh
        install_claude
        install_obsidian
        install_vscode
        install_intellij
        install_java
        install_vim
        install_tmux
        install_karabiner
        install_ghostty
        install_localsend
        install_tailscale
        install_maven
        install_dbeaver
        install_linearmouse
        install_1password
        ;;
    *)
        echo "Usage: ./install.sh [zsh|vim|tmux|karabiner|ghostty|localsend|tailscale|claude|obsidian|vscode|intellij|java|maven|dbeaver|linearmouse|1password|all]"
        echo "  zsh             - zsh 설정 (oh-my-zsh, powerlevel9k, fzf, zoxide, bat)"
        echo "  vim             - vim 설정만 설치"
        echo "  tmux            - tmux 설정만 설치"
        echo "  karabiner       - Karabiner-Elements 설정만 설치"
        echo "  ghostty         - Ghostty 설치 및 설정"
        echo "  localsend       - LocalSend 설치"
        echo "  tailscale       - Tailscale 설치"
        echo "  claude          - Claude 앱 및 Claude Code CLI 설치"
        echo "  obsidian        - Obsidian 설치 및 플러그인/설정 적용"
        echo "  vscode          - Visual Studio Code 설치"
        echo "  intellij        - IntelliJ IDEA Ultimate 2025.3.5 설치"
        echo "  java            - Amazon Corretto 17, 21 설치"
        echo "  maven           - Maven 설치 및 settings.xml 템플릿 적용"
        echo "  dbeaver         - DBeaver Community 설치"
        echo "  linearmouse     - LinearMouse 설치"
        echo "  1password       - 1Password 및 1Password CLI 설치"
        echo "  all             - 전체 설치 (기본값)"
        exit 1
        ;;
esac
