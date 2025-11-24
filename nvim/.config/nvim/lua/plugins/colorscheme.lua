return {
  {
    "folke/tokyonight.nvim",
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
