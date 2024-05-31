return {
  "ggandor/leap.nvim",
  dependencies = {
    "tpope/vim-repeat",
  },
  config = function()
    vim.keymap.set({ "n", "x", "o" }, "s", "<Plug>(leap)")
  end,
}
