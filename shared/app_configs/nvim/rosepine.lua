-- Rosé Pine Neovim Colorscheme
local function apply_theme()
  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
  end

  vim.g.colors_name = "OgsRosePine"
  vim.o.background = "dark"

  local set = vim.api.nvim_set_hl

  -- Base UI
  set(0, "Normal", { fg = "#e0def4", bg = "#191724" })
  set(0, "NormalFloat", { fg = "#e0def4", bg = "#1f1d2e" })
  set(0, "FloatBorder", { fg = "#ebbcba", bg = "#1f1d2e" })
  set(0, "Cursor", { fg = "#191724", bg = "#524f67" })
  set(0, "CursorLine", { bg = "#21202e" })
  set(0, "CursorColumn", { bg = "#21202e" })
  set(0, "ColorColumn", { bg = "#21202e" })
  set(0, "LineNr", { fg = "#6e6a86" })
  set(0, "CursorLineNr", { fg = "#ebbcba", bold = true })
  set(0, "VertSplit", { fg = "#26233a" })
  set(0, "WinSeparator", { fg = "#26233a" })
  set(0, "StatusLine", { fg = "#e0def4", bg = "#1f1d2e" })
  set(0, "StatusLineNC", { fg = "#6e6a86", bg = "#1f1d2e" })
  set(0, "Visual", { bg = "#403d52" })
  set(0, "Search", { fg = "#191724", bg = "#f6c177" })
  set(0, "IncSearch", { fg = "#191724", bg = "#eb6f92" })

  -- Syntax Highlighting
  set(0, "Keyword", { fg = "#31748f", bold = true })
  set(0, "Statement", { fg = "#31748f" })
  set(0, "Conditional", { fg = "#31748f" })
  set(0, "Repeat", { fg = "#31748f" })
  set(0, "Function", { fg = "#ebbcba" })
  set(0, "Identifier", { fg = "#ebbcba" })
  set(0, "String", { fg = "#f6c177" })
  set(0, "Character", { fg = "#f6c177" })
  set(0, "Number", { fg = "#eb6f92" })
  set(0, "Boolean", { fg = "#eb6f92" })
  set(0, "Float", { fg = "#eb6f92" })
  set(0, "Constant", { fg = "#eb6f92" })
  set(0, "Type", { fg = "#9ccfd8" })
  set(0, "StorageClass", { fg = "#9ccfd8" })
  set(0, "Structure", { fg = "#9ccfd8" })
  set(0, "Typedef", { fg = "#9ccfd8" })
  set(0, "PreProc", { fg = "#c4a7e7" })
  set(0, "Include", { fg = "#31748f" })
  set(0, "Define", { fg = "#31748f" })
  set(0, "Macro", { fg = "#eb6f92" })
  set(0, "Comment", { fg = "#6e6a86", italic = true })
  set(0, "Special", { fg = "#c4a7e7" })
  set(0, "Delimiter", { fg = "#908caa" })
  set(0, "Error", { fg = "#eb6f92", bold = true })
  set(0, "Todo", { fg = "#191724", bg = "#f6c177", bold = true })
end

apply_theme()

return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        apply_theme()
      end,
    },
  },
}
