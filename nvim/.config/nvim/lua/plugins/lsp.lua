return {
    {
        "williamboman/mason.nvim",
        lazy = false,
        config = function()
            require("mason").setup({
                registries = {
                    "github:mason-org/mason-registry",
                    "github:crashdummyy/mason-registry",
                },
            })
        end,
    },

    {
        "williamboman/mason-lspconfig.nvim",
        lazy = false,
        config = function()
            require("mason-lspconfig").setup({
                auto_install = true,
            })
        end,
    },

    {
        "neovim/nvim-lspconfig",
        lazy = false,
        config = function()
            local capabilities = require("blink.cmp").get_lsp_capabilities()

            -- Configure Expert
            vim.lsp.config('expert', {
                cmd = { "/home/penkin/expert_linux_amd64" },
                capabilities = capabilities,
            })

            -- Configure lua_ls
            vim.lsp.config('lua_ls', {
                capabilities = capabilities,
                settings = {
                    Lua = {
                        diagnostics = {
                            globals = { "vim" },
                        },
                    },
                },
            })
        end,
    },
}
