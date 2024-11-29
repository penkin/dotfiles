return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  lazy = false,
  version = false,
  keys = {
    { "<leader>am", "", desc = "avante: model" },
    {
      "<leader>amh",
      function()
        local avante = require("avante")
        local model = "claude-3-5-haiku-20241022"
        avante.setup({ provider = "claude", claude = { model = model } })
        vim.notify("Switched to " .. model)
      end,
      desc = "Switch to claude-3-5-haiku-20241022",
    },
    {
      "<leader>ams",
      function()
        local avante = require("avante")
        local model = "claude-3-5-sonnet-20241022"
        avante.setup({ provider = "claude", claude = { model = model } })
        vim.notify("Switched to " .. model)
      end,
      desc = "Switch to claude-3-5-sonnet-20241022",
    },
  },
  opts = {
    provider = "claude",
    claude = {
      model = "claude-3-5-haiku-20241022",
    },
    auto_suggestions_provider = "copilot",
    behaviour = {
      auto_suggestions = true,
    },
  },
  build = "make",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-tree/nvim-web-devicons",
    "zbirenbaum/copilot.lua",
    {
      -- support for image pasting
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        -- recommended settings
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
        },
      },
    },
    {
      -- Make sure to set this up properly if you have lazy=true
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
  },
}
