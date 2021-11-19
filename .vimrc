set nocompatible

let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Plugins
call plug#begin('~/.vim/plugged')

Plug 'mhinz/vim-startify'
Plug 'misterbuckley/vim-definitive'
Plug 'vim-airline/vim-airline'
Plug 'scrooloose/syntastic'
Plug 'alexandregv/norminette-vim'
Plug 'scrooloose/nerdtree'
Plug 'sheerun/vim-polyglot'
Plug 'ryanoasis/vim-devicons'
Plug 'pbondoer/vim-42header'
"Plug 'ctrlpvim/ctrlp.vim'

" Theme plugins
Plug 'jacoborus/tender.vim'
Plug 'sjl/badwolf'
Plug 'tomasr/molokai'
Plug 'mangeshrex/uwu.vim'
Plug 'joshdick/onedark.vim'
Plug 'pacokwon/onedarkhc.vim'
Plug 'ghifarit53/tokyonight-vim'
Plug 'morhetz/gruvbox'
Plug 'dracula/vim'
Plug 'flazz/vim-colorschemes'
Plug 'vim-airline/vim-airline-themes'

call plug#end()

" Basic settings
syntax on
set noerrorbells
set nowrap
set mouse=a
set number
set relativenumber
set ignorecase
set smartcase
set wildignorecase
set noswapfile
set nobackup
set undodir=~/.vim/undodir
set undofile
set incsearch
set scrolloff=8
set cursorline
" More powerful backspacing
set backspace=indent,eol,start
set listchars=eol:¬,tab:>·,trail:~,extends:>,precedes:<,space:␣
set hidden

" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300

"Tab Settings
"set expandtab
set shiftwidth=4
set softtabstop=4
set tabstop=4
set smartindent

" onedark
"colorscheme onedark
"let g:airline_theme = 'onedark'

" onedarkpaco
colorscheme onedarkhc
let g:airline_theme = 'onedark'

" uwu
"colorscheme uwu
"let g:airline_theme = 'onedark'

" molokai
"colorscheme molokai
"let g:airline_theme = 'molokai'

" ayu
"colorscheme ayu
"let g:airline_theme = 'ayu_dark'

" Gruvbox
"colorscheme gruvbox
"let g:airline_theme = 'gruvbox'

" Dracula theme
"colorscheme dracula
"let g:airline_theme = 'dracula'

" Tokyonight theme
"colorscheme tokyonight
"let g:tokyonight_style = 'night'
"let g:tokyonight_enable_italic = 1
"let g:airline_theme = 'tokyonight'

"Color Scheme
set background=dark
highlight Normal guibg=NONE
"set colorcolumn=80
set t_Co=256

" Make vertical separator pretty
highlight VertSplit cterm=NONE
set fillchars+=vert:\▏

"Vim-airline
let g:airline_powerline_fonts = 1
let g:airline#extensions#wordcount#enabled = 1

if exists('+termguicolors')
	let &t_8f="\<Esc>[38;2;%lu;%lu;%lum"
	let &t_8b="\<Esc>[48;2;%lu;%lu;%lum"
	set termguicolors
endif

"Remaps
let mapleader = ','
noremap <C-h> <C-w>h
noremap <C-j> <C-w>j
noremap <C-k> <C-w>k
noremap <C-l> <C-w>l
" Source file
nnoremap <leader>s :so %<CR>
" Show nerdtree
nnoremap <leader>d :NERDTreeToggle<CR>
" Show whitespace
nnoremap <leader>w :set list<CR>
" Change spaces to tabs
nnoremap <leader>t :set noet<CR>:%retab!<CR>
" Fix paste
set pastetoggle=<leader>p
highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$\|\s+\s{1}/
highlight MoreThan80 ctermbg=blue guibg=blue
:2match MoreThan80 /\%81v.\+/

" Syntastic + Norminette
" Enable norminette-vim (and gcc)
" let g:syntastic_c_checkers = ['norminette', 'gcc']
let g:syntastic_c_checkers = ['gcc']
let g:syntastic_aggregate_errors = 1

" Support headers (.h)
let g:c_syntax_for_h = 1
let g:syntastic_c_include_dirs = ['include', '../include', '../../include', 'libft', '../libft/include', '../../libft/include']

" Pass custom arguments to norminette (this one ignores 42header)
let g:syntastic_c_norminette_args = '-R CheckTopCommentHeader'

" Check errors when opening a file (disable to speed up startup time)
let g:syntastic_check_on_open = 1

" Enable error list
let g:syntastic_always_populate_loc_list = 1

" Automatically open error list
let g:syntastic_auto_loc_list = 1

" Skip check when closing
let g:syntastic_check_on_wq = 0

" Autocommands
fun! TrimWhitespace()
	let l:save = winsaveview()
	keeppatterns %s/\s\+$//e
	call winrestview(l:save)
endfun

augroup DELETE_WHITESPACE
	autocmd!
	autocmd BufWritePre * : call TrimWhitespace()
augroup END
