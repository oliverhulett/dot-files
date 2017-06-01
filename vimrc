" vim:foldmethod=marker:foldlevel=0

set nocompatible
syntax enable

" Vundle stuff {{{

" See https://github.com/VundleVim/Vundle.vim
filetype off
try
	set rtp+=~/.vim/bundle/Vundle.vim
	call vundle#begin()
	Plugin 'VundleVim/Vundle.vim'

	Plugin 'ConradIrwin/vim-bracketed-paste'
	Plugin 'altercation/vim-colors-solarized'
	Plugin 'kawaz/batscheck.vim'
	Plugin 'lifepillar/vim-cheat40'
	Plugin 'myint/syntastic-extras'
	Plugin 'ntpeters/vim-better-whitespace'
	Plugin 'reedes/vim-litecorrect'
	Plugin 'vim-scripts/bats.vim'
	Plugin 'vim-scripts/wordlist.vim'
	Plugin 'vim-syntastic/syntastic'

	" All of your Plugins must be added before the following line.
	call vundle#end()
catch
	" Vundle not there...
endtry
" If you've added a plugin, run `:PluginInstall`

" }}}

filetype plugin on
filetype indent on

" Colour scheme {{{

if has('gui_running')
	set background=light
else
	set background=dark
endif
"#colorscheme solarized
"#let g:solarized_termcolors=256
"#let g:solarized_termtrans=1
"#let g:solarized_visibility="low"

" }}}

" Plugin setup {{{

" From ntpeters/vim-better-whitespace: Strip white-space on save.
autocmd BufEnter * silent! EnableStripWhitespaceOnSave

" From reeds/vim-litecorrect: Lightweight auto-cow-wrecks.
autocmd FileType * silent! call litecorrect#init()

" Syntastic settings
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
" Syntastic checkers
let g:syntastic_python_checkers = ['flake8']
" Shellcheck syntastic options
let g:syntastic_sh_shellcheck_args = '-x'

" }}}

" Terminal and local setup {{{

let g:netrw_home=$HOME.'.cache/vim'

" No TTY flow control <CTRL>+S/<CTRL>+Q
execute ':silent ! stty -ixoff'
execute ':silent ! stty -ixon'

" Stop vim locking up on write because of your disc-tweaks.
set nofsync
set swapsync=

" Don't remember highlighting.
set viminfo^=h

" Don't restore cursor position.
:autocmd BufRead * exe "normal! gg"

" Auto-reload vimrc on write.
autocmd bufwritepost .vimrc source $MYVIMRC
autocmd bufwritepost vimrc source $MYVIMRC

" Add word completion, ctrl+P to complete in insert mode.
set complete+=kspell

" Use space as command leader.
let mapleader = " "
let g:mapleader = " "

" }}}

" Shortcuts and re-mappings - saving, quitting, and changing mode {{{

" Shortcut for write and exit.
map <leader>w :w<CR>
map <leader>q :q<CR>
map <leader>n :n<CR>

" Leave insert mode without all that pesky wrist movement...
imap <c-d> <Esc>

" Shortcut to save from anywhere.
nmap <c-s> :w<CR>
" From visual mode, restore selection.
vmap <c-s> <Esc><c-s>gv
" But from insert mode, don't return to insert mode.
imap <c-s> <Esc><c-s>

" Shortcut to quit with <CTRL>+Q
nmap <c-q> :q<CR>

" }}}

" Shortcuts and re-mappings - movement {{{

" Move vertically by "visual" line (respect wrapping.)  N.B. these have to be non-recursive mappings as the contain the mapped key.
nnoremap j gj
nnoremap k gk

" Ctrl+j as the opposite of Shift+j;  Insert a new line without entering insert mode.
nmap <C-J> i<CR><Esc>k$

" Ctrl+o to replicate o without entering insert mode.
nmap <C-O> o<Esc>
nmap <C-I> O<Esc>j

" }}}

" Shortcuts and re-mappings - highlighting {{{

" Shortcut to substitute.  In visual mode yank selection first.
map <c-f> :%s/<c-r>///gc<Left><left><left>
vmap <c-f> y:%s/<c-r>///gc<Left><left><left>

" Clear search highlighting on space+enter.
map <silent> <leader><CR> :nohl<CR>

" Highlight last inserted text.
nmap gV `[v`]

" Sort lines in visual mode.
vmap s :sort<cr>
vnoremap u :sort -u<cr>
vnoremap u :sort -u<cr>

" }}}

" Personalise {{{

set hlsearch
set incsearch
set modelines=1
set noautoindent
set nobackup
set noexpandtab
set noswapfile
set nowb
set number
set pastetoggle=<F2>	" Paste-mode toggle
set ruler
set scrolloff=10
set shiftwidth=4
set showmatch
set smartcase
set smarttab
set spell spelllang=en_gb
set tabstop=4
set textwidth=100
set wildignore=*.o,*.obj,*~	" stuff to ignore when tab completing
set wildmenu	" enable ctrl-n and ctrl-p to scroll through matches
set wildmode=list:longest	" make cmdline tab completion similar to bash
autocmd FileType * setlocal formatoptions+=n
autocmd FileType * setlocal formatoptions+=q
autocmd FileType * setlocal formatoptions-=a
autocmd FileType * setlocal formatoptions-=c
autocmd FileType * setlocal formatoptions-=o
autocmd FileType * setlocal formatoptions-=r
autocmd FileType * setlocal formatoptions-=t

" Show tabs as well
set listchars=tab:»·,trail:·,extends:»,precedes:«
set list

" }}}

" Toggle buffer lists functions {{{

function! GetBufferList()
	redir =>buflist
	silent! ls!
	redir END
	return buflist
endfunction
function! ToggleList(bufname, pfx)
	let buflist = GetBufferList()
	for bufnum in map(filter(split(buflist, '\n'), 'v:val =~ "'.a:bufname.'"'), 'str2nr(matchstr(v:val, "\\d\\+"))')
		if bufwinnr(bufnum) != -1
			exec(a:pfx.'close')
			return
		endif
	endfor
	if a:pfx == 'l' && len(getloclist(0)) == 0
			echohl ErrorMsg
			echo "Location List is Empty."
			return
	endif
	let winnr = winnr()
	exec(a:pfx.'open')
	if winnr() != winnr
		wincmd p
	endif
endfunction

nmap <silent> <leader>k :call ToggleList("Location List", 'l')<cr>
nmap <leader>kk :lprev<cr>
nmap <leader>kj :lnext<cr>

" }}}

" Spelling {{{

" Shortcut keys to turn on spell-checking.
nmap <c-l> :setlocal spell! spelllang=en_gb<cr>
imap <c-l> <c-g>u<Esc>[s
nmap <leader>lk ]s
nmap <leader>sj z=<c-g>u
nmap <leader>a :spellrepall<cr>

hi SpellBad cterm=underline
hi clear SpellBad
hi clear SpellCap
hi clear SpellLocal
hi clear SpellRare
" No spell-check patterns
syn match SingleChar '\<\A*\a{1,2}\A*\>' contains=@NoSpell
" Enable spell check on certain files only.
"autocmd FileType markdown setlocal spell

" }}}

" Statusline {{{

" statusline setup
set statusline =%#identifier#
" tail of the filename
set statusline+=[%f]
set statusline+=%*

" display a warning if fileformat isn't unix
set statusline+=%#warningmsg#
set statusline+=%{&ff!='unix'?'['.&ff.']':''}
set statusline+=%*

" display a warning if file encoding isn't utf-8
set statusline+=%#warningmsg#
set statusline+=%{(&fenc!='utf-8'&&&fenc!='')?'['.&fenc.']':''}
set statusline+=%*

" help file flag
set statusline+=%h
" file format
set statusline+=%5*%{&ff}%*
" file type
set statusline+=%3*%y%*

" read only flag
set statusline+=%#identifier#
set statusline+=%r
set statusline+=%*

" modified flag
set statusline+=%#warningmsg#
set statusline+=%m
set statusline+=%*

" display a warning if &et is wrong, or we have mixed-indenting
set statusline+=%#error#
set statusline+=%{StatuslineTabWarning()}
set statusline+=%*

" display a warning if &paste is set
set statusline+=%#error#
set statusline+=%{&paste?'[paste]':''}
set statusline+=%*

" Syntastic warnings
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

" left/right separator
set statusline+=%=
set statusline+=%{StatuslineCurrentHighlight()}\ \ "current highlight
" cursor column
set statusline+=%c,
" cursor line/total lines
set statusline+=%l/%L
" percent through file
set statusline+=\ %P
set laststatus=2

" return the syntax highlight group under the cursor ''
function! StatuslineCurrentHighlight()
	let name = synIDattr(synID(line('.'),col('.'),1),'name')
	if name == ''
		return ''
	else
		return '[' . name . ']'
	endif
endfunction

" recalculate the trailing whitespace warning when idle, and after saving
autocmd cursorhold,bufwritepost * unlet! b:statusline_tab_warning

" return '[expand-tabs]' if &et is set wrong
" return '[mixed-indenting]' if spaces and tabs are used to indent
" return an empty string if everything is fine
function! StatuslineTabWarning()
	if !exists("b:statusline_tab_warning")
		let b:statusline_tab_warning = ''

		if !&modifiable
			return b:statusline_tab_warning
		endif

		let tabs = search('^\t', 'nw') != 0

		"find spaces that aren't used as alignment in the first indent column
		let spaces = search('^ \{' . &ts . ',}[^\t]', 'nw') != 0
		"let spaces = search('^ ', 'nw') != 0

		if tabs && spaces
			let b:statusline_tab_warning = '[mixed-indenting]'
		elseif (spaces && !&et) || (tabs && &et)
			let b:statusline_tab_warning = '[expand-tabs]'
		else
			let b:statusline_tab_warning = ''
		endif
	endif
	return b:statusline_tab_warning
endfunction

" }}}

" Per filetype indenting {{{

" Python, JSON, and Yaml should use spaces instead of tabs.
autocmd Filetype javascript setlocal expandtab
autocmd Filetype json setlocal expandtab
autocmd Filetype modula2 setlocal expandtab tabstop=2
autocmd Filetype python setlocal expandtab
autocmd Filetype xml setlocal expandtab tabstop=2
autocmd Filetype xsd setlocal expandtab tabstop=2
autocmd Filetype yaml setlocal expandtab tabstop=2

" }}}
