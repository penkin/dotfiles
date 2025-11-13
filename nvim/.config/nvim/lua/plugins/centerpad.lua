return {
  "smithbm2316/centerpad.nvim",
  cmd = "Centerpad",
  keys = {
    -- Toggle with calculated padding based on center width
    {
      "<leader>z",
      function()
        local center_width = 120 -- Set your desired center width here
        local total_width = vim.o.columns
        local padding = math.floor((total_width - center_width) / 2)

        -- Make sure padding is at least 0
        padding = math.max(0, padding)

        require("centerpad").toggle({
          leftpad = padding,
          rightpad = padding,
        })
      end,
      desc = "Toggle centerpad (auto-calculated)",
    },
    -- Or just use default padding
    { "<leader>Z", "<cmd>Centerpad<cr>", desc = "Toggle centerpad (default)" },
  },
}
