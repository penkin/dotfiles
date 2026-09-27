" ~/.idea-lazy.vim

" To install, add this to the top of your ~/.ideavimrc:
" source ~/.idea-lazy.vim

" LazyVim default settings
" https://www.lazyvim.org/configuration/general

let mapleader=" "
let maplocalleader="\\"

" Confirm to save changes before exiting modified buffer
set formatoptions=jcroqlnt
" Print line number
set number
" Relative line numbers
set relativenumber
" Lines of context
set scrolloff=4
" Round indent
set shiftround
" Columns of context
set sidescrolloff=8
" which-key says to set this high, or set notimeout
set timeoutlen=5000
set undolevels=10000
" Disable line wrap
set nowrap

" Neovim settings that differ from Vim
" https://neovim.io/doc/user/diff.html
" https://github.com/mikeslattery/nvim-defaults.vim/blob/main/plugin/.vimrc

set backspace=indent,eol,start
set formatoptions=tcqj
set listchars=tab:>\ ,trail:-,nbsp:+
set shortmess=filnxtToOF

" Enable plugin behavior

" https://github.com/JetBrains/ideavim/wiki/IdeaVim-Plugins
" https://www.lazyvim.org/plugins

" gcc and gc<action> mappings.
Plug 'tpope/vim-commentary'
" s action, such as cs"' (replace " with '), ds" (unquote)
Plug 'tpope/vim-surround'
" similar to flash.nvim
" Plug 'justinmk/vim-sneak'
" Enable the whichkey plugin, available on Jetbrains marketplace
set which-key
" Extended matching.  A Neovim default plugin.
set matchit

" Key maps

" https://www.lazyvim.org/configuration/keymaps

" General Keymaps

" Go to Left Window
nmap <C-h> <C-w>h
" Go to Lower Window
nmap <C-j> <C-w>j
" Go to Upper Window
nmap <C-k> <C-w>k
" Go to Right Window
nmap <C-l> <C-w>l
" Increase Window Height
nmap <C-Up> <Action>(IncrementWindowHeight)
" Decrease Window Height
nmap <C-Down> <Action>(DecrementWindowHeight)
" Decrease Window Width
nmap <C-Left> <Action>(DecrementWindowWidth)
" Increase Window Width
nmap <C-Right> <Action>(IncrementWindowWidth)
" Move Down
nmap <A-j> <Action>(MoveLineDown)
" Move Down
imap <A-j> <Esc><Action>(MoveLineDown)i
" Move Up
nmap <A-k> k
" Prev Buffer
nmap <S-h> <Action>(PreviousTab)
" Next Buffer
nmap <S-l> <Action>(NextTab)
" Prev Buffer (alternative)
nmap <S-h> <Action>(PreviousTab)
" Next Buffer (alternative)
nmap [b <Action>(NextTab)
" Switch to Other Buffer
nmap ]b <Action>(NextTab)
" Switch to Other Buffer (alternative)
nmap <leader>bb <Action>(NextTab)
" Delete Buffer
nmap <leader>bd <Action>(CloseContent)
" Delete Buffer and Window
nmap <leader>bD <Action>(CloseContent)
" Escape and Clear hlsearch
nmap <esc> :nohlsearch<CR>
nmap <leader>ur :nohlsearch<CR>
" Save File
inoremap <C-s> <C-o>:w<CR>
" Keywordprg
nmap <leader>K :help<space><C-r><C-w><CR>
" Add Comment Below
nmap gco jgcck
" Add Comment Above
nmap gcO kgccj
" Lazy
nmap <leader>l <Action>(WelcomeScreen.Plugins)
" New File
nmap <leader>fn :enew<CR>
" Location List
nmap <leader>xl <Action>(ActivateProblemsViewToolWindow)
" Quickfix List
nmap <leader>xq <Action>(ActivateProblemsViewToolWindow)
" Previous Quickfix
nmap [q <Action(GotoPreviousError)
" Next Quickfix
nmap ]q <Action(GotoNextError)
" Format
nmap <leader>cf <Action>(Format)
vmap <leader>cf <Action>(Format)
" Line Diagnostics
nmap <leader>cd <Action>(ActivateProblemsViewToolWindow)
" Next Diagnostic
nmap ]d <Action(GotoNextError)
" Prev Diagnostic
nmap [d <Action(GotoPreviousError)
" Next Error
nmap ]e <Action(GotoNextError)
" Prev Error
nmap [e <Action(GotoPreviousError)
" Next Warning
nmap ]w <Action(GotoNextError)
" Prev Warning
nmap [w <Action(GotoPreviousError)
" Toggle Auto Format (Global)
nmap <leader>ub :echo 'There is no equivalent mapping for Toggle Auto Format.'<cr>
" Toggle Auto Format (Buffer)
nmap <leader>uB :echo 'There is no equivalent mapping for Toggle Auto Format.'<cr>
" Toggle Spelling
nmap <leader>us :setlocal spell!<CR>
" Toggle Wrap
nmap <leader>uw :setlocal wrap!<CR>
" Toggle Relative Number
nmap <leader>uL :set relativenumber!<CR>
" Toggle Diagnostics
nmap <leader>ud <Action>(ActivateProblemsViewToolWindow)
" Toggle Line Numbers
nmap <leader>ul :set number!<CR>
" Toggle conceallevel
nmap <leader>uc :echo 'There is no equivalent mapping for Toggle Conceallevel.'<cr>
" Toggle Treesitter Highlight
nmap <leader>uT :echo 'There is no equivalent mapping for Toggle Treesitter Highlight.'<cr>
" Toggle Background
nmap <leader>ub :echo 'There is no equivalent mapping for Toggle Background.'<cr>
" Toggle Inlay Hints
nmap <leader>uh :echo 'There is no equivalent mapping for Toggle Inlay Hints.'<cr>
" Lazygit (Root Dir)
nmap <leader>gg <Action>(ActivateCommitToolWindow)
" Lazygit (cwd)
nmap <leader>gG <Action>(ActivateCommitToolWindow)
" Git Blame Line
nmap <leader>gb <Action>(Annotate)
" Git Browse
nmap <leader>gB :echo 'Not yet implemented'<CR>
" Lazygit Current File History
nmap <leader>gf <Action>(Vcs.Show.Log)
" Lazygit Log
nmap <leader>gl <Action>(Vcs.Show.Log)
" Lazygit Log (cwd)
nmap <leader>gL <Action>(Vcs.Show.Log)
" Quit All
nmap <leader>qq <Action>(Exit)
" Inspect Pos
nmap <leader>ui <Actrion>(FindUsages)
" Inspect Tree
nmap <leader>uI <Action>(ActivateStructureToolWindow)
" LazyVim Changelog
nmap <leader>L <Action>(Vcs.Show.Log)
" Terminal (Root Dir)
nmap <leader>ft <Action>(ActivateTerminalToolWindow)
" Terminal (cwd)
nmap <leader>fT <Action>(ActivateTerminalToolWindow)
" Terminal (Root Dir)
" nmap <C-/><C-w> <Action>(ActivateTerminalToolWindow)
" Hide Terminal
nmap <C-_> <Action>(ActivateTerminalToolWindow)
" Split Window Below.  :split<cr> doesn't work.
nmap <leader>- <c-w>s
" Split Window Right
nmap <leader><bar> <c-w>v
" Delete Window
nmap <leader>wd <Action>(CloseContent)
" Toggle Maximize
nmap <leader>wm <Action>(ToggleDistractionFreeMode)
" Last Tab
nmap <leader><tab>l <Action>(GoToLastTab)
" Close Other Tabs
nmap <leader><tab>o <Action>(CloseOtherTabs)
" First Tab
nmap <leader><tab>f <Action>(GoToTab1)
" New Tab
nmap <leader><tab><tab> :enew<CR>
" Next Tab
nmap <leader><tab>] <Action>(NextTab)
" Close Tab
nmap <leader><tab>d <Action>(CloseContent)
" Previous Tab
nmap <leader><tab>[ <Action>(PreviousTab)

" LSP Keymaps

" Lsp Info
nmap <leader>cc :echo 'There is no equivalent mapping for Lsp Info.'<cr>
" Goto Definition
nmap gd <Action>(GotoDeclaration)
" References
nmap gr <Action>(FindUsages)
" Goto Implementation
nmap gI <Action>(GotoImplementation)
" Goto Type Definition
nmap gy <Action>(GotoTypeDeclaration)
" Goto Declaration
nmap gD <Action>(GotoDeclaration)
" Signature Help
nmap gK <Action>(ParameterInfo)
" Signature Help in Insert Mode
imap <C-k> <C-o><Action>(ParameterInfo)
" Code Action
nmap <leader>ca <Action>(RefactoringMenu)
vmap <leader>ca <Action>(RefactoringMenu)
" Run Codelens
nmap <leader>cc :echo 'There is no equivalent mapping for Run Codelens.'<cr>
vmap <leader>cc :echo 'There is no equivalent mapping for Run Codelens.'<cr>
" Refresh & Display Codelens
nmap <leader>cC :echo 'There is no equivalent mapping for Refresh & Display Codelens.'<cr>
" Rename File
nmap <leader>cR <Action>(RenameFile)
" Rename
nmap <leader>cr <Action>(RenameElement)
" Source Action
nmap <leader>cA <Action>(ShowIntentionActions)
" Next Reference
nmap ]] <Action>(GotoNextError)
" Prev Reference
nmap [[ <Action>(GotoPreviousError)
" Next Reference (alternative)
nmap <a-n> <Action>(GotoNextError)
" Prev Reference (alternative)
nmap <a-p> <Action>(GotoPreviousError)
" Neo-tree Keymaps

" Buffer Explorer
nmap <leader>be <Action>(ActivateProjectToolWindow)
" Explorer NeoTree (Root Dir)
nmap <leader>e <Action>(FileStructurePopup)
" Explorer NeoTree (cwd)
nmap <leader>E <Action>(SelectInProjectView)
" Explorer NeoTree (Root Dir) (alternative)
nmap <leader>fe <Action>(ActivateProjectToolWindow)
" Explorer NeoTree (cwd) (alternative)
nmap <leader>fE <Action>(ActivateProjectToolWindow)
" Git Explorer
nmap <leader>ge <Action>(ActivateVersionControlToolWindow)
" Telescope Keymaps

" Find Files (Root Dir)
nmap <leader><space> <Action>(Switcher)
" Switch Buffer
nmap <leader>, <Action>(Switcher)
" Grep (Root Dir)
nmap <leader>/ <Action>(FindInPath)
" Command History
nmap <leader>: :history<cr>
" Buffers
nmap <leader>fb <Action>(Switcher)
" Find Config File
nmap <leader>fc <Action>(GotoFile)
" Find Files (Root Dir) (alternative)
nmap <leader>ff <Action>(GotoFile)
" Find Files (cwd)
nmap <leader>fF <Action>(GotoFile)
" Find Files (git-files)
nmap <leader>fg <Action>(GotoFile)
" Recent
nmap <leader>fr <Action>(RecentFiles)
" Recent (cwd)
nmap <leader>fR <Action>(RecentFiles)
" Commits
nmap <leader>gc <Action>(Vcs.Show.Log)
" Status
nmap <leader>gs <Action>(Vcs.Show.Log)
" Registers
nmap <leader>s" :registers<cr>
" Auto Commands
nmap <leader>sa :echo 'There is no equivalent mapping.'<cr>
" Buffer
nmap <leader>sb <Action>(Switcher)
" Command History (alternative)
nmap <leader>sc :history<cr>
" Commands
nmap <leader>sC :commands<cr>
" Document Diagnostics
nmap <leader>sd <Action>(ActivateProblemsViewToolWindow)
" Workspace Diagnostics
nmap <leader>sD <Action>(ActivateProblemsViewToolWindow)
" Grep (Root Dir) (alternative)
nmap <leader>sg <Action>(FindInPath)
" Grep (cwd)
nmap <leader>sG <Action>(FindInPath)
" Help Pages
nmap <leader>sh <Action>(HelpTopics)
" Search Highlight Groups
nmap <leader>sH <Action>(HighlightUsagesInFile)
" Jumplist
nmap <leader>sj <Action>(RecentLocations)
" Key Maps
nmap <leader>sk :map<cr>
" Location List
nmap <leader>sl <Action>(ActivateProblemsViewToolWindow)
" Jump to Mark
nmap <leader>sm :marks<cr>
" Man Pages
nmap <leader>sM <Action>(ShowDocumentation)
" Options
nmap <leader>so <Action>(ShowSettings)
" Quickfix List
nmap <leader>sq <Action>(ActivateProblemsViewToolWindow)
" Resume
nmap <leader>sR :echo 'Not yet implmented.'<cr>
" Goto Symbol
nmap <leader>ss <Action>(GotoSymbol)
" Goto Symbol (Workspace)
nmap <leader>sS <Action>(GotoSymbol)
" Word (Root Dir)
nmap <leader>sw <Action>(FindWordAtCaret)
" Word (cwd)
nmap <leader>sW <Action>(FindWordAtCaret)
" Selection (Root Dir)
vmap <leader>sw <Action>(FindWordAtCaret)
" Selection (cwd)
vmap <leader>sW <Action>(FindWordAtCaret)
" Colorscheme with Preview
nmap <leader>uC <Action>(QuickChangeScheme)

" DAP Keymaps

" Run with Args
nmap <leader>da <Action>(ChooseRunConfiguration)
" Toggle Breakpoint
nmap <leader>db <Action>(ToggleBreakpointAction)
" Breakpoint Condition
nmap <leader>dB <Action>(ToggleBreakpointAction)
" Continue
nmap <leader>dc <Action>(Resume)
" Run to Cursor
nmap <leader>dC <Action>(ForceRunToCursor)
" Go to Line (No Execute)
nmap <leader>dg <Action>(GotoLine)
" Step Into
nmap <leader>di <Action>(StepInto)
" Down
nmap <leader>dj <Action>(GotoNextError)
" Up
nmap <leader>dk <Action>(GotoPreviousError)
" Run Last
nmap <leader>dl <Action>(Debug)
" Step Out
nmap <leader>do <Action>(StepOut)
" Step Over
nmap <leader>dO <Action>(StepOver)
" Pause
nmap <leader>dp <Action>(Pause)
" Toggle REPL
nmap <leader>dr <Action>(JShell.Console)
" Session
nmap <leader>ds :echo 'Not yet implmented.'<cr>
" Terminate
nmap <leader>dt <Action>(Stop)
" Widgets
nmap <leader>dw :echo 'There is no equivalent mapping for Widgets.'<cr>
" Todo-comments Keymaps

" Todo
nmap <leader>st oTODO<esc>gcc
" Todo/Fix/Fixme
nmap <leader>sT :echo 'Not yet implemented.'<cr>
" Todo (Trouble)
nmap <leader>xt :echo 'Not yet implemented.'<cr>
" Todo/Fix/Fixme (Trouble)
nmap <leader>xT :echo 'Not yet implemented.'<cr>
" Previous Todo Comment
nmap [t ?TODO<cr>
" Next Todo Comment
nmap ]t /TODO<cr>
" DAP UI Keymaps

" Eval
nmap <leader>de <Action>(EvaluateExpression)
vmap <leader>de <Action>(EvaluateExpression)
" Dap UI
nmap <leader>du :echo 'Not yet implemented.'<cr>
" Neotest Keymaps

" Run Last
nmap <leader>tl <Action>(Debug)
" Show Output
nmap <leader>to :echo 'Not yet implemented.'<cr>
" Toggle Output Panel
nmap <leader>tO :echo 'Not yet implemented.'<cr>
" Run Nearest
nmap <leader>tr <Action>(RunTestGroup)
" Toggle Summary
nmap <leader>ts <Action>(ShowTestSummary)
" Stop
nmap <leader>tS <Action>(Stop)
" Run File
nmap <leader>tt <Action>(RunTestGroup)
" Run All Test Files
nmap <leader>tT <Action>(RunAllTests)
" Toggle Watch
nmap <leader>tw <Action>(ToggleTestWatch)
" Neovim mappings
" https://neovim.io/doc/user/vim_diff.html#_default-mappings

nnoremap Y y$
inoremap <C-U> <C-G>u<C-U>
inoremap <C-W> <C-G>u<C-W>
" Q isn't exactly the same.
nnomap Q @@
" There are several more Neovim mappings that need to be ported.  See link.

" Jetbrains conflicts
" https://github.com/JetBrains/ideavim/blob/master/doc/sethandler.md
" None, yet.  Possible conflicts: ctrl -6befhjklorsvw
