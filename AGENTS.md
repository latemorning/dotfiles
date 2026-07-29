# AGENTS.md

## 프로젝트 개요

이 저장소는 macOS 개발 환경을 재현하기 위한 개인 dotfiles 저장소입니다. 핵심 진입점은 `install.sh`이며, Homebrew 기반 설치, 외부 도구 설치, 설정 파일 심볼릭 링크, 템플릿 복사를 컴포넌트별로 수행합니다.

주요 대상은 zsh, Vim, tmux, Karabiner-Elements, Ghostty, Claude, Obsidian, Visual Studio Code, IntelliJ IDEA Ultimate, Java, Maven, DBeaver, LocalSend, LinearMouse, 1Password입니다.

## 실행 방식

- 전체 설치: `./install.sh` 또는 `./install.sh all`
- 개별 설치: `./install.sh zsh|vim|tmux|karabiner|ghostty|localsend|claude|obsidian|vscode|intellij|java|maven|dbeaver|linearmouse|1password`
- 설치 스크립트는 Homebrew 설치 확인, 패키지 설치, GitHub clone, curl 다운로드, 심볼릭 링크 생성, 템플릿 복사를 수행합니다.
- Homebrew를 처음 설치한 경우 현재 프로세스에 `brew shellenv`를 적용하며, 설치 실패가 발생하면 즉시 중단합니다.
- 설정 파일 경로는 `install.sh`의 실제 위치를 기준으로 계산하므로 저장소 clone 경로에 의존하지 않습니다.
- `all`은 여러 앱과 CLI를 설치하므로, 에이전트가 임의로 실행하기 전에 사용자 확인이 필요합니다.

## 디렉토리 구성

- `install.sh`: 컴포넌트별 설치 함수와 CLI entrypoint.
- `zsh/`: oh-my-zsh, powerlevel9k, fzf, zoxide, Homebrew shellenv, vi mode, alias, 머신별 local 설정 로딩.
- `vim/`: amix/vimrc의 `my_configs.vim`에 연결되는 개인 Vim 설정.
- `tmux/`: TPM, Catppuccin, 복사 모드, 상태 바, pane 이동 단축키 설정.
- `ghostty/`: Ghostty 터미널 설정. D2Coding 폰트, Dracula 테마, Option-as-Alt, true color 설정을 포함.
- `karabiner/`: Karabiner-Elements JSON 설정. Right Command를 F13으로 매핑하고 Escape 입력 시 ABC 입력 소스로 전환.
- `obsidian/`: `my_vault/.obsidian`에 복사될 Obsidian 설정과 커뮤니티 플러그인 manifest/data 파일.
- `maven/`: Nexus 및 NVD API 키를 채워 넣는 `settings.example.xml` 템플릿.
- `dbeaver/`: PostgreSQL 접속 설정용 `data-sources.example.json` 템플릿.

## 주요 설정 요약

### zsh

- `zsh/zshrc`는 oh-my-zsh를 사용하고 테마는 `powerlevel9k/powerlevel9k`입니다.
- 플러그인은 `git`, `fzf`를 활성화하고 디렉토리 이동에는 `zoxide`를 사용합니다.
- Homebrew shellenv와 macOS `path_helper`를 실행합니다.
- vi mode를 켜고 `cat=bat`, `emv`, `emz` alias를 정의합니다.
- 머신별 설정은 `~/.zshrc.local`, `~/.zprofile.local`에서 로딩합니다.
- `zsh/local.zsh.example`에는 Java, Vim runtime, Graphviz, PostgreSQL, libpq, NVM, uv 경로 예시가 있습니다.

### Vim

- line number, search highlight, autoindent, autoread, UTF-8 및 한글 인코딩 fallback을 설정합니다.
- 외부 변경 감지를 위해 `FocusGained`, `BufEnter`, `CursorHold`에서 `checktime`을 실행합니다.
- macOS에서 `~/.local/bin/select-input-source`가 있으면 Insert 모드 Escape 이후 Normal 모드 Escape를 한 번 더 눌렀을 때 ABC 입력 소스로 전환합니다.

### tmux

- 기본 prefix는 `Ctrl+Space`, 보조 prefix는 `Ctrl+b`입니다.
- true color, mouse, vi copy mode, `pbcopy` 연동을 설정합니다.
- TPM 플러그인은 Catppuccin, CPU, battery, resurrect, continuum을 사용합니다.
- `install_tmux`는 `Prefix + Tab`에 필요한 `yazi`도 함께 설치합니다.
- `Prefix + Tab`으로 현재 경로에서 `yazi`를 50% split으로 엽니다.
- `Option+h/j/k/l`로 pane을 이동합니다.

### Obsidian

- vault 대상 경로는 `~/obsidianVaults/my_vault`입니다.
- Vim mode, readable line length off, prompt delete off, link 자동 업데이트를 사용합니다.
- 활성 커뮤니티 플러그인은 Vimrc Support, Copilot, Calendar, Templater, Tasks, Dataview, Kanban, Advanced Tables입니다.
- `install_obsidian`은 Obsidian community plugin 목록을 받아 각 플러그인의 release asset(`main.js`, 선택적으로 `styles.css`)을 다운로드합니다.

### Java, Maven, DB 도구

- Java 설치는 Amazon Corretto 21과 17을 대상으로 합니다.
- Maven은 Homebrew로 설치하고 `~/.m2/settings.xml`이 없을 때 템플릿을 복사합니다.
- Maven 템플릿에는 Nexus credential placeholder와 NVD API key placeholder가 있습니다.
- DBeaver는 Community edition을 설치하고 PostgreSQL 접속 템플릿을 복사합니다.

### Claude와 마우스

- Claude 데스크탑 앱과 Claude Code CLI는 각각 Homebrew cask로 설치합니다.
- 마우스 스크롤 및 포인터 설정 도구는 LinearMouse를 사용합니다.
- npm 기반 Claude Code 또는 DiscreteScroll이 남아 있으면 자동 삭제하지 않고 충돌 방지 명령을 안내합니다.

### IntelliJ IDEA

- IntelliJ IDEA Ultimate는 `2025.3.5` 버전을 고정 설치합니다.
- Apple Silicon은 `ideaIU-2025.3.5-aarch64.dmg`, Intel Mac은 `ideaIU-2025.3.5.dmg`를 사용합니다.
- 설치 경로는 `/Applications/IntelliJ IDEA Ultimate 2025.3.5.app`이며, `~/.local/bin/idea`를 해당 버전에 연결합니다.

## 민감 정보와 로컬 파일

다음 파일은 `.gitignore`에 의해 추적하지 않습니다.

- `.claude/settings.local.json`
- `zsh/local.zsh`
- `dbeaver/data-sources.json`
- `maven/settings.xml`

템플릿 파일의 `REPLACE_*` placeholder는 실제 값으로 채우되, 실제 credential이나 개인 접속 정보는 커밋하지 않아야 합니다.

## 작업 시 주의사항

- 기존 사용자 변경을 되돌리지 마세요. 특히 현재 변경이 있는 파일을 수정할 때는 diff를 먼저 확인하세요.
- 설치 스크립트는 네트워크 접근과 시스템 설정 변경을 수행하므로, 분석이나 문서 작업에서는 실행하지 않는 것이 기본입니다.
- 설정 파일은 대부분 실제 홈 디렉토리로 symlink 또는 copy됩니다. 파일 경로를 바꿀 때는 `install.sh`의 링크 대상도 함께 확인하세요.
- JSON 설정은 `jq`로 검증하고, shell script 변경은 `bash -n install.sh`로 문법 확인하세요.
- 설치 흐름 변경은 `bash tests/install_test.sh`로 mock 기반 회귀 테스트를 실행하세요.
- Obsidian plugin manifest version을 변경하면 `install_obsidian`의 release asset 다운로드 URL도 영향을 받습니다.

## 빠른 검증 명령

- `bash -n install.sh`
- `bash tests/install_test.sh`
- `jq empty karabiner/karabiner.json`
- `jq empty obsidian/my_vault/*.json`
- `find obsidian/my_vault/plugins -name manifest.json -print`
