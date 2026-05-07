set hlsearch
set nu
set autoindent
set scrolloff=2
set wildmode=longest,list
set ts=4
set sts=4
set sw=1
set autowrite
" 외부에서 파일이 변경되면 자동으로 읽어오기
set autoread
set cindent
set bs=eol,start,indent
set history=256
set laststatus=2
set paste
set shiftwidth=4
set showmatch
set smartcase
set smarttab
set smartindent
set softtabstop=4
set tabstop=4
set ruler
set incsearch
set statusline=\ %<%l:%v\ [%P]%=%a\ %h%m%r\ %F\
set encoding=utf-8
set fileencodings=utf-8,cp949,euc-kr,latin1
set ambiwidth=double

" cursor shape
" Options (replace the number after '\e[')
"    Ps = 0  -> blinking block.
"    Ps = 1  -> blinking block (default).
"    Ps = 2  -> steady block.
"    Ps = 3  -> blinking underline.
"    Ps = 4  -> steady underline.
"    Ps = 5  -> blinking bar (xterm).
"    Ps = 6  -> steady bar (xterm).
let &t_SI = "\e[5 q" " insert mode
let &t_EI = "\e[1 q" " normal mode


" 1. Vim으로 다시 포커스가 돌아올 때 체크
au FocusGained,BufEnter * checktime

" 2. (강력 추천) 아무 키도 안 누르고 가만히 있을 때(CursorHold) 정기적으로 체크
" 기본값이 4초(4000ms)이므로 1초 정도로 줄이면 더 빠릿합니다.
set updatetime=3000
au CursorHold,CursorHoldI * checktime

" 3. 파일이 자동으로 로드될 때 알림 메시지 출력 (선택 사항)
au FileChangedShellPost * echohl WarningMsg | echo "파일이 외부에서 변경되어 새로고침되었습니다!(" . strftime("%H:%M:%S") . ")" | echohl None

" insert mode에서 ESC를 누른 직후 ESC를 한 번 더 누르면 macOS 입력 소스를 ABC로 전환
if has('macunix') && executable('/Users/KTH/.local/bin/select-input-source')
  let g:select_english_after_insert_escape_window = 0.7

  function! s:RememberInsertEscapeForInputSource() abort
    let g:select_english_after_insert_escape_at = reltime()
    return "\<Esc>"
  endfunction

  function! s:SelectEnglishInputSource() abort
    let l:uid = matchstr(system('id -u'), '\d\+')
    if empty(l:uid)
      call system('/Users/KTH/.local/bin/select-input-source com.apple.keylayout.ABC >/dev/null 2>&1')
    else
      call system('launchctl asuser ' . l:uid . ' /Users/KTH/.local/bin/select-input-source com.apple.keylayout.ABC >/dev/null 2>&1')
    endif
  endfunction

  function! s:SelectEnglishOnSecondEscape() abort
    if exists('g:select_english_after_insert_escape_at')
      if reltimefloat(reltime(g:select_english_after_insert_escape_at)) <= g:select_english_after_insert_escape_window
        silent! call <SID>SelectEnglishInputSource()
      endif
      unlet g:select_english_after_insert_escape_at
    endif
  endfunction

  inoremap <expr> <Esc> <SID>RememberInsertEscapeForInputSource()
  nnoremap <silent> <Esc> :<C-u>call <SID>SelectEnglishOnSecondEscape()<CR>
endif
