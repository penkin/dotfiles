return {
  "nvim-neorg/neorg",

  config = function()
    require("neorg").setup({
      load = {
        ["core.defaults"] = {},
        ["core.concealer"] = {
          config = {
            icon_preset = "basic",
          },
        },
        ["core.dirman"] = {
          config = {
            notes = "~/Knowledge",
          },
          default_workspace = "Knowledge",
        },
        ["core.summary"] = {},
        ["core.completion"] = {
          config = {
            engine = "nvim-cmp",
          },
        },
        ["core.itero"] = {},
        ["core.journal"] = {},
        ["core.ui.calendar"] = {},
        ["core.qol.toc"] = {},
      },
    })

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
      pattern = { "*.norg" },
      command = "set conceallevel=3",
    })
  end,
}
