-- Monochrome High Contrast Neovim Colorscheme
local function apply_theme()
  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
  end

  vim.g.colors_name = "OgsMonochrome"
  vim.o.background = "dark"

  local set = vim.api.nvim_set_hl

  set(0, "Normal", { fg = "#ffffff", bg = "#121212" })
  set(0, "NormalFloat", { fg = "#ffffff", bg = "#0a0a0a" })
  set(0, "FloatBorder", { fg = "#ffffff", bg = "#0a0a0a" })
  set(0, "Cursor", { fg = "#121212", bg = "#ffffff" })
  set(0, "CursorLine", { bg = "#222222" })
  set(0, "CursorColumn", { bg = "#222222" })
  set(0, "ColorColumn", { bg = "#222222" })
  set(0, "LineNr", { fg = "#555555" })
  set(0, "CursorLineNr", { fg = "#ffffff", bold = true })
  set(0, "VertSplit", { fg = "#333333" })
  set(0, "WinSeparator", { fg = "#333333" })
  set(0, "StatusLine", { fg = "#ffffff", bg = "#0a0a0a" })
  set(0, "StatusLineNC", { fg = "#888888", bg = "#0a0a0a" })
  set(0, "Visual", { bg = "#444444" })
  set(0, "Search", { fg = "#121212", bg = "#fbbf24" })
  set(0, "IncSearch", { fg = "#121212", bg = "#f472b6" })

  -- Syntax Colors matching Zed Monochrome Palette
  set(0, "Keyword", { fg = "#f472b6", bold = true })
  set(0, "Statement", { fg = "#f472b6", bold = true })
  set(0, "Conditional", { fg = "#f472b6", bold = true })
  set(0, "Repeat", { fg = "#f472b6", bold = true })
  set(0, "Function", { fg = "#60a5fa" })
  set(0, "Identifier", { fg = "#e2e8f0" })
  set(0, "String", { fg = "#4ade80" })
  set(0, "Character", { fg = "#4ade80" })
  set(0, "Number", { fg = "#fbbf24" })
  set(0, "Boolean", { fg = "#fbbf24" })
  set(0, "Float", { fg = "#fbbf24" })
  set(0, "Constant", { fg = "#f472b6" })
  set(0, "Type", { fg = "#38bdf8" })
  set(0, "StorageClass", { fg = "#38bdf8" })
  set(0, "Structure", { fg = "#38bdf8" })
  set(0, "Typedef", { fg = "#38bdf8" })
  set(0, "PreProc", { fg = "#f472b6" })
  set(0, "Include", { fg = "#f472b6" })
  set(0, "Define", { fg = "#f472b6" })
  set(0, "Macro", { fg = "#f472b6" })
  set(0, "Comment", { fg = "#64748b", italic = true })
  set(0, "Special", { fg = "#e2e8f0" })
  set(0, "Delimiter", { fg = "#94a3b8" })
  set(0, "Error", { fg = "#f87171", bold = true })
  set(0, "Todo", { fg = "#121212", bg = "#fbbf24", bold = true })
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
