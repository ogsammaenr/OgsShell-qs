-- Gruvbox Dark Neovim Colorscheme
local function apply_theme()
  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
  end

  vim.g.colors_name = "OgsGruvbox"
  vim.o.background = "dark"

  local set = vim.api.nvim_set_hl

  set(0, "Normal", { fg = "#fbf1c7", bg = "#282828" })
  set(0, "NormalFloat", { fg = "#fbf1c7", bg = "#1d2021" })
  set(0, "FloatBorder", { fg = "#fabd2f", bg = "#1d2021" })
  set(0, "Cursor", { fg = "#282828", bg = "#fbf1c7" })
  set(0, "CursorLine", { bg = "#3c3836" })
  set(0, "CursorColumn", { bg = "#3c3836" })
  set(0, "ColorColumn", { bg = "#3c3836" })
  set(0, "LineNr", { fg = "#665c54" })
  set(0, "CursorLineNr", { fg = "#fabd2f", bold = true })
  set(0, "VertSplit", { fg = "#3c3836" })
  set(0, "WinSeparator", { fg = "#3c3836" })
  set(0, "StatusLine", { fg = "#fbf1c7", bg = "#1d2021" })
  set(0, "StatusLineNC", { fg = "#a89984", bg = "#1d2021" })
  set(0, "Visual", { bg = "#504945" })
  set(0, "Search", { fg = "#282828", bg = "#fabd2f" })
  set(0, "IncSearch", { fg = "#282828", bg = "#fb4934" })

  set(0, "Keyword", { fg = "#fb4934", bold = true })
  set(0, "Statement", { fg = "#fb4934" })
  set(0, "Conditional", { fg = "#fb4934" })
  set(0, "Repeat", { fg = "#fb4934" })
  set(0, "Function", { fg = "#83a598" })
  set(0, "Identifier", { fg = "#83a598" })
  set(0, "String", { fg = "#b8bb26" })
  set(0, "Character", { fg = "#b8bb26" })
  set(0, "Number", { fg = "#d3869b" })
  set(0, "Boolean", { fg = "#d3869b" })
  set(0, "Float", { fg = "#d3869b" })
  set(0, "Constant", { fg = "#d3869b" })
  set(0, "Type", { fg = "#fabd2f" })
  set(0, "StorageClass", { fg = "#fabd2f" })
  set(0, "Structure", { fg = "#fabd2f" })
  set(0, "Typedef", { fg = "#fabd2f" })
  set(0, "PreProc", { fg = "#8ec07c" })
  set(0, "Include", { fg = "#83a598" })
  set(0, "Define", { fg = "#83a598" })
  set(0, "Macro", { fg = "#fb4934" })
  set(0, "Comment", { fg = "#928374", italic = true })
  set(0, "Special", { fg = "#fe8019" })
  set(0, "Delimiter", { fg = "#fbf1c7" })
  set(0, "Error", { fg = "#fb4934", bold = true })
  set(0, "Todo", { fg = "#282828", bg = "#fabd2f", bold = true })
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
