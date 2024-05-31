return {
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",

  config = function()
    require("ibl").setup({
      scope = { enabled = false },
      exclude = {
        filetypes = {
          "help",
          "alpha",
          "dashboard",
          "neo-tree",
          "Trouble",
          "trouble",
          "lazy",
          "mason",
          "notify",
          "toggleterm",
          "lazyterm",
        },
      },
    })
  end,
}
