return {
  "mbbill/undotree",
  cmd = "UndotreeToggle",
  keys = {
    { "<leader>u", nil, desc = "Undo" },
    { "<leader>uu", "<cmd>UndotreeToggle<cr>", desc = "Toggle Undotree" },
    { "<leader>ur", "<cmd>UndotreeRefresh<cr>", desc = "Refresh Undotree" },
    { "<leader>ul", "<cmd>UndotreeFocus<cr>", desc = "Focus Undotree" },
  },
}
