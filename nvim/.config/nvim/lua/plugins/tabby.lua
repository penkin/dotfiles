return {
  "nanozuki/tabby.nvim",
  config = function()
    local theme = {
      fill = "TabLineFill",
      current_tab = "TabLineSel",
      tab = "TabLine",
    }
    require("tabby").setup({
      line = function(line)
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
          hl = theme.fill,
        }
      end,
    })

    vim.keymap.set("n", "<leader>w,", function()
      local snacks = require("snacks")
      snacks.input({ prompt = "Tab name: " }, function(input)
        if input then
          vim.cmd("Tabby rename_tab " .. input)
        end
      end)
    end)
  end,
}
