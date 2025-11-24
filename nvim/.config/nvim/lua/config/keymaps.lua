-- JK for escaping
vim.keymap.set({ "i" }, "jk", "<esc>")
vim.keymap.set("t", "jk", "<c-\\><c-n>")

-- -- Navigation between splits
-- vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
-- vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
-- vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
-- vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

vim.keymap.set("n", "<up>", [[<cmd>horizontal resize +2<cr>]])
vim.keymap.set("n", "<down>", [[<cmd>horizontal resize -2<cr>]])
vim.keymap.set("n", "<right>", [[<cmd>vertical resize -5<cr>]])
vim.keymap.set("n", "<left>", [[<cmd>vertical resize -5<cr>]])

-- Clear highlights on search when pressing <Esc> in normal mode
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Move between buffers
vim.keymap.set("n", "<leader>bn", "<cmd>bn<cr>")
vim.keymap.set("n", "<leader>bp", "<cmd>bp<cr>")

-- Tab amanagement
vim.keymap.set("n", "<leader>wc", "<cmd>tabnew<cr>")
vim.keymap.set("n", "<leader>wn", "<cmd>tabnext<cr>")
vim.keymap.set("n", "<leader>wp", "<cmd>tabprev<cr>")
vim.keymap.set("n", "<leader>wv", "<cmd>vsplit<cr>", { desc = "Open split vertically" })
vim.keymap.set("n", "<leader>ws", "<cmd>split<cr>", { desc = "Open split horizontally" })

vim.keymap.set("n", "<leader>tt", "<cmd>terminal<cr><cmd>startinsert<cr>", { desc = "Open terminal in window" })
vim.keymap.set(
  "n",
  "<leader>tv",
  "<cmd>vsplit | wincmd l | terminal<cr><cmd>startinsert<cr>",
  { desc = "Open terminal in vertical split" }
)
vim.keymap.set(
  "n",
  "<leader>ts",
  "<cmd>split | wincmd j | terminal<cr><cmd>startinsert<cr>",
  { desc = "Open terminal in horizontal split" }
)

-- Jump to specific tab numbers
for i = 1, 9 do
  vim.keymap.set("n", "<leader>" .. i, i .. "gt", { desc = "Go to tab " .. i })
end

vim.keymap.set("n", "gk", vim.diagnostic.open_float, { desc = "Diagnostic hover" })
