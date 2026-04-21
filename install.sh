#!/bin/bash

COMPONENT=${1:-all}

install_zsh() {
    echo "=== zsh 설정 시작 ==="

    if ! command -v brew &>/dev/null; then
        echo "Homebrew가 없습니다. 설치 중..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

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

    # fasd 설치
    if ! command -v fasd &>/dev/null; then
        echo "fasd 설치 중..."
        brew install fasd
    fi

    # bat 설치 (cat alias 대체)
    if ! command -v bat &>/dev/null; then
        echo "bat 설치 중..."
        brew install bat
    fi

    # 심볼릭 링크 생성
    echo "심볼릭 링크 생성 중..."
    ln -sf ~/dotfiles/zsh/zshrc ~/.zshrc
    ln -sf ~/dotfiles/zsh/zprofile ~/.zprofile

    # 머신별 설정 파일 생성 (없는 경우만)
    if [ ! -f ~/.zshrc.local ]; then
        echo "~/.zshrc.local 템플릿 복사 중..."
        cp ~/dotfiles/zsh/local.zsh.example ~/.zshrc.local
        echo "~/.zshrc.local 을 환경에 맞게 수정하세요."
    fi

    echo "=== zsh 설정 완료! ==="
    echo "터미널을 재시작하거나 'source ~/.zshrc' 를 실행하세요."
}

install_vim() {
    echo "=== vim 설치 시작 ==="

    if [ ! -d ~/.vim_runtime ]; then
        echo "amix/vimrc 설치 중..."
        git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
        sh ~/.vim_runtime/install_awesome_vimrc.sh
    fi

    echo "심볼릭 링크 생성 중..."
    ln -sf ~/dotfiles/vim/my_configs.vim ~/.vim_runtime/my_configs.vim

    echo "=== vim 설치 완료! ==="
}

install_tmux() {
    echo "=== tmux 설치 시작 ==="

    # Homebrew 확인
    if ! command -v brew &>/dev/null; then
        echo "Homebrew가 없습니다. 설치 중..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # tmux 설치
    if ! command -v tmux &>/dev/null; then
        echo "tmux 설치 중..."
        brew install tmux
    fi

    # Nerd Font 설치
    if ! fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd" && \
       ! ls ~/Library/Fonts/ 2>/dev/null | grep -qi "JetBrainsMonoNerdFont"; then
        echo "JetBrains Mono Nerd Font 설치 중..."
        brew install --cask font-jetbrains-mono-nerd-font
    fi

    # TPM 설치
    if [ ! -d ~/.tmux/plugins/tpm ]; then
        echo "TPM(Tmux Plugin Manager) 설치 중..."
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    fi

    # catppuccin 플러그인 설치 및 업데이트
    if [ ! -d ~/.tmux/plugins/tmux ]; then
        echo "catppuccin 테마 설치 중..."
        git clone https://github.com/catppuccin/tmux ~/.tmux/plugins/tmux
    else
        echo "catppuccin 테마 업데이트 중..."
        git -C ~/.tmux/plugins/tmux pull
    fi

    # 심볼릭 링크 생성
    echo "심볼릭 링크 생성 중..."
    ln -sf ~/dotfiles/tmux/tmux.conf ~/.tmux.conf

    echo ""
    echo "=== tmux 설치 완료! ==="
    echo "터미널 폰트를 'JetBrainsMono Nerd Font'로 변경하세요."
    echo "tmux 실행 후 Prefix + I 를 눌러 나머지 플러그인을 설치하세요."
}

install_karabiner() {
    echo "=== Karabiner-Elements 설치 시작 ==="

    if ! command -v brew &>/dev/null; then
        echo "Homebrew가 없습니다. 설치 중..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    if ! brew list --cask karabiner-elements &>/dev/null; then
        echo "Karabiner-Elements 설치 중..."
        brew install --cask karabiner-elements
    else
        echo "Karabiner-Elements 이미 설치되어 있습니다."
    fi

    echo "심볼릭 링크 생성 중..."
    mkdir -p ~/.config/karabiner
    ln -sf ~/dotfiles/karabiner/karabiner.json ~/.config/karabiner/karabiner.json

    echo "=== Karabiner-Elements 설치 완료! ==="
    echo "Karabiner-Elements를 재시작하면 설정이 적용됩니다."
}

install_ghostty() {
    echo "=== Ghostty 설치 시작 ==="

    if ! command -v brew &>/dev/null; then
        echo "Homebrew가 없습니다. 설치 중..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    if ! brew list --cask ghostty &>/dev/null; then
        echo "Ghostty 설치 중..."
        brew install --cask ghostty
    else
        echo "Ghostty 이미 설치되어 있습니다."
    fi

    echo "심볼릭 링크 생성 중..."
    mkdir -p ~/.config/ghostty
    ln -sf ~/dotfiles/ghostty/config ~/.config/ghostty/config

    echo "=== Ghostty 설치 완료! ==="
}

install_claude() {
    echo "=== Claude 설치 시작 ==="

    if ! command -v brew &>/dev/null; then
        echo "Homebrew가 없습니다. 설치 중..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # Claude 데스크탑 앱
    if ! brew list --cask claude &>/dev/null; then
        echo "Claude 데스크탑 앱 설치 중..."
        brew install --cask claude
    else
        echo "Claude 데스크탑 앱 이미 설치되어 있습니다."
    fi

    # Claude Code CLI
    if ! command -v node &>/dev/null; then
        echo "Node.js가 없습니다. NVM을 먼저 설치하거나 ~/.zshrc.local 에서 NVM을 활성화하세요."
        echo "Claude Code CLI 설치를 건너뜁니다."
    elif npm list -g --depth=0 2>/dev/null | grep -q "@anthropic-ai/claude-code"; then
        echo "Claude Code CLI 업데이트 중..."
        npm update -g @anthropic-ai/claude-code
    else
        echo "Claude Code CLI 설치 중..."
        npm install -g @anthropic-ai/claude-code
    fi

    echo "=== Claude 설치 완료! ==="
}

install_obsidian() {
    echo "=== Obsidian 설치 시작 ==="

    if ! command -v brew &>/dev/null; then
        echo "Homebrew가 없습니다. 설치 중..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    if ! brew list --cask obsidian &>/dev/null; then
        echo "Obsidian 설치 중..."
        brew install --cask obsidian
    else
        echo "Obsidian 이미 설치되어 있습니다."
    fi

    # vault 경로 설정
    VAULT_DIR="$HOME/obsidianVaults/my_vault"
    OBSIDIAN_CONFIG="$VAULT_DIR/.obsidian"
    DOTFILES_OBSIDIAN="$HOME/dotfiles/obsidian/my_vault"

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
    COMMUNITY_JSON=$(curl -s "https://raw.githubusercontent.com/obsidianmd/obsidian-releases/master/community-plugins.json")

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
            curl -sL "$base_url/main.js" -o "$target/main.js"
            curl -sL "$base_url/styles.css" -o "$target/styles.css" 2>/dev/null || rm -f "$target/styles.css"
        else
            echo "  [$plugin_id] 커뮤니티 목록에서 repo를 찾을 수 없습니다. 수동 설치 필요."
        fi
    done

    echo "=== Obsidian 설치 완료! ==="
    echo "Obsidian 실행 후 vault 경로를 '$VAULT_DIR' 로 열어주세요."
}

install_vscode() {
    echo "=== Visual Studio Code 설치 시작 ==="

    if ! command -v brew &>/dev/null; then
        echo "Homebrew가 없습니다. 설치 중..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

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
        code --install-extension "$ext" --force 2>/dev/null
    done

    echo "=== Visual Studio Code 설치 완료! ==="
}

install_java() {
    echo "=== Java 설치 시작 ==="

    if ! command -v brew &>/dev/null; then
        echo "Homebrew가 없습니다. 설치 중..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

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

    if ! command -v brew &>/dev/null; then
        echo "Homebrew가 없습니다. 설치 중..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    if ! command -v mvn &>/dev/null; then
        echo "Maven 설치 중..."
        brew install maven
    else
        echo "Maven 이미 설치되어 있습니다. ($(mvn -v 2>/dev/null | head -1))"
    fi

    # settings.xml 템플릿 복사 (없는 경우만)
    if [ ! -f ~/.m2/settings.xml ]; then
        echo "Maven settings.xml 템플릿 복사 중..."
        mkdir -p ~/.m2
        cp ~/dotfiles/maven/settings.example.xml ~/.m2/settings.xml
        echo "⚠️  ~/.m2/settings.xml 에서 아래 항목을 실제 값으로 수정하세요:"
        echo "    - REPLACE_NEXUS_USERNAME / REPLACE_NEXUS_PASSWORD"
        echo "    - REPLACE_NVD_API_KEY"
    else
        echo "Maven settings.xml 이 이미 존재합니다. 템플릿: ~/dotfiles/maven/settings.example.xml"
    fi

    echo "=== Maven 설치 완료! ==="
}

install_dbeaver() {
    echo "=== DBeaver 설치 시작 ==="

    if ! command -v brew &>/dev/null; then
        echo "Homebrew가 없습니다. 설치 중..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

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
        cp ~/dotfiles/dbeaver/data-sources.example.json "$DBEAVER_CONFIG/data-sources.json"
        echo "⚠️  $DBEAVER_CONFIG/data-sources.json 에서 REPLACE_HOST를 실제 호스트로 수정하세요."
    else
        echo "DBeaver 접속 설정이 이미 존재합니다. 템플릿: ~/dotfiles/dbeaver/data-sources.example.json"
    fi

    echo "=== DBeaver 설치 완료! ==="
}

install_localsend() {
    echo "=== LocalSend 설치 시작 ==="

    if ! command -v brew &>/dev/null; then
        echo "Homebrew가 없습니다. 설치 중..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    if ! brew list --cask localsend &>/dev/null; then
        echo "LocalSend 설치 중..."
        brew install --cask localsend
    else
        echo "LocalSend 이미 설치되어 있습니다."
    fi

    echo "=== LocalSend 설치 완료! ==="
}

install_discretescroll() {
    echo "=== DiscreteScroll 설치 시작 ==="

    if ! command -v brew &>/dev/null; then
        echo "Homebrew가 없습니다. 설치 중..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    if ! brew list --cask discretescroll &>/dev/null; then
        echo "DiscreteScroll 설치 중..."
        brew install --cask discretescroll
    else
        echo "DiscreteScroll 이미 설치되어 있습니다."
    fi

    echo "=== DiscreteScroll 설치 완료! ==="
    echo "시스템 환경설정 > 개인 정보 보호 및 보안 > 손쉬운 사용에서 DiscreteScroll 권한을 허용하세요."
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
    claude)
        install_claude
        ;;
    obsidian)
        install_obsidian
        ;;
    vscode)
        install_vscode
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
    discretescroll)
        install_discretescroll
        ;;
    all)
        install_zsh
        install_claude
        install_obsidian
        install_vscode
        install_java
        install_vim
        install_tmux
        install_karabiner
        install_ghostty
        install_localsend
        install_maven
        install_dbeaver
        install_discretescroll
        ;;
    *)
        echo "Usage: ./install.sh [zsh|vim|tmux|karabiner|ghostty|localsend|claude|obsidian|vscode|java|maven|dbeaver|discretescroll|all]"
        echo "  zsh             - zsh 설정 (oh-my-zsh, powerlevel9k, bat, fasd)"
        echo "  vim             - vim 설정만 설치"
        echo "  tmux            - tmux 설정만 설치"
        echo "  karabiner       - Karabiner-Elements 설정만 설치"
        echo "  ghostty         - Ghostty 설치 및 설정"
        echo "  localsend       - LocalSend 설치"
        echo "  claude          - Claude Code CLI 설치/업데이트"
        echo "  obsidian        - Obsidian 설치 및 플러그인/설정 적용"
        echo "  vscode          - Visual Studio Code 설치"
        echo "  java            - Amazon Corretto 17, 21 설치"
        echo "  maven           - Maven 설치 및 settings.xml 템플릿 적용"
        echo "  dbeaver         - DBeaver Community 설치"
        echo "  discretescroll  - DiscreteScroll 설치"
        echo "  all             - 전체 설치 (기본값)"
        exit 1
        ;;
esac
