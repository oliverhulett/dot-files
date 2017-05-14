set nocompatible
syntax enable

" Vundle stuff, see https://github.com/VundleVim/Vundle.vim
filetype off
try
	set rtp+=~/.vim/bundle/Vundle.vim
	call vundle#begin()
	Plugin 'VundleVim/Vundle.vim'

	Plugin 'ConradIrwin/vim-bracketed-paste'
	Plugin 'kawaz/batscheck.vim'
	Plugin 'myint/syntastic-extras'
	Plugin 'ntpeters/vim-better-whitespace'
	Plugin 'reedes/vim-litecorrect'
	Plugin 'vim-scripts/bats.vim'
	Plugin 'vim-scripts/wordlist.vim'
	Plugin 'vim-syntastic/syntastic'

	" All of your Plugins must be added before the following line
	call vundle#end()
catch
	" Vundle not there...
endtry
filetype plugin on
filetype indent on
" If you've added a plugin, run `:PluginInstall`

" From ntpeters/vim-better-whitespace: Strip white-space on save
autocmd BufEnter * silent! EnableStripWhitespaceOnSave

" From reeds/vim-litecorrect: Lightweight auto-cow-wrecks
autocmd FileType * silent! call litecorrect#init()

" Show tabs as well
set listchars=tab:»·,trail:·,extends:»,precedes:«
set list

" Stop vim locking up on write because of your disc-tweaks
set nofsync
set swapsync=

let g:netrw_home=$HOME.'.cache/vim'

" Use space as command leader.
let mapleader = " "
let g:mapleader = " "

" Shortcut for write and exit
map <leader>w :w<CR>
map <leader>q :q<CR>
map <leader>n :n<CR>

" Leave insert mode without all that pesky wrist movement...
imap <c-d> <Esc>

" No TTY flow control <CTRL>+S/<CTRL>+Q
execute ':silent ! stty -ixoff'
execute ':silent ! stty -ixon'

" Shortcut to save from anywhere
nmap <c-s> :w<CR>
" From visual mode, restore selection
vmap <c-s> <Esc><c-s>gv
" But from insert mode, don't return to insert mode
imap <c-s> <Esc><c-s>

" Shortcut to quit with <CTRL>+Q
nmap <c-q> :q<CR>

" Shortcut to substitute
map <c-f> :%s/<c-r>///gc<Left><left><left>

" Personalise
set hlsearch
set incsearch
set noautoindent
set nobackup
set noexpandtab
set noswapfile
set nowb
set number
set ruler
set scrolloff=10
set shiftwidth=4
set showmatch
set smartcase
set smarttab
set spell spelllang=en_gb
set tabstop=4
set textwidth=100
autocmd FileType * setlocal formatoptions+=n
autocmd FileType * setlocal formatoptions+=q
autocmd FileType * setlocal formatoptions-=a
autocmd FileType * setlocal formatoptions-=c
autocmd FileType * setlocal formatoptions-=o
autocmd FileType * setlocal formatoptions-=r
autocmd FileType * setlocal formatoptions-=t

" Syntastic settings
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
" Syntastic checkers
let g:syntastic_python_checkers = ['flake8']

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

" Syntastic settings
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

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

" Shortcut keys to turn on spell-checking
nnoremap <c-l> :setlocal spell! spelllang=en_gb<cr>
imap <c-l> <c-g>u<Esc>[s
nmap <leader>l ]s
nmap <leader>s z=<c-g>u
nnoremap <leader>a :spellrepall<cr>

" Add word completion, ctrl+P to complete in insert mode
set complete+=kspell

hi SpellBad cterm=underline
hi clear SpellBad
hi clear SpellCap
hi clear SpellLocal
hi clear SpellRare
" No spell-check patterns
syn match SingleChar '\<\A*\a{1,2}\A*\>' contains=@NoSpell
" Enable spell check on certain files only.
"autocmd FileType markdown setlocal spell

"make cmdline tab completion similar to bash
set wildmode=list:longest
"enable ctrl-n and ctrl-p to scroll through matches
set wildmenu
"stuff to ignore when tab completing
set wildignore=*.o,*.obj,*~

"statusline setup
set statusline =%#identifier#
"tail of the filename
set statusline+=[%f]
set statusline+=%*

"display a warning if fileformat isn't unix
set statusline+=%#warningmsg#
set statusline+=%{&ff!='unix'?'['.&ff.']':''}
set statusline+=%*

"display a warning if file encoding isn't utf-8
set statusline+=%#warningmsg#
set statusline+=%{(&fenc!='utf-8'&&&fenc!='')?'['.&fenc.']':''}
set statusline+=%*

"help file flag
set statusline+=%h
"file format
set statusline+=%5*%{&ff}%*
"file type
set statusline+=%3*%y%*

"read only flag
set statusline+=%#identifier#
set statusline+=%r
set statusline+=%*

"modified flag
set statusline+=%#warningmsg#
set statusline+=%m
set statusline+=%*

"display a warning if &et is wrong, or we have mixed-indenting
set statusline+=%#error#
set statusline+=%{StatuslineTabWarning()}
set statusline+=%*

"display a warning if &paste is set
set statusline+=%#error#
set statusline+=%{&paste?'[paste]':''}
set statusline+=%*

"Syntastic warnings
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

"Syntastic warnings
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

"left/right separator
set statusline+=%=
set statusline+=%{StatuslineCurrentHighlight()}\ \ "current highlight
"cursor column
set statusline+=%c,
"cursor line/total lines
set statusline+=%l/%L
"percent through file
set statusline+=\ %P
set laststatus=2

"return the syntax highlight group under the cursor ''
function! StatuslineCurrentHighlight()
	let name = synIDattr(synID(line('.'),col('.'),1),'name')
	if name == ''
		return ''
	else
		return '[' . name . ']'
	endif
endfunction

"return '[&et]' if &et is set wrong
"return '[mixed-indenting]' if spaces and tabs are used to indent
"return an empty string if everything is fine
function! StatuslineTabWarning()
	if !exists("b:statusline_tab_warning")
		let b:statusline_tab_warning = ''

		if !&modifiable
			return b:statusline_tab_warning
		endif

		let tabs = search('^\t', 'nw') != 0

		"find spaces that aren't used as alignment in the first indent column
		let spaces = search('^ \{' . &ts . ',}[^\t]', 'nw') != 0

		if tabs && spaces
			let b:statusline_tab_warning = '[mixed-indenting]'
		elseif (spaces && !&et) || (tabs && &et)
			let b:statusline_tab_warning = '[&et]'
		endif
	endif
	return b:statusline_tab_warning
endfunction

" Don't remember highlighting.
set viminfo^=h

" Don't restore cursor position.
:autocmd BufRead * exe "normal! gg"

" Shortcut keys to search for visual selection
" vnoremap <silent> * :call VisualSelection('f')<CR>
" vnoremap <silent> # :call VisualSelection('b')<CR>
" Clear search highlighting on space+enter
map <silent> <leader><CR> :nohl<CR>

" Map ALT+[jk] to move line of text.
nmap <M-j> mz:m+<CR>`z
nmap <M-k> mz:m-2<CR>`z
vmap <M-j> :m'>+<CR>`<my`>mzgv`yo`z
vmap <M-k> :m'<-2<CR>`>my`<mzgv`yo`z

" Shift+Enter to insert a new line without entering insert mode
nmap <S-Enter> O<Esc>
" Ctrl+j as the opposite of Shift+j
nnoremap <C-J> a<CR><Esc>k$

" Python, JSON, and Yaml should use spaces instead of tabs
autocmd Filetype javascript setlocal expandtab
autocmd Filetype json setlocal expandtab
autocmd Filetype modula2 setlocal expandtab tabstop=2
autocmd Filetype python setlocal expandtab
autocmd Filetype xml setlocal expandtab tabstop=2
autocmd Filetype yaml setlocal expandtab tabstop=2

