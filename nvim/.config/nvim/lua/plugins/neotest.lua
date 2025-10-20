return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-treesitter/nvim-treesitter",
    -- Test runners
    "nvim-neotest/neotest-python",
    "jfpedroza/neotest-elixir",
  },

  opts = {
    adapters = {
      ["neotest-python"] = {},
      ["neotest-elixir"] = {},
    },
  },
}
