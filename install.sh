#!/bin/bash

COMPONENT=${1:-all}

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

    # catppuccin 플러그인 설치
    if [ ! -d ~/.tmux/plugins/tmux ]; then
        echo "catppuccin 테마 설치 중..."
        git clone https://github.com/catppuccin/tmux ~/.tmux/plugins/tmux
    fi

    # 심볼릭 링크 생성
    echo "심볼릭 링크 생성 중..."
    ln -sf ~/dotfiles/tmux/tmux.conf ~/.tmux.conf

    echo ""
    echo "=== tmux 설치 완료! ==="
    echo "터미널 폰트를 'JetBrainsMono Nerd Font'로 변경하세요."
    echo "tmux 실행 후 Prefix + I 를 눌러 나머지 플러그인을 설치하세요."
}

case "$COMPONENT" in
    vim)
        install_vim
        ;;
    tmux)
        install_tmux
        ;;
    all)
        install_vim
        install_tmux
        ;;
    *)
        echo "Usage: ./install.sh [vim|tmux|all]"
        echo "  vim   - vim 설정만 설치"
        echo "  tmux  - tmux 설정만 설치"
        echo "  all   - 전체 설치 (기본값)"
        exit 1
        ;;
esac
