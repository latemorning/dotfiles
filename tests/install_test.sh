#!/bin/bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

assert_log_contains() {
    local log_file=$1
    local expected=$2
    grep -Fxq "$expected" "$log_file" ||
        fail "expected '$expected' in $log_file"
}

assert_log_not_contains() {
    local log_file=$1
    local unexpected=$2
    if grep -Fq "$unexpected" "$log_file"; then
        fail "did not expect '$unexpected' in $log_file"
    fi
}

create_mock_commands() {
    local mock_bin=$1

    mkdir -p "$mock_bin"

    cat >"$mock_bin/brew" <<'EOF'
#!/bin/bash
printf '%s\n' "$*" >>"$BREW_LOG"

if [ -n "${BREW_FAIL_ON:-}" ] && [[ "$*" == *"$BREW_FAIL_ON"* ]]; then
    exit 42
fi

if [ "${1:-}" = "shellenv" ]; then
    brew_bin_dir=$(cd "$(dirname "$0")" && pwd)
    printf 'export PATH="%s:$PATH"\n' "$brew_bin_dir"
    exit 0
fi

if [ "${1:-}" = "list" ]; then
    exit 1
fi

exit 0
EOF

    cat >"$mock_bin/git" <<'EOF'
#!/bin/bash
exit 0
EOF

    chmod +x "$mock_bin/brew" "$mock_bin/git"
}

create_mock_installer_commands() {
    local mock_bin=$1

    mkdir -p "$mock_bin"

    cat >"$mock_bin/curl" <<'EOF'
#!/bin/bash
cat <<'INSTALL'
mkdir -p "$HOMEBREW_PREFIX/bin"
cp "$BREW_TEMPLATE" "$HOMEBREW_PREFIX/bin/brew"
chmod +x "$HOMEBREW_PREFIX/bin/brew"
INSTALL
EOF

    cat >"$mock_bin/git" <<'EOF'
#!/bin/bash
exit 0
EOF

    cat >"$mock_bin/uname" <<'EOF'
#!/bin/bash
echo test_arch
EOF

    chmod +x "$mock_bin/curl" "$mock_bin/git" "$mock_bin/uname"
}

create_obsidian_mock_curl() {
    local mock_bin=$1

    cat >"$mock_bin/curl" <<'EOF'
#!/bin/bash
output_file=""
url=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        -o)
            output_file=$2
            shift 2
            ;;
        -*)
            shift
            ;;
        *)
            url=$1
            shift
            ;;
    esac
done

case "$url" in
    *community-plugins.json)
        if [ "${OBSIDIAN_CURL_MODE:-}" = "catalog-failure" ]; then
            exit 22
        fi
        if [ "${OBSIDIAN_CURL_MODE:-}" = "unresolved-plugin" ]; then
            echo '[]'
            exit 0
        fi
        cat <<'JSON'
[
  {"id":"calendar","repo":"test/calendar"},
  {"id":"copilot","repo":"test/copilot"},
  {"id":"dataview","repo":"test/dataview"},
  {"id":"obsidian-kanban","repo":"test/obsidian-kanban"},
  {"id":"obsidian-tasks-plugin","repo":"test/obsidian-tasks-plugin"},
  {"id":"obsidian-vimrc-support","repo":"test/obsidian-vimrc-support"},
  {"id":"table-editor-obsidian","repo":"test/table-editor-obsidian"},
  {"id":"templater-obsidian","repo":"test/templater-obsidian"}
]
JSON
        ;;
    */main.js)
        if [ "${OBSIDIAN_CURL_MODE:-}" = "main-failure" ]; then
            exit 22
        fi
        printf '// plugin\n' >"$output_file"
        ;;
    */styles.css)
        exit 22
        ;;
    *)
        exit 22
        ;;
esac
EOF

    chmod +x "$mock_bin/curl"
}

prepare_home() {
    local test_home=$1

    mkdir -p \
        "$test_home/.oh-my-zsh/custom/themes/powerlevel9k" \
        "$test_home/.tmux/plugins/tpm" \
        "$test_home/.tmux/plugins/tmux" \
        "$test_home/Library/Fonts"
}

run_component() {
    local component=$1
    local test_home=$2
    local mock_bin=$3
    local brew_log=$4

    (
        cd "$TEST_TMP"
        HOME="$test_home" \
            BREW_LOG="$brew_log" \
            MOCK_BIN="$mock_bin" \
            PATH="$mock_bin:/usr/bin:/bin" \
            /bin/bash "$ROOT_DIR/install.sh" "$component"
    )
}

test_fresh_homebrew_is_loaded_in_current_process() {
    local case_dir="$TEST_TMP/homebrew-bootstrap"
    local test_home="$case_dir/home"
    local mock_bin="$case_dir/bin"
    local template_bin="$case_dir/template-bin"
    local brew_template="$case_dir/brew-template"
    local brew_prefix="$case_dir/homebrew"
    local brew_log="$case_dir/brew.log"

    prepare_home "$test_home"
    create_mock_commands "$template_bin"
    mv "$template_bin/brew" "$brew_template"
    create_mock_installer_commands "$mock_bin"
    : >"$brew_log"

    HOMEBREW_PREFIX="$brew_prefix" \
        BREW_TEMPLATE="$brew_template" \
        run_component zsh "$test_home" "$mock_bin" "$brew_log"

    assert_log_contains "$brew_log" "shellenv"
    assert_log_contains "$brew_log" "install fzf"
}

test_zsh_installs_current_tools_and_uses_clone_path() {
    local case_dir="$TEST_TMP/zsh-success"
    local test_home="$case_dir/home"
    local mock_bin="$case_dir/bin"
    local brew_log="$case_dir/brew.log"

    prepare_home "$test_home"
    create_mock_commands "$mock_bin"
    : >"$brew_log"

    run_component zsh "$test_home" "$mock_bin" "$brew_log"

    assert_log_contains "$brew_log" "shellenv"
    assert_log_contains "$brew_log" "install fzf"
    assert_log_contains "$brew_log" "install zoxide"
    assert_log_contains "$brew_log" "install bat"
    assert_log_not_contains "$brew_log" "fasd"
    grep -Fq 'zoxide init zsh' "$ROOT_DIR/zsh/zshrc" ||
        fail "zsh does not initialize zoxide"
    if grep -Fq 'fasd' "$ROOT_DIR/zsh/zshrc"; then
        fail "zsh still enables fasd"
    fi

    [ "$(readlink "$test_home/.zshrc")" = "$ROOT_DIR/zsh/zshrc" ] ||
        fail ".zshrc does not point to the cloned repository"
    [ "$(readlink "$test_home/.zprofile")" = "$ROOT_DIR/zsh/zprofile" ] ||
        fail ".zprofile does not point to the cloned repository"
}

test_install_failure_is_not_masked() {
    local case_dir="$TEST_TMP/zsh-failure"
    local test_home="$case_dir/home"
    local mock_bin="$case_dir/bin"
    local brew_log="$case_dir/brew.log"

    prepare_home "$test_home"
    create_mock_commands "$mock_bin"
    : >"$brew_log"

    if BREW_FAIL_ON=bat run_component zsh "$test_home" "$mock_bin" "$brew_log"; then
        fail "zsh install succeeded after brew failed"
    fi
}

test_shellenv_failure_is_not_masked() {
    local case_dir="$TEST_TMP/shellenv-failure"
    local test_home="$case_dir/home"
    local mock_bin="$case_dir/bin"
    local brew_log="$case_dir/brew.log"

    prepare_home "$test_home"
    create_mock_commands "$mock_bin"
    : >"$brew_log"

    if BREW_FAIL_ON=shellenv run_component zsh "$test_home" "$mock_bin" "$brew_log"; then
        fail "zsh install succeeded after brew shellenv failed"
    fi

    if grep -Fq "install " "$brew_log"; then
        fail "package installation continued after brew shellenv failed"
    fi
}

test_claude_code_uses_homebrew_cask() {
    local case_dir="$TEST_TMP/claude"
    local test_home="$case_dir/home"
    local mock_bin="$case_dir/bin"
    local brew_log="$case_dir/brew.log"

    prepare_home "$test_home"
    create_mock_commands "$mock_bin"
    : >"$brew_log"

    run_component claude "$test_home" "$mock_bin" "$brew_log"

    assert_log_contains "$brew_log" "install --cask claude"
    assert_log_contains "$brew_log" "install --cask claude-code"
}

test_tmux_installs_yazi() {
    local case_dir="$TEST_TMP/tmux"
    local test_home="$case_dir/home"
    local mock_bin="$case_dir/bin"
    local brew_log="$case_dir/brew.log"

    prepare_home "$test_home"
    create_mock_commands "$mock_bin"
    : >"$brew_log"

    run_component tmux "$test_home" "$mock_bin" "$brew_log"

    assert_log_contains "$brew_log" "install tmux"
    assert_log_contains "$brew_log" "install yazi"
}

test_linearmouse_replaces_discretescroll() {
    local case_dir="$TEST_TMP/linearmouse"
    local test_home="$case_dir/home"
    local mock_bin="$case_dir/bin"
    local brew_log="$case_dir/brew.log"

    prepare_home "$test_home"
    create_mock_commands "$mock_bin"
    : >"$brew_log"

    run_component linearmouse "$test_home" "$mock_bin" "$brew_log"

    assert_log_contains "$brew_log" "install --cask linearmouse"
    assert_log_not_contains "$brew_log" "install --cask discretescroll"
}

test_obsidian_rejects_unresolved_required_plugin() {
    local case_dir="$TEST_TMP/obsidian-unresolved"
    local test_home="$case_dir/home"
    local mock_bin="$case_dir/bin"
    local brew_log="$case_dir/brew.log"

    prepare_home "$test_home"
    create_mock_commands "$mock_bin"
    create_obsidian_mock_curl "$mock_bin"
    : >"$brew_log"

    if OBSIDIAN_CURL_MODE=unresolved-plugin \
        run_component obsidian "$test_home" "$mock_bin" "$brew_log"; then
        fail "Obsidian install succeeded with an unresolved required plugin"
    fi

    test_home="$case_dir/catalog-home"
    prepare_home "$test_home"
    if OBSIDIAN_CURL_MODE=catalog-failure \
        run_component obsidian "$test_home" "$mock_bin" "$brew_log"; then
        fail "Obsidian install succeeded after the community catalog failed"
    fi
}

test_obsidian_requires_main_but_allows_missing_styles() {
    local case_dir="$TEST_TMP/obsidian-assets"
    local test_home="$case_dir/home"
    local mock_bin="$case_dir/bin"
    local brew_log="$case_dir/brew.log"

    prepare_home "$test_home"
    create_mock_commands "$mock_bin"
    create_obsidian_mock_curl "$mock_bin"
    : >"$brew_log"

    if OBSIDIAN_CURL_MODE=main-failure \
        run_component obsidian "$test_home" "$mock_bin" "$brew_log"; then
        fail "Obsidian install succeeded without a required main.js"
    fi

    OBSIDIAN_CURL_MODE=success \
        run_component obsidian "$test_home" "$mock_bin" "$brew_log"

    [ -f "$test_home/obsidianVaults/my_vault/.obsidian/plugins/calendar/main.js" ] ||
        fail "Obsidian main.js was not installed"
    [ ! -e "$test_home/obsidianVaults/my_vault/.obsidian/plugins/calendar/styles.css" ] ||
        fail "missing optional styles.css was retained"
}

test_fresh_homebrew_is_loaded_in_current_process
test_zsh_installs_current_tools_and_uses_clone_path
test_install_failure_is_not_masked
test_shellenv_failure_is_not_masked
test_claude_code_uses_homebrew_cask
test_tmux_installs_yazi
test_linearmouse_replaces_discretescroll
test_obsidian_rejects_unresolved_required_plugin
test_obsidian_requires_main_but_allows_missing_styles

echo "install tests: PASS"
