return {
  {
    "catppuccin/nvim",
    lazy = false,
    name = "catppuccin",

    config = function()
      require("catppuccin").setup()
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}
