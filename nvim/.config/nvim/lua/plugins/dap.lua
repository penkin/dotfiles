return {
    "mfussenegger/nvim-dap",
    dependencies = {
        "rcarriga/nvim-dap-ui",
        "nvim-neotest/nvim-nio",
    },
    config = function()
        local dap, dapui = require("dap"), require("dapui")

        vim.fn.mkdir(vim.fn.stdpath("cache") .. "/dap", "p")

        dap.listeners.before.attach.dapui_config = function()
            dapui.open()
        end
        dap.listeners.before.launch.dapui_config = function()
            dapui.open()
        end
        dap.listeners.before.event_terminated.dapui_config = function()
            dapui.close()
        end
        dap.listeners.before.event_exited.dapui_config = function()
            dapui.close()
        end

        dapui.setup()

        -- Setup Elixir debugger
        dap.adapters.mix_task = {
            type = "executable",
            command = vim.fn.expand("~/.local/share/nvim/mason/packages/elixir-ls/debug_adapter.sh"),
            args = {},
            options = {
                initialize_timeout_sec = 300,
            },
        }

        -- Setup .NET debugger
        dap.adapters.coreclr = {
            type = "executable",
            command = "netcoredbg-dotnet8",
            args = { "--interpreter=vscode" },
        }

        require("dap.ext.vscode").load_launchjs()

        vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle Breakpoint" })
        vim.keymap.set("n", "<leader>dl", function()
            dapui.float_element("breakpoints")
        end, { desc = "List Breakpoints" })
        vim.keymap.set("n", "<F2>", dap.continue, { desc = "Debug Continue" })
        vim.keymap.set("n", "<F3>", dap.step_over, { desc = "Debug Step Over" })
        vim.keymap.set("n", "<F4>", dap.step_into, { desc = "Debug Step Into" })
        vim.keymap.set("n", "<F5>", dap.terminate, { desc = "Debug Stop" })

        vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = "#ed8796" })
        vim.api.nvim_set_hl(0, "DapBreakpointLine", { bg = "#181825" })

        vim.api.nvim_set_hl(0, "DapStopped", { fg = "#a6da95" })
        vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = "#11111b" })

        vim.fn.sign_define(
            "DapBreakpoint",
            { text = "", texthl = "DapBreakpoint", linehl = "DapBreakpointLine", numhl = "" }
        )
        vim.fn.sign_define("DapStopped", { text = "", texthl = "DapStopped", linehl = "DapStoppedLine", numhl = "" })
    end,
}
