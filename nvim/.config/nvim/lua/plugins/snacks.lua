return {
  "folke/snacks.nvim",

  opts = {
    picker = {
      -- focus = "list",
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
      "<leader>/",
      mode = { "n" },
      function()
        Snacks.picker.grep({ layout = "ivy" })
      end,
      desc = "File Grep Picker",
    },
    {
      "<leader>:",
      function()
        Snacks.picker.command_history()
      end,
      desc = "Command History",
    },
    {
      "<leader>'",
      mode = { "n" },
      function()
        Snacks.picker.marks()
      end,
      desc = "File Marks",
    },
    {
      '<leader>"',
      mode = { "n" },
      function()
        Snacks.picker.registers()
      end,
    },
    {
      "<leader>fj",
      mode = { "n" },
      function()
        Snacks.picker.jumps()
      end,
      desc = "File Jumps",
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

    -- GIT PICKERS
    {
      "<leader>gb",
      function()
        Snacks.picker.git_branches()
      end,
      desc = "Git Branches",
    },
    {
      "<leader>gl",
      function()
        Snacks.picker.git_log()
      end,
      desc = "Git Log",
    },
    {
      "<leader>gL",
      function()
        Snacks.picker.git_log_line()
      end,
      desc = "Git Log Line",
    },
    {
      "<leader>gs",
      function()
        Snacks.picker.git_status()
      end,
      desc = "Git Status",
    },
    {
      "<leader>gS",
      function()
        Snacks.picker.git_stash()
      end,
      desc = "Git Stash",
    },
    {
      "<leader>gd",
      function()
        Snacks.picker.git_diff()
      end,
      desc = "Git Diff (Hunks)",
    },
    {
      "<leader>gf",
      function()
        Snacks.picker.git_log_file()
      end,
      desc = "Git Log File",
    },
    {
      "<leader>gi",
      function()
        Snacks.picker.gh_issue()
      end,
      desc = "Github Issues (open)",
    },
    {
      "<leader>gI",
      function()
        Snacks.picker.gh_issue({ state = "all" })
      end,
      desc = "Github Issues (open)",
    },
    {
      "<leader>gp",
      function()
        Snacks.picker.gh_pr()
      end,
      desc = "Github Pull Requests (open)",
    },
    {
      "<leader>gP",
      function()
        Snacks.picker.gh_pr({ state = "all" })
      end,
      desc = "Github Pull Requests (all)",
    },

    -- LSP PICKERS
    {
      "<leader>ld",
      mode = { "n" },
      function()
        Snacks.picker.lsp_definitions({ layout = "ivy" })
      end,
      desc = "LSP Definitions",
    },
    {
      "<leader>lD",
      mode = { "n" },
      function()
        Snacks.picker.lsp_declarations({ layout = "ivy" })
      end,
      desc = "LSP Declarations",
    },
    {
      "<leader>lr",
      mode = { "n" },
      function()
        Snacks.picker.lsp_references({ layout = "ivy" })
      end,
      desc = "LSP References",
    },
    {
      "<leader>li",
      mode = { "n" },
      function()
        Snacks.picker.lsp_implementations({ layout = "ivy" })
      end,
      desc = "LSP Implementations",
    },
    {
      "<leader>lt",
      mode = { "n" },
      function()
        Snacks.picker.lsp_type_definitions({ layout = "ivy" })
      end,
      desc = "LSP Type Definitions",
    },
    {
      "<leader>lci",
      mode = { "n" },
      function()
        Snacks.picker.lsp_incoming_calls({ layout = "ivy" })
      end,
      desc = "LSP Incoming Calls",
    },
    {
      "<leader>lco",
      mode = { "n" },
      function()
        Snacks.picker.lsp_outgoing_calls({ layout = "ivy" })
      end,
      desc = "LSP Outgoing Calls",
    },
    {
      "<leader>ls",
      mode = { "n" },
      function()
        Snacks.picker.lsp_symbols({ layout = "ivy" })
      end,
      desc = "LSP Symbols",
    },
    {
      "<leader>lws",
      mode = { "n" },
      function()
        Snacks.picker.lsp_workspace_symbols({ layout = "ivy" })
      end,
      desc = "LSP Workspace Symbols",
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
      desc = "Highlights Picker",
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

  config = function(_, opts)
    -- MonkeyPatch - https://github.com/folke/snacks.nvim/pull/2012
    local M = require("snacks.picker.core.main")
    M.new = function(opts)
      opts = vim.tbl_extend("force", {
        float = false,
        file = true,
        current = false,
      }, opts or {})
      local self = setmetatable({}, M)
      self.opts = opts
      self.win = vim.api.nvim_get_current_win()
      return self
    end

    -- Setup snacks with opts
    require("snacks").setup(opts)
  end,
}
