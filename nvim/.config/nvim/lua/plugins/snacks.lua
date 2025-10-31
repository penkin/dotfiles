return {
    "folke/snacks.nvim",

    opts = {
        picker = {
            matches = {
                frecency = true,
            },
            sources = {
                lsp_definitions = { auto_confirm = false },
                lsp_implementations = { auto_confirm = false },
                lsp_references = { auto_confirm = false },
                lsp_declarations = { auto_confirm = false },
            },
        },
    },

    keys = {
        -- FILE PICKERS
        {
            "<leader>ff",
            mode = { "n" },
            function()
                Snacks.picker.smart({ layout = "ivy" })
            end,
            desc = "File Picker",
        },
        {
            "<leader>fg",
            mode = { "n" },
            function()
                Snacks.picker.grep({ layout = "ivy" })
            end,
            desc = "File Grep Picker",
        },
        {
            "<leader>fe",
            mode = { "n" },
            function()
                Snacks.picker.explorer()
            end,
            desc = "File Explorer",
        },

        -- BUFFER PICKERS
        {
            "<leader>bb",
            mode = { "n" },
            function()
                Snacks.picker.buffers({ layout = "ivy" })
            end,
            desc = "Buffer Picker",
        },
        {
            "<leader>bg",
            mode = { "n" },
            function()
                Snacks.picker.grep_buffers({ layout = "ivy" })
            end,
            desc = "Buffer Grep Picker",
        },

        -- LSP PICKERS
        {
            "<leader>lr",
            mode = { "n" },
            function()
                Snacks.picker.lsp_references({ layout = "ivy" })
            end,
            desc = "LSP References",
        },
        {
            "<leader>ld",
            mode = { "n" },
            function()
                Snacks.picker.lsp_definitions({ layout = "ivy" })
            end,
            desc = "LSP Definitions",
        },
        {
            "<leader>ls",
            mode = { "n" },
            function()
                Snacks.picker.lsp_symbols({ layout = "ivy" })
            end,
            desc = "LSP Symbols",
        },

        -- HELP PICKERS
        {
            "<leader>hh",
            mode = { "n" },
            function()
                Snacks.picker.help({ layout = "ivy" })
            end,
            desc = "Help Picker",
        },
        {
            "<leader>hi",
            mode = { "n" },
            function()
                Snacks.picker.highlights({ layout = "ivy" })
            end,
            desc = "Help Picker",
        },

        -- SCRATCH
        {
            "<leader>fs",
            mode = { "n" },
            function()
                Snacks.scratch()
            end,
            desc = "Scratch Buffer",
        },
        {
            "<leader>fS",
            mode = { "n" },
            function()
                Snacks.scratch.select()()
            end,
            desc = "Select Scratch Buffer",
        },
    },
}
