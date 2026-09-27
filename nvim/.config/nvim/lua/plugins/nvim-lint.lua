return {
  "mfussenegger/nvim-lint",

  config = function()
    local lint = require("lint")

    lint.linters_by_ft = {
      elixir = { "credo" },
    }

    vim.api.nvim_create_autocmd({ "BufReadPost" }, {
      callback = function()
        lint.try_lint()
      end,
    })
    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
      callback = function()
        lint.try_lint()
      end,
    })
  end,
}
