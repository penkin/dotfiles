-- Both schemes stay installed and configured. Tokyo Night is the one applied at
-- startup; switch at runtime with `:colorscheme catppuccin`.
return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    -- Configured first so that catppuccin's `colorscheme` call is the one
    -- that lands.
    priority = 1000,
    config = function()
      require("tokyonight").setup({
        on_highlights = function(hl, colors)
          hl.CursorLine = { bg = "#1e293b" }
          hl.DapBreakpoint = { fg = colors.red }
          hl.DapBreakpointLine = { bg = "#2d1a1a" }
          hl.DapStopped = { fg = colors.green }
          hl.DapStoppedLine = { bg = "#1a2d1a" }
          -- hl.VisualMagenta = { bg = "#351a42" }

          -- Cursor colors for different modes
          hl.CursorNormal = { bg = colors.blue, fg = colors.bg }
          hl.CursorInsert = { bg = colors.green, fg = colors.bg }
          hl.CursorVisual = { bg = colors.magenta, fg = colors.bg }
          hl.CursorReplace = { bg = colors.red, fg = colors.bg }
          hl.CursorCommand = { bg = "#e0af68", fg = colors.bg }
          hl.CursorTerminal = { bg = "#9ece6a", fg = colors.bg }
        end,
      })
    end,
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 999,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha",
        custom_highlights = function(colors)
          return {
            CursorLine = { bg = colors.surface0 },
            DapBreakpoint = { fg = colors.red },
            DapBreakpointLine = { bg = "#2d1a1a" },
            DapStopped = { fg = colors.green },
            DapStoppedLine = { bg = "#1a2d1a" },

            -- Cursor colors for different modes
            CursorNormal = { bg = colors.blue, fg = colors.base },
            CursorInsert = { bg = colors.green, fg = colors.base },
            CursorVisual = { bg = colors.mauve, fg = colors.base },
            CursorReplace = { bg = colors.red, fg = colors.base },
            CursorCommand = { bg = colors.yellow, fg = colors.base },
            CursorTerminal = { bg = colors.teal, fg = colors.base },
          }
        end,
      })

      vim.cmd.colorscheme("tokyonight-night")

      -- Set cursor mode
      vim.opt.guicursor = {
        "n-v:block-CursorNormal",
        "c:block-CursorCommand-blinkwait700-blinkon400-blinkoff250",
        "i-ci-ve:ver10-CursorInsert-blinkwait700-blinkon400-blinkoff250",
        "v-ve:block-CursorVisual",
        "r-cr:hor10-CursorReplace-blinkwait700-blinkon400-blinkoff250",
        "o:hor50-CursorNormal",
      }

      -- -- Apply magenta visual only to normal buffers
      -- vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
      --   callback = function()
      --     local ft = vim.bo.filetype
      --     if not ft:match("^snacks") and ft ~= "" then
      --       vim.wo.winhighlight = "Visual:VisualMagenta"
      --     end
      --   end,
      -- })
    end,
  },
}
