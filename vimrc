set nocompatible
syntax enable
set encoding=utf-8

" Vundle stuff {{{

" See https://github.com/VundleVim/Vundle.vim
filetype off
try
	set rtp+=~/.vim/bundle/Vundle.vim
	call vundle#begin()
	Plugin 'VundleVim/Vundle.vim'

	Plugin 'ConradIrwin/vim-bracketed-paste'	" Set pastemode on paste
	Plugin 'RRethy/vim-illuminate'				" Highlight the word under the cursor
	Plugin 'Valloric/YouCompleteMe'				" Tab-completion
	Plugin 'Xuyuanp/nerdtree-git-plugin'		" Git status for nerdtree
	Plugin 'scrooloose/nerdtree'				" Nerdtree - file browser in the sidebar

	Plugin 'altercation/vim-colors-solarized'
	Plugin 'ap/vim-buftabline'
	Plugin 'chaoren/vim-wordmotion'
	Plugin 'djoshea/vim-autoread'
	Plugin 'godlygeek/tabular'
	Plugin 'inside/vim-search-pulse'
	Plugin 'integralist/vim-mypy'
	Plugin 'kawaz/batscheck.vim'
	Plugin 'leafgarland/typescript-vim'
	Plugin 'lifepillar/vim-cheat40'
	Plugin 'lilydjwg/colorizer'
	Plugin 'liuchengxu/vim-which-key'
	Plugin 'myint/syntastic-extras'
	"Plugin 'ntpeters/vim-better-whitespace'
	Plugin 'plasticboy/vim-markdown'
	Plugin 'reedes/vim-litecorrect'
	Plugin 'terryma/vim-smooth-scroll'
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
let g:syntastic_java_checkers = []
" Shellcheck syntastic options
let g:syntastic_sh_shellcheck_args = '-x'

" YouCompleteMe
let g:ycm_always_populate_location_list = 1

" By default timeoutlen is 1000 ms
set timeoutlen=500

nmap <silent> <leader>t :NERDTreeToggle<CR>
let g:NERDTreeNodeDelimiter = "\u00a0"
" Start NerdTree when vim starts
" autocmd vimenter * NERDTree

" How can I open a NERDTree automatically when vim starts up if no files were specified?
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
" How can I open NERDTree automatically when vim starts up on opening a directory?
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | endif

" Smooth scroll
noremap <silent> <c-u> :call smooth_scroll#up(&scroll, 0, 2)<CR>
noremap <silent> <c-d> :call smooth_scroll#down(&scroll, 0, 2)<CR>
noremap <silent> <c-b> :call smooth_scroll#up(&scroll*2, 0, 4)<CR>
noremap <silent> <c-f> :call smooth_scroll#down(&scroll*2, 0, 4)<CR>

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

" Split window below and right by default.
set splitbelow
set splitright

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

" Use semi-colon instead of colon for entering comands.
nnoremap ; :

" }}}

" Shortcuts and re-mappings - saving, quitting, and changing mode {{{

" Shortcut for write and exit.
noremap <leader>w :w<CR>
noremap <leader>q :q<CR>
noremap <leader>n :n<CR>

" Leave insert mode without all that pesky wrist movement...
inoremap <C-d> <ESC>

" Shortcut to save from anywhere.
nnoremap <C-s> :w<CR>
" From visual mode, restore selection.
vnoremap <C-s> <ESC>:w<CR>gv
" But from insert mode, don't return to insert mode.
inoremap <C-s> <ESC>:w<CR>

" Shortcut to quit with <CTRL>+Q
nnoremap <C-q> :q<CR>

" }}}

" Shortcuts and re-mappings - movement {{{

" Move vertically by "visual" line (respect wrapping.)  N.B. these have to be non-recursive mappings as the contain the mapped key.
nnoremap j gj
nnoremap k gk

" Shift+k as the opposite of Shift+j;  Insert a new line without entering insert mode.
nnoremap J mzJ`z
nnoremap K mzi<CR><ESC>`z$

" Ctrl+o to replicate o without entering insert mode.
nnoremap <C-O> mzo<ESC>`zj
nnoremap <C-I> mzO<ESC>`zk

" Split navigation; Ctrl+{j,k,l,h} to move between splits.
nnoremap <C-j> <C-W><C-J>
nnoremap <C-k> <C-W><C-K>
nnoremap <C-l> <C-W><C-L>
nnoremap <C-h> <C-W><C-H>

" Vertical split with scroll lock so I can have two pages side by side.
" Good for interviews where I can have notes on the right (2nd page) and capabilities and prompts on the left (1st page)
noremap <silent> <Leader>vs :<C-u>let @z=&so<CR>:set so=0 noscb<CR>:bo vs<CR>Ljzt:setl scb<CR><C-w>p:setl scb<CR>:let &so=@z<CR>:setl scrolloff=0<CR><C-W><C-L>G
noremap <silent> <Leader>sv <C-w>o:setl scrolloff<<CR>

" }}}

" Shortcuts and re-mappings - highlighting {{{

" Shortcut to substitute.  In visual mode yank selection first.
noremap <C-f> :%s/<C-r>///gc<left><left><left>
vnoremap <C-f> y:%s/<C-r>///gc<left><left><left>

" Clear search highlighting on space+enter.
noremap <silent> <leader><CR> :nohl<CR>

" Highlight last inserted text.
nnoremap gV `[v`]

" Sort lines in visual mode.
vnoremap si :sort i<CR>
vnoremap ss :sort<CR>
vnoremap su :sort u<CR>

" Use Q for formatting the current paragraph (or selection)
vnoremap Q gq
nnoremap Q gqap

if exists(":Tabularize")
	nmap <Leader>a= :Tabularize /=<CR>
	vmap <Leader>a= :Tabularize /=<CR>
endif


" }}}

" Shortcuts and re-mappings - functions {{{

" Append modeline after last line in buffer.
" Use substitute() instead of printf() to handle '%%s' modeline in LaTeX
" files.
function! AppendModeline()
	let l:modeline = printf(" vim: set ts=%d sw=%d tw=%d %set :",
		\ &tabstop, &shiftwidth, &textwidth, &expandtab ? '' : 'no')
	let l:modeline = substitute(&commentstring, "%s", l:modeline, "")
	call append(line("$"), l:modeline)
endfunction
nnoremap <silent> <Leader>ml :call AppendModeline()<CR>

" }}}

" Personalise {{{

set copyindent
set foldlevel=99
set formatoptions+=n
set formatoptions+=q
set formatoptions-=a
set formatoptions-=c
set formatoptions-=o
set formatoptions-=r
set formatoptions-=t
set hlsearch
set incsearch
set modelines=10
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
set showmode
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

nnoremap <silent> <leader>k :call ToggleList("Location List", 'l')<CR>
nnoremap <leader>kk :lprev<CR>
nnoremap <leader>kj :lnext<CR>

" }}}

" Spelling {{{

" Shortcut keys to turn on spell-checking.
nnoremap <C-a> :setlocal spell! spelllang=en_gb<CR>
inoremap <C-a> <C-g>u<ESC>[s
nnoremap <leader>lk ]s
nnoremap <leader>sj z=<C-g>u
nnoremap <leader>a :spellrepall<CR>

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
set statusline+=%{exists('g:loaded_syntastic')?SyntasticStatuslineFlag():''}
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
autocmd Filetype dosini setlocal noautoindent
autocmd Filetype gitconfig setlocal noautoindent
autocmd Filetype groovy setlocal expandtab
autocmd Filetype java setlocal expandtab
autocmd Filetype javascript setlocal expandtab
autocmd Filetype json setlocal expandtab
autocmd Filetype markdown setlocal expandtab
autocmd Filetype modula2 setlocal expandtab
autocmd Filetype python setlocal expandtab
autocmd Filetype xml setlocal expandtab tabstop=2
autocmd Filetype xsd setlocal expandtab tabstop=2
autocmd Filetype yaml setlocal expandtab tabstop=2

" }}}
