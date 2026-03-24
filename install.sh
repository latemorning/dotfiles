#!/bin/bash

echo "=== vim dotfiles 설치 시작 ==="

# amix/vimrc 설치
if [ ! -d ~/.vim_runtime ]; then
    echo "amix/vimrc 설치 중..."
    git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
    sh ~/.vim_runtime/install_awesome_vimrc.sh
fi

# 심볼릭 링크 생성
echo "심볼릭 링크 생성 중..."
ln -sf ~/dotfiles/vim/my_configs.vim ~/.vim_runtime/my_configs.vim

echo "=== 설치 완료! ==="
