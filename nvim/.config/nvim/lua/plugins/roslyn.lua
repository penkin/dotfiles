local capabilities = require("blink.cmp").get_lsp_capabilities()
local on_attach = require("blink.cmp").on_attach
local rzls_path = vim.fn.expand("$MASON/packages/rzls/libexec")

local cmd = {
  "roslyn",
  "--stdio",
  "--logLevel=Information",
  "--extensionLogDirectory=" .. vim.fs.dirname(vim.lsp.get_log_path()),
  "--razorSourceGenerator=" .. vim.fs.joinpath(rzls_path, "Microsoft.CodeAnalysis.Razor.Compiler.dll"),
  "--razorDesignTimePath=" .. vim.fs.joinpath(rzls_path, "Targets", "Microsoft.NET.Sdk.Razor.DesignTime.targets"),
  "--extension",
  vim.fs.joinpath(rzls_path, "RazorExtension", "Microsoft.VisualStudioCode.RazorExtension.dll"),
}

return {
  {
    "tris203/rzls.nvim",
    config = function()
      require("rzls").setup({
        on_attach = on_attach,
        capabilities = capabilities,
      })
    end,
  },
  {
    "seblj/roslyn.nvim",
    ft = { "cs", "razor" },
    config = function()
      require("roslyn").setup({
        cmd = cmd,
        config = {
          on_attach = on_attach,
          capabilities = capabilities,
          handlers = require("rzls.roslyn_handlers"),
        },
      })
    end,
    init = function()
      vim.filetype.add({
        extension = {
          razor = "razor",
          cshtml = "razor",
        },
      })
    end,
  },
}
