return {
  "mbbill/undotree",

  config = function()
    vim.keymap.set("n", "<leader>uu", ":UndotreeToggle<cr>")
  end,
}
