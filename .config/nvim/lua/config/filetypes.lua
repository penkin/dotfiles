local M = {}

M.setup = function()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "gdscript",
    callback = function()
      vim.bo.tabstop = 4
      vim.bo.shiftwidth = 4
      vim.bo.expandtab = true
      vim.bo.softtabstop = 4
    end,
  })
end

return M
