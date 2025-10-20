return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- Add languages to the existing opts.ensure_installed table
      vim.list_extend(opts.ensure_installed, {
        "bash",
        "c_sharp",
        "css",
        "dockerfile",
        "gdscript",
        "godot_resource",
        "html",
        "javascript",
        "json",
        "lua",
        "markdown",
        "regex",
        "scss",
        "toml",
        "python",
        "htmldjango",
      })

      -- Modify indent settings
      opts.indent = vim.tbl_deep_extend("force", opts.indent or {}, {
        enable = true,
        disable = { "gdscript" },
      })

      return opts
    end,
  },
}
