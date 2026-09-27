return {
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      -- Set up custom registries
      opts.registries = opts.registries or {}
      vim.list_extend(opts.registries, {
        "github:mason-org/mason-registry",
        "github:Crashdummyy/mason-registry",
      })

      -- Ensure required packages are installed
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "csharpier",
        "elixirls",
        "html-lsp",
        "lua-language-server",
        "netcoredbg",
        "prettier",
        "roslyn",
        "rzls",
        "stylua",
        "tailwindcss-language-server",
        "vtsls",
      })
    end,
  },
}
