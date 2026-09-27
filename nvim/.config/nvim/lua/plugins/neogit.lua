return {
  "NeogitOrg/neogit",

  dependencies = {
    "nvim-lua/plenary.nvim",
    "sindrets/diffview.nvim",
  },

  keys = {
    { "<leader>gg", mode = { "n" }, ":Neogit<CR>", desc = "Open git" },
    { "<leader>gd", mode = { "n" }, ":DiffviewOpen<CR>", desc = "Open git diff" },
  },

  opts = {},
}
