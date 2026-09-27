return {
  "nanozuki/tabby.nvim",
  config = function()
    local theme = {
      fill = "TabLineFill",
      current_tab = "TabLineSel",
      tab = "TabLine",
    }

    local show_clock = true

    local function build_tabline(line)
      local clock = show_clock and { " " .. os.date("%H:%M") .. " ", hl = "Special" } or ""
      return {
        line.tabs().foreach(function(tab)
          local hl = tab.is_current() and theme.current_tab or theme.tab
          return {
            " ",
            tab.number(),
            ". ",
            tab.name(),
            " ",
            hl = hl,
          }
        end),
        line.spacer(),
        clock,
        hl = theme.fill,
      }
    end

    require("tabby").setup({
      line = build_tabline,
    })

    vim.keymap.set("n", "<leader>w0", function()
      show_clock = not show_clock
      vim.cmd("redrawtabline")
    end, { desc = "Toggle clock" })

    vim.keymap.set("n", "<leader>w,", function()
      local snacks = require("snacks")
      snacks.input({ prompt = "Tab name: " }, function(input)
        if input then
          vim.cmd("Tabby rename_tab " .. input)
        end
      end)
    end)

    -- Update tabline every minute to refresh the time
    local timer = vim.loop.new_timer()
    timer:start(
      60000 - (os.time() % 60) * 1000, -- Start at the next minute boundary
      60000, -- Repeat every 60 seconds
      vim.schedule_wrap(function()
        vim.cmd("redrawtabline")
      end)
    )
  end,
}
