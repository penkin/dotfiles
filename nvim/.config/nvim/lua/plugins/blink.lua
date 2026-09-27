return {
  "saghen/blink.cmp",

  lazy = false,

  dependencies = {
    "L3MON4D3/LuaSnip",
    version = "v2.*",
  },

  version = "v0.*",
  opts = {
    keymap = { preset = "default" },

    appearance = {
      use_nvim_cmp_as_default = true,
      nerd_font_variant = "mono",
    },

    snippets = {
      preset = "luasnip",
      expand = function(snippet)
        require("luasnip").lsp_expand(snippet)
      end,
      active = function(filter)
        if filter and filter.direction then
          return require("luasnip").jumpable(filter.direction)
        end
        return require("luasnip").in_snippet()
      end,
      jump = function(direction)
        require("luasnip").jump(direction)
      end,
    },

    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
      per_filetype = {
        sql = { "snippets", "dadbod", "buffer" },
        mysql = { "snippets", "dadbod", "buffer" },
      },
      providers = {
        dadbod = { name = "Dadbod", module = "vim_dadbod_completion.blink" },
      },
    },

    completion = {
      accept = {
        auto_brackets = {
          enabled = true,
        },
      },

      trigger = {
        show_on_insert_on_trigger_character = false,
      },

      documentation = {
        auto_show = true,
        auto_show_delay_ms = 200,
      },

      menu = {
        draw = {
          treesitter = { "lsp" },
        },
      },
    },

    signature = {
      enabled = true,
    },
  },
  opts_extend = { "sources.default" },
}
