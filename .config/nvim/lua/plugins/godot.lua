return {
  {
    "habamax/vim-godot",
    event = "VimEnter",

    config = function()
      local gdproject = io.open(vim.fn.getcwd() .. "/project.godot", "r")
      if gdproject then
        io.close(gdproject)
        vim.fn.serverstart("./.godothost")
      end
    end,
  },
}
