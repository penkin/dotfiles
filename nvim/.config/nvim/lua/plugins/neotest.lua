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
            "<leader>tt",
            mode = { "n" },
            function()
                require("neotest").run.run({ suite = true })
                require("neotest").summary.open()
            end,
            desc = "Test Suite",
        },
        {
            "<leader>tn",
            mode = { "n" },
            function()
                require("neotest").run.run()
            end,
            desc = "Test Nearest",
        },
        {
            "<leader>tf",
            mode = { "n" },
            function()
                require("neotest").run.run(vim.fn.expand("%"))
            end,
            desc = "Test File",
        },
        {
            "<leader>tx",
            mode = { "n" },
            function()
                require("neotest").run.stop()
            end,
            desc = "Test Stop",
        },
        {
            "<leader>to",
            mode = { "n" },
            function()
                require("neotest").output_panel.toggle()
            end,
            desc = "Test Output",
        },
        {
            "<leader>tp",
            mode = { "n" },
            function()
                require("neotest").output_panel.toggle()
            end,
            desc = "Test Panel",
        },
        {
            "<leader>ts",
            mode = { "n" },
            function()
                require("neotest").summary.toggle()
            end,
            desc = "Test Summary",
        },
        {
            "<leader>t,",
            mode = { "n" },
            function()
                require("neotest").jump.prev({ status = "failed" })
            end,
            desc = "Previous Failed",
        },
        {
            "<leader>t;",
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
