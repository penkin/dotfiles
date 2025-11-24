return {
  "folke/which-key.nvim",
  event = "VeryLazy",

  opts = {
    preset = "modern",
    delay = 1000,

    -- Window styling
    win = {
      border = "rounded",
      padding = { 1, 2 },
      title = true,
      title_pos = "center",
    },

    -- Layout
    layout = {
      width = { min = 20, max = 50 },
      spacing = 3,
    },

    -- Icons
    icons = {
      breadcrumb = "»",
      separator = "➜",
      group = "+",
      mappings = true,
      colors = true,
    },
  },

  config = function(_, opts)
    local wk = require("which-key")
    wk.setup(opts)

    wk.add({
      -- Main prefix groups
      { "<leader>a", group = "AI" },
      { "<leader>b", group = "Buffers" },
      { "<leader>f", group = "Find/Files" },
      { "<leader>g", group = "Git" },
      { "<leader>l", group = "LSP", icon = "󰌵" },
      { "<leader>d", group = "Debug" },
      { "<leader>t", group = "Terminal" },
      { "<leader>T", group = "Test" },
      { "<leader>u", group = "Undo", icon = "󰕌" },
      { "<leader>w", group = "Windows/Tabs" },
      { "<leader>h", group = "Help", icon = "󰋗" },

      -- LSP subgroups
      { "<leader>lc", group = "Calls" },
      { "<leader>lw", group = "Workspace" },

      -- Tab navigation (hidden)
      { "<leader>1", desc = "Tab 1", hidden = true },
      { "<leader>2", desc = "Tab 2", hidden = true },
      { "<leader>3", desc = "Tab 3", hidden = true },
      { "<leader>4", desc = "Tab 4", hidden = true },
      { "<leader>5", desc = "Tab 5", hidden = true },
      { "<leader>6", desc = "Tab 6", hidden = true },
      { "<leader>7", desc = "Tab 7", hidden = true },
      { "<leader>8", desc = "Tab 8", hidden = true },
      { "<leader>9", desc = "Tab 9", hidden = true },

      -- Special keymaps
      { "<leader>/", desc = "Grep Files" },
      { "<leader>:", desc = "Command History" },
      { "-", desc = "Parent Directory" },

      -- Function keys (Debug)
      { "<F2>", desc = "Continue" },
      { "<F3>", desc = "Step Over" },
      { "<F4>", desc = "Step Into" },
      { "<F5>", desc = "Stop" },
    })

    wk.add({
      mode = { "n" },
      { "<Esc>", desc = "Clear Highlight" },
      { "<C-h>", desc = "← Left Window" },
      { "<C-j>", desc = "↓ Lower Window" },
      { "<C-k>", desc = "↑ Upper Window" },
      { "<C-l>", desc = "→ Right Window" },
    })

    wk.add({
      mode = { "i", "t" },
      { "jk", desc = "Exit to Normal" },
    })
  end,
}
