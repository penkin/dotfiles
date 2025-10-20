return {
  "folke/noice.nvim",
  opts = {
    routes = {
      {
        filter = {
          event = "notify",
          find = "setExceptionBreakpoints is currently not supported",
        },
        opts = { skip = true },
      },
      {
        filter = {
          event = "notify",
          find = "Debug adapter didn't respond",
        },
        opts = { skip = true },
      },
    },
  },
}
