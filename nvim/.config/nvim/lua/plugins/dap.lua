return {
  {
    "mfussenegger/nvim-dap",
    config = function()
      local dap = require("dap")

      vim.fn.mkdir(vim.fn.stdpath("cache") .. "/dap", "p")

      -- Setup Elixir debugger
      dap.adapters.mix_task = {
        type = "executable",
        command = vim.fn.stdpath("data") .. "/mason/packages/elixir-ls/debug_adapter.sh",
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
      vim.keymap.set("n", "<F2>", dap.continue, { desc = "Debug Continue" })
      vim.keymap.set("n", "<F3>", dap.step_over, { desc = "Debug Step Over" })
      vim.keymap.set("n", "<F4>", dap.step_into, { desc = "Debug Step Into" })
      vim.keymap.set("n", "<F5>", function()
        dap.terminate()
        vim.cmd("DapViewClose")
      end, { desc = "Debug Stop" })

      vim.fn.sign_define(
        "DapBreakpoint",
        { text = "", texthl = "DapBreakpoint", linehl = "DapBreakpointLine", numhl = "" }
      )
      vim.fn.sign_define("DapStopped", { text = "", texthl = "DapStopped", linehl = "DapStoppedLine", numhl = "" })
    end,
  },
  {
    "igorlfs/nvim-dap-view",
    opts = {
      winbar = {
        default_section = "repl",
      },
      auto_toggle = true,
    },
  },
}
