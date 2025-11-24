return {
  "stevearc/oil.nvim",
  dependencies = { { "nvim-mini/mini.icons", opts = {} } },
  lazy = false,

  keys = {
    { "-", mode = { "n" }, "<CMD>Oil<CR>", desc = "Open parent directory" },
  },

  opts = {
    skip_confirm_for_simple_edits = true,
    view_options = {
      show_hidden = true,
    },
  },
}
