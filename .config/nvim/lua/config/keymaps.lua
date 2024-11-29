-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local keymap = vim.keymap.set

-- JK for escaping
keymap("i", "jk", "<esc>")
keymap("t", "jk", "<c-\\><c-n>")

-- Tabs
keymap("n", "<Tab>", ":tabnext<CR>", { desc = "Next tab" })
keymap("n", "<S-Tab>", ":tabprevious<CR>", { desc = "Previous tab" })
keymap("n", "<leader><Tab>r", ":Tabby rename_tab ", { desc = "Rename tab" })

-- Oil
keymap("n", "-", "<cmd>Oil<cr>", { desc = "Open Oil" })
