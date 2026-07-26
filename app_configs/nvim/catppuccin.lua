-- Catppuccin Mocha Neovim Colorscheme
vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") then
  vim.cmd("syntax reset")
end

vim.g.colors_name = "OgsCatppuccin"
vim.o.background = "dark"

local set = vim.api.nvim_set_hl

-- Base UI
set(0, "Normal", { fg = "#cdd6f4", bg = "#1e1e2e" })
set(0, "NormalFloat", { fg = "#cdd6f4", bg = "#181825" })
set(0, "FloatBorder", { fg = "#cba6f7", bg = "#181825" })
set(0, "Cursor", { fg = "#11111b", bg = "#f5e0dc" })
set(0, "CursorLine", { bg = "#313244" })
set(0, "CursorColumn", { bg = "#313244" })
set(0, "ColorColumn", { bg = "#313244" })
set(0, "LineNr", { fg = "#585b70" })
set(0, "CursorLineNr", { fg = "#cba6f7", bold = true })
set(0, "VertSplit", { fg = "#45475a" })
set(0, "WinSeparator", { fg = "#45475a" })
set(0, "StatusLine", { fg = "#cdd6f4", bg = "#181825" })
set(0, "StatusLineNC", { fg = "#6c7086", bg = "#181825" })
set(0, "Visual", { bg = "#585b70" })
set(0, "Search", { fg = "#1e1e2e", bg = "#f9e2af" })
set(0, "IncSearch", { fg = "#1e1e2e", bg = "#f38ba8" })

-- Syntax Highlighting
set(0, "Keyword", { fg = "#cba6f7", bold = true })
set(0, "Statement", { fg = "#cba6f7" })
set(0, "Conditional", { fg = "#cba6f7" })
set(0, "Repeat", { fg = "#cba6f7" })
set(0, "Function", { fg = "#89b4fa" })
set(0, "Identifier", { fg = "#89b4fa" })
set(0, "String", { fg = "#a6e3a1" })
set(0, "Character", { fg = "#a6e3a1" })
set(0, "Number", { fg = "#fab387" })
set(0, "Boolean", { fg = "#fab387" })
set(0, "Float", { fg = "#fab387" })
set(0, "Constant", { fg = "#fab387" })
set(0, "Type", { fg = "#f9e2af" })
set(0, "StorageClass", { fg = "#f9e2af" })
set(0, "Structure", { fg = "#f9e2af" })
set(0, "Typedef", { fg = "#f9e2af" })
set(0, "PreProc", { fg = "#94e2d5" })
set(0, "Include", { fg = "#cba6f7" })
set(0, "Define", { fg = "#cba6f7" })
set(0, "Macro", { fg = "#f38ba8" })
set(0, "Comment", { fg = "#6c7086", italic = true })
set(0, "Special", { fg = "#f5e0dc" })
set(0, "Delimiter", { fg = "#9399b2" })
set(0, "Error", { fg = "#f38ba8", bold = true })
set(0, "Todo", { fg = "#1e1e2e", bg = "#f9e2af", bold = true })
