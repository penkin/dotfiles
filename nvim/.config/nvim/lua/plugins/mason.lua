return {
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        -- LSPs
        "lua-language-server",
        "typos-lsp",
        "basedpyright",
        "ruff-lsp",
        "omnisharp",

        -- Formatters
        "stylua",
        "csharpier",
        "djlint",

        -- Linters
      })
    end,
  },
}
