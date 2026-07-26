-- Everforest Dark Hard Neovim Colorscheme
vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") then
  vim.cmd("syntax reset")
end

vim.g.colors_name = "OgsEverforest"
vim.o.background = "dark"

local set = vim.api.nvim_set_hl

set(0, "Normal", { fg = "#d3c6aa", bg = "#2d353b" })
set(0, "NormalFloat", { fg = "#d3c6aa", bg = "#232a2e" })
set(0, "FloatBorder", { fg = "#a7c080", bg = "#232a2e" })
set(0, "Cursor", { fg = "#2d353b", bg = "#d3c6aa" })
set(0, "CursorLine", { bg = "#343f44" })
set(0, "CursorColumn", { bg = "#343f44" })
set(0, "ColorColumn", { bg = "#343f44" })
set(0, "LineNr", { fg = "#475258" })
set(0, "CursorLineNr", { fg = "#a7c080", bold = true })
set(0, "VertSplit", { fg = "#475258" })
set(0, "WinSeparator", { fg = "#475258" })
set(0, "StatusLine", { fg = "#d3c6aa", bg = "#232a2e" })
set(0, "StatusLineNC", { fg = "#859289", bg = "#232a2e" })
set(0, "Visual", { bg = "#504945" })
set(0, "Search", { fg = "#2d353b", bg = "#dbbc7f" })
set(0, "IncSearch", { fg = "#2d353b", bg = "#e67e80" })

set(0, "Keyword", { fg = "#e67e80", bold = true })
set(0, "Statement", { fg = "#e67e80" })
set(0, "Conditional", { fg = "#e67e80" })
set(0, "Repeat", { fg = "#e67e80" })
set(0, "Function", { fg = "#a7c080" })
set(0, "Identifier", { fg = "#a7c080" })
set(0, "String", { fg = "#dbbc7f" })
set(0, "Character", { fg = "#dbbc7f" })
set(0, "Number", { fg = "#d699b6" })
set(0, "Boolean", { fg = "#d699b6" })
set(0, "Float", { fg = "#d699b6" })
set(0, "Constant", { fg = "#d699b6" })
set(0, "Type", { fg = "#7fbbb3" })
set(0, "StorageClass", { fg = "#7fbbb3" })
set(0, "Structure", { fg = "#7fbbb3" })
set(0, "Typedef", { fg = "#7fbbb3" })
set(0, "PreProc", { fg = "#83c092" })
set(0, "Include", { fg = "#a7c080" })
set(0, "Define", { fg = "#a7c080" })
set(0, "Macro", { fg = "#e67e80" })
set(0, "Comment", { fg = "#859289", italic = true })
set(0, "Special", { fg = "#d3c6aa" })
set(0, "Delimiter", { fg = "#d3c6aa" })
set(0, "Error", { fg = "#e67e80", bold = true })
set(0, "Todo", { fg = "#2d353b", bg = "#dbbc7f", bold = true })
