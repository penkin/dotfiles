vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")
vim.cmd("set number")
vim.cmd("set relativenumber")

vim.g.mapleader = " "

vim.opt.swapfile = false
vim.opt.showmode = false
vim.opt.signcolumn = "yes"

-- Navigate vim panes
vim.keymap.set("n", "<c-h>", ":wincmd h<cr>")
vim.keymap.set("n", "<c-j>", ":wincmd j<cr>")
vim.keymap.set("n", "<c-k>", ":wincmd k<cr>")
vim.keymap.set("n", "<c-l>", ":wincmd l<cr>")

-- JK for escaping
vim.keymap.set("i", "jk", "<esc>")
vim.keymap.set("t", "jk", "<c-\\><c-n>")

-- Get rid of search highlights
vim.keymap.set("n", ",h", ":nohlsearch<cr>")

-- Move quickly between buffers
vim.keymap.set("n", "<leader>bb", ":buffer ")
vim.keymap.set("n", "<leader>bn", ":bnext<cr>")
vim.keymap.set("n", "<leader>bp", ":bprevious<cr>")
vim.keymap.set("n", "<leader>bd", ":bdelete<cr>")
vim.keymap.set("n", "<leader>bl", ":ls<cr>")

-- No line numbers in nvim terminals
vim.api.nvim_create_autocmd("TermOpen", {
	pattern = "*",
	callback = function()
		vim.cmd("setlocal nonumber norelativenumber")
	end,
})

local laststatus_toggle = 0
local function toggle_statusbar()
	if laststatus_toggle == 0 then
		vim.o.laststatus = 0
		laststatus_toggle = 1
	else
		vim.o.laststatus = 2
		laststatus_toggle = 0
	end
end

vim.keymap.set("n", "<leader>vb", toggle_statusbar, { silent = true })
