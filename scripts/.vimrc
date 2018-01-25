
syntax on
set nocompatible
set ai
set showmatch
set incsearch
set hlsearch
set nobackup
set nowritebackup
set laststatus=2 " Always show the status line, even if there's only one buffer
set ruler
set scrolloff=3
" set nowrap
set listchars+=precedes:<,extends:>

set ignorecase
set smartcase
set diffopt=filler "iwhite
set backspace=eol,indent,start

" Find tags whatever subdirectory they are in
set tags=./tags,tags,../tags,../../tags,../../../tags,../../../../tags

" Find files referred to in build logs
set path=.,/usr/include,,../bin/aot.dev,../bin/codegen.dev,../bin/codert.dev,../bin/jit.dev,../bin/jitdebug.dev,../bin/jitrt.dev

" Custom syntax colours
hi Comment	ctermfg=Green
hi Constant	ctermfg=Magenta
hi Special	ctermfg=Red
hi Identifier	ctermfg=DarkCyan
hi Statement	ctermfg=White
hi PreProc	ctermfg=Yellow
hi Type		ctermfg=Red
hi Ignore	ctermfg=Gray

hi WarningMsg   ctermfg=White    ctermbg=DarkMagenta
hi ErrorMsg     ctermfg=Yellow   ctermbg=DarkRed

" Seems to be impossible to make search highlighting use a dark foreground colour everywhere
set hl=i:Search " Use same highlighting for incsearch and last search
hi Search ctermfg=white ctermbg=yellow

" Special Testarossa types
autocmd BufNewFile,BufReadPost *.c,*.h,*.cpp,*.hpp syntax keyword cType intptrj_t uintptrj_t ncount_t
autocmd BufNewFile,BufReadPost *.c,*.h,*.cpp,*.hpp syntax keyword cError intptr_t uintptr_t
"autocmd BufNewFile,BufReadPost *.c,*.h,*.cpp,*.hpp syntax match   cError "\t"
autocmd BufNewFile,BufReadPost *.c,*.h,*.cpp,*.hpp syntax match   cType "\<TR_[A-Z0-9]\+[a-z]\+[A-Za-z0-9]*\>"
autocmd BufNewFile,BufReadPost *.limit source $HOME/.vim-files/limitfile.vim
autocmd BufNewFile,BufReadPost *.trace source $HOME/.vim-files/tracefile.vim
autocmd BufNewFile,BufReadPost *.limit set noexpandtab tabstop=8 shiftwidth=8

set errorformat=%f(%l)\ :\ error\ %t%n:\ %m,%f(%l)\ :\ fatal\ error\ %t%n:\ %m

hi Folded ctermbg=darkgrey ctermfg=lightred

" Mark the 90th column
hi TooWide ctermbg=blue
match TooWide /\%91v/
"set textwidth=90

" Standard Testarossa indenting rules
augroup cprog
   au BufNewFile,BufReadPost *.cpp,*.hpp set formatoptions=crql cinoptions=>3,f3,{1s,h0 nocompatible tabstop=3 shiftwidth=3 expandtab ai
augroup END

hi Folded guibg=darkgrey guifg=blue
hi FoldColumn guibg=darkgrey guifg=white

" This doesn't seem to work
syn region debugFold start="#if defined(DEBUG)" end="#endif" fold

"""""""""""""""""""""""""
" Handy comma-macros
"

" Open file at cursor in a new window
map ,f <C-W>sgf

" Fold matching brace (eg. a whole function) and then find next open-brace
" Good for quickly folding up many selected functions in a file
map ,z zf%/{<C-M>zt

" Go to next open-brace and center in window
" Combined with % command (find matching brace), good for quickly browsing
" blocks of C code
map ,[ /{<C-M>%zt

" Check out the current file from CMVC and re-open it to clear read-only mode
map ,c :!File -checkout % -defect ${DEFECT}<C-M>filter d2u %<C-M>:e<C-M>
map ,x :!cmvc-fork %<C-M>:e<C-M>

" Change README.ksh export statements so syntax highlighting works
map ,e /export ["]<C-M>wxe p

" Scroll trace file so disassembly fills the window
map ,d 68zl

" Search for next reference to register name
map ,r hevb ybh/\<[er]\?<C-R>"[bwd]\?\><C-M>

" Extract -Xjit option from a command line
map ,j /-X\?jit<C-M>yWcW$JIT<esc>OJIT="<C-R>""<esc>

" Smart tag lookup
map <C-]> g<C-]>

" Highlight spills
map ,S ms/SPILL<C-M>`s

" Bookmarks
map ,b :split ~/.vim-bookmarks<C-M>z10<C-M>
map ,g ^Wy$^gf:<C-R>"<C-M><C-W>=
map ,B :let @" = expand("%:p") . " " . line(".")<C-M>,bGo<C-R>"<esc>:w<C-M>

" Register pressure simulation folding
map ,s :set foldmarker={\ ,\ }<C-M>:set foldmethod=marker<C-M>

"gtags
"source /usr/local/share/gtags/gtags.vim

"gvim
set guifont=Lucida_Console\:h7\:cANSI

"VCSCommand plug-in: http://vim.sourceforge.net/scripts/script.php?script_id=90
map <Leader>ch :helptags $VIM/vim70/doc<C-M>

" Xiaoli's additions

if has("autocmd")
   " In text files, always limit the width of text to 80 characters
   autocmd BufRead *.txt set tw=80
   " When editing a file, always jump to the last cursor position
   autocmd BufReadPost * if line("'\"") | exe "'\"" | endif
endif

" abbreviations
ab teh the
ab adn and
" ab xiaoli Xiaoli Liang
