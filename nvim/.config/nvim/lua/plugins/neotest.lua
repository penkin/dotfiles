return {
  "nvim-neotest/neotest",

  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-treesitter/nvim-treesitter",

    -- Test runners
    "jfpedroza/neotest-elixir",
  },

  keys = {
    {
      "<leader>Tt",
      mode = { "n" },
      function()
        require("neotest").run.run({ suite = true })
        require("neotest").summary.open()
      end,
      desc = "Test Suite",
    },
    {
      "<leader>Tn",
      mode = { "n" },
      function()
        require("neotest").run.run()
      end,
      desc = "Test Nearest",
    },
    {
      "<leader>Tf",
      mode = { "n" },
      function()
        require("neotest").run.run(vim.fn.expand("%"))
      end,
      desc = "Test File",
    },
    {
      "<leader>Tx",
      mode = { "n" },
      function()
        require("neotest").run.stop()
      end,
      desc = "Test Stop",
    },
    {
      "<leader>To",
      mode = { "n" },
      function()
        require("neotest").output_panel.toggle()
      end,
      desc = "Test Output",
    },
    {
      "<leader>Tp",
      mode = { "n" },
      function()
        require("neotest").output_panel.toggle()
      end,
      desc = "Test Panel",
    },
    {
      "<leader>Ts",
      mode = { "n" },
      function()
        require("neotest").summary.toggle()
      end,
      desc = "Test Summary",
    },
    {
      "<leader>T,",
      mode = { "n" },
      function()
        require("neotest").jump.prev({ status = "failed" })
      end,
      desc = "Previous Failed",
    },
    {
      "<leader>T;",
      mode = { "n" },
      function()
        require("neotest").jump.next({ status = "failed" })
      end,
      desc = "Next Failed",
    },
  },

  opts = function()
    return {
      adapters = {
        require("neotest-elixir"),
      },
    }
  end,
}
