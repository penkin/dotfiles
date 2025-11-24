return {
  "nvim-treesitter/nvim-treesitter",

  config = function()
    local config = require("nvim-treesitter.configs")

    config.setup({
      ensure_installed = {
        "eex",
        "elixir",
        "erlang",
        "heex",
        "html",
        "javascript",
        "json",
        "scss",
      },
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
    })
  end,
}
