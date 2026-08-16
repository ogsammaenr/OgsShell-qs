-- Tokyo Night Neovim Colorscheme
local function apply_theme()
  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
  end

  vim.g.colors_name = "OgsTokyoNight"
  vim.o.background = "dark"

  local set = vim.api.nvim_set_hl

  set(0, "Normal", { fg = "#c0caf5", bg = "#1a1b26" })
  set(0, "NormalFloat", { fg = "#c0caf5", bg = "#16161e" })
  set(0, "FloatBorder", { fg = "#7aa2f7", bg = "#16161e" })
  set(0, "Cursor", { fg = "#1a1b26", bg = "#c0caf5" })
  set(0, "CursorLine", { bg = "#292e42" })
  set(0, "CursorColumn", { bg = "#292e42" })
  set(0, "ColorColumn", { bg = "#292e42" })
  set(0, "LineNr", { fg = "#3b4261" })
  set(0, "CursorLineNr", { fg = "#7aa2f7", bold = true })
  set(0, "VertSplit", { fg = "#292e42" })
  set(0, "WinSeparator", { fg = "#292e42" })
  set(0, "StatusLine", { fg = "#c0caf5", bg = "#16161e" })
  set(0, "StatusLineNC", { fg = "#565f89", bg = "#16161e" })
  set(0, "Visual", { bg = "#33467c" })
  set(0, "Search", { fg = "#1a1b26", bg = "#e0af68" })
  set(0, "IncSearch", { fg = "#1a1b26", bg = "#f7768e" })

  set(0, "Keyword", { fg = "#bb9af7", bold = true })
  set(0, "Statement", { fg = "#bb9af7" })
  set(0, "Conditional", { fg = "#bb9af7" })
  set(0, "Repeat", { fg = "#bb9af7" })
  set(0, "Function", { fg = "#7aa2f7" })
  set(0, "Identifier", { fg = "#7aa2f7" })
  set(0, "String", { fg = "#9ece6a" })
  set(0, "Character", { fg = "#9ece6a" })
  set(0, "Number", { fg = "#ff9e64" })
  set(0, "Boolean", { fg = "#ff9e64" })
  set(0, "Float", { fg = "#ff9e64" })
  set(0, "Constant", { fg = "#ff9e64" })
  set(0, "Type", { fg = "#2ac3de" })
  set(0, "StorageClass", { fg = "#2ac3de" })
  set(0, "Structure", { fg = "#2ac3de" })
  set(0, "Typedef", { fg = "#2ac3de" })
  set(0, "PreProc", { fg = "#7dcfff" })
  set(0, "Include", { fg = "#7aa2f7" })
  set(0, "Define", { fg = "#7aa2f7" })
  set(0, "Macro", { fg = "#f7768e" })
  set(0, "Comment", { fg = "#565f89", italic = true })
  set(0, "Special", { fg = "#7dcfff" })
  set(0, "Delimiter", { fg = "#89ddff" })
  set(0, "Error", { fg = "#f7768e", bold = true })
  set(0, "Todo", { fg = "#1a1b26", bg = "#e0af68", bold = true })
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
