-- Automatically reload a file on external changes
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
  command = "if mode() != 'c' | checktime | endif",
  pattern = "*",
})

-- Set highlight group of windows to have the darker background highlighting
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "neotest-output-panel", "neotest-summary", "qf", "undotree" },
  callback = function()
    vim.opt_local.winhighlight = "Normal:NormalFloat,NormalNC:NormalFloat"
  end,
})

-- -- Set darker highlight for terminals
-- vim.api.nvim_create_autocmd("TermOpen", {
--   callback = function()
--     vim.opt_local.winhighlight = "Normal:NormalFloat,NormalNC:NormalFloat"
--   end,
-- })

-- Add highlight for yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
  pattern = "*",
  desc = "highlight selection on yank",
  callback = function()
    vim.highlight.on_yank({ timeout = 200, visual = true })
  end,
})

-- Split help vertical
vim.api.nvim_create_autocmd("FileType", {
  pattern = "help",
  command = "wincmd L",
})

-- Return cursor back to the last position in the file
vim.api.nvim_create_autocmd("BufReadPost", {
  pattern = "*",
  callback = function()
    local line = vim.fn.line("'\"")
    if line > 1 and line <= vim.fn.line("$") then
      vim.cmd('normal! g`""`')
    end
  end,
})

-- No line numbers in nvim terminals
vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*",
  callback = function()
    vim.cmd("setlocal nonumber norelativenumber")
  end,
})

-- Cursorline only in active window
vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
  pattern = "*",
  callback = function()
    vim.wo.cursorline = true
  end,
})

vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
  pattern = "*",
  callback = function()
    vim.wo.cursorline = false
  end,
})
