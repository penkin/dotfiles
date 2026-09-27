return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  lazy = false,
  opts = {
    close_if_last_window = true,
  },
  keys = {
    {
      "<leader>fe",
      mode = { "n" },
      "<cmd>Neotree<cr>",
      desc = "File Explorer",
    },
  },
}
