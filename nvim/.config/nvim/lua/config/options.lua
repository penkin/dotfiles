-- No line numbers in nvim terminals
vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*",
  callback = function()
    vim.cmd("setlocal nonumber norelativenumber")
  end,
})
