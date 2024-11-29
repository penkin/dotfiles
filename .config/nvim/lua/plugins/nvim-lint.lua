return {
  "mfussenegger/nvim-lint",
  opts = {
    linters_by_ft = {
      django = { "djlint" },
      htmldjango = { "djlint" },
      gdscript = { "gdlint" },
      elixir = { "credo" },
    },
  },
}
