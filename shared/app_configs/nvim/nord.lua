-- Nord Neovim Colorscheme
local function apply_theme()
  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
  end

  vim.g.colors_name = "OgsNord"
  vim.o.background = "dark"

  local set = vim.api.nvim_set_hl

  set(0, "Normal", { fg = "#d8dee9", bg = "#2e3440" })
  set(0, "NormalFloat", { fg = "#d8dee9", bg = "#272c36" })
  set(0, "FloatBorder", { fg = "#88c0d0", bg = "#272c36" })
  set(0, "Cursor", { fg = "#2e3440", bg = "#d8dee9" })
  set(0, "CursorLine", { bg = "#3b4252" })
  set(0, "CursorColumn", { bg = "#3b4252" })
  set(0, "ColorColumn", { bg = "#3b4252" })
  set(0, "LineNr", { fg = "#4c566a" })
  set(0, "CursorLineNr", { fg = "#88c0d0", bold = true })
  set(0, "VertSplit", { fg = "#4c566a" })
  set(0, "WinSeparator", { fg = "#4c566a" })
  set(0, "StatusLine", { fg = "#d8dee9", bg = "#272c36" })
  set(0, "StatusLineNC", { fg = "#4c566a", bg = "#272c36" })
  set(0, "Visual", { bg = "#4c566a" })
  set(0, "Search", { fg = "#2e3440", bg = "#ebcb8b" })
  set(0, "IncSearch", { fg = "#2e3440", bg = "#bf616a" })

  set(0, "Keyword", { fg = "#81a1c1", bold = true })
  set(0, "Statement", { fg = "#81a1c1" })
  set(0, "Conditional", { fg = "#81a1c1" })
  set(0, "Repeat", { fg = "#81a1c1" })
  set(0, "Function", { fg = "#88c0d0" })
  set(0, "Identifier", { fg = "#88c0d0" })
  set(0, "String", { fg = "#a3be8c" })
  set(0, "Character", { fg = "#a3be8c" })
  set(0, "Number", { fg = "#b48ead" })
  set(0, "Boolean", { fg = "#b48ead" })
  set(0, "Float", { fg = "#b48ead" })
  set(0, "Constant", { fg = "#b48ead" })
  set(0, "Type", { fg = "#8fbcbb" })
  set(0, "StorageClass", { fg = "#8fbcbb" })
  set(0, "Structure", { fg = "#8fbcbb" })
  set(0, "Typedef", { fg = "#8fbcbb" })
  set(0, "PreProc", { fg = "#81a1c1" })
  set(0, "Include", { fg = "#81a1c1" })
  set(0, "Define", { fg = "#81a1c1" })
  set(0, "Macro", { fg = "#bf616a" })
  set(0, "Comment", { fg = "#616e88", italic = true })
  set(0, "Special", { fg = "#d8dee9" })
  set(0, "Delimiter", { fg = "#d8dee9" })
  set(0, "Error", { fg = "#bf616a", bold = true })
  set(0, "Todo", { fg = "#2e3440", bg = "#ebcb8b", bold = true })
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
