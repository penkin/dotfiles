return {
  "nvim-telescope/telescope.nvim",
  dependencies = { "rcarriga/nvim-notify" },
  opts = function()
    require("telescope").load_extension("notify")
  end,
}
