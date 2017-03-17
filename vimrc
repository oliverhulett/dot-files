set nocompatible
syntax enable

" Vundle stuff, see https://github.com/VundleVim/Vundle.vim
filetype off
try
	set rtp+=~/.vim/bundle/Vundle.vim
	call vundle#begin()
	Plugin 'VundleVim/Vundle.vim'

	Plugin 'ntpeters/vim-better-whitespace'
	Plugin 'ConradIrwin/vim-bracketed-paste'
	Plugin 'reedes/vim-litecorrect'
	Plugin 'vim-scripts/wordlist.vim'

	" All of your Plugins must be added before the following line
	call vundle#end()
catch
	" Vundle not there...
endtry
filetype plugin on
" If you've added a plugin, run `:PluginInstall`

" From ntpeters/vim-better-whitespace: Strip white-space on save
autocmd BufEnter * silent! EnableStripWhitespaceOnSave

" From reeds/vim-litecorrect:  Lightweight auto cow wrecks
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
nmap <c-w> :w<CR>
" From visual mode, restore selection
vmap <c-w> <Esc><c-w>gv
" But from insert mode, don't return to insert mode
imap <c-s> <Esc><c-w>
imap <c-w> <Esc><c-w>

" Shortcut to quit with <CTRL>+Q
nmap <c-q> :q<CR>

" Shortcut to substitute
map <c-f> :%s/<c-r>///gc<Left><left><left>

" Personalise
set number
set ruler
set showmatch
set scrolloff=10
set smartcase
set tabstop=4
set shiftwidth=4
set textwidth=100
set smarttab
set noexpandtab
set incsearch
set hlsearch
set nobackup
set nowb
set noswapfile
set noautoindent
set spell spelllang=en_gb
autocmd FileType * setlocal formatoptions-=t
autocmd FileType * setlocal formatoptions-=o
autocmd FileType * setlocal formatoptions-=c
autocmd FileType * setlocal formatoptions-=a
autocmd FileType * setlocal formatoptions+=q
autocmd FileType * setlocal formatoptions+=n

" Shortcut keys to turn on spell-checking
nnoremap <c-l> :setlocal spell! spelllang=en_gb<cr>
imap <c-l> <c-g>u<Esc>[s
nmap <leader>l ]s
nmap <leader>s z=<c-g>u
nnoremap <leader>a :spellrepall<cr>

" Add word completion, ctrl+P to complete in insert mode
set complete+=kspell

" No spell-check patterns
syn match SingleChar '\<\A*\a\A*\>' contains=@NoSpell

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
autocmd Filetype python setlocal expandtab
autocmd Filetype json setlocal expandtab
autocmd Filetype yaml setlocal expandtab
