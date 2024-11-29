return {
  {
    "mfussenegger/nvim-dap",
    optional = true,
    dependencies = {
      "mfussenegger/nvim-dap-python",
    },
    opts = function(_, opts)
      local dap = require("dap")

      vim.fn.mkdir(vim.fn.stdpath("cache") .. "/dap", "p")
      dap.set_log_level("TRACE")

      -- Python
      require("dap-python").setup("~/.virtualenvs/debugpy/bin/python")

      -- Godot configuration
      dap.adapters.godot = {
        type = "server",
        host = "127.0.0.1",
        port = 6006,
      }

      dap.configurations.gdscript = {
        {
          type = "godot",
          request = "launch",
          name = "Launch scene",
          project = "${workspaceFolder}",
          launch_scene = true,
        },
      }

      dap.adapters.mix_task = {
        type = "executable",
        command = "/home/jean/.local/share/nvim/mason/packages/elixir-ls/debug_adapter.sh",
        args = {},
      }

      -- Load launch.json configurations
      require("dap.ext.vscode").load_launchjs()

      return opts
    end,
  },
}
