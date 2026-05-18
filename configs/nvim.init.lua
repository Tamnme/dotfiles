-- Minimal nvim init — extend freely.

-- Sync all yank/delete/change with macOS system clipboard.
-- Lets `y` in visual mode put text in pasteboard usable by Cmd+V elsewhere.
vim.opt.clipboard = "unnamedplus"
