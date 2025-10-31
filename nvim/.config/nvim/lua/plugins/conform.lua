return {
    "stevearc/conform.nvim",

    opts = {
        formatters_by_ft = {
            elixir = { "mix" },
            heex = { "mix" },
            lua = { "stylua" },
        },

        format_on_save = {},
    },
}
