syntax enable

set nofsync
set swapsync=

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
nmap <c-w> :w<CR>
" From visual mode, restore selection
vmap <c-s> <Esc><c-s>gv
vmap <c-w> <Esc><c-s>gv
" But from insert mode, don't return to insert mode
imap <c-s> <Esc><c-s>
imap <c-w> <Esc><c-s>

" Shortcut to quit with <CTRL>+Q
nmap <c-q> :q<CR>

" Shortcut to substitute
map <c-f> :%s/<c-r>///gc<Left><left><left>

set number
set ruler
set showmatch
set scrolloff=10
set smartcase
set tabstop=4
set shiftwidth=4
set smarttab
set noexpandtab
set incsearch
set hlsearch
set nobackup
set nowb
set noswapfile

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
