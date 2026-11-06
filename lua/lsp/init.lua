local lsp = nvim.load "lsp.nvim"
local coc = nvim.load "lsp.coc"

local keys = { "gaa", "gal", "gan", "gaw", "grn", "gra", "grr", "grt", "gri", "grd", "grx" }
for _, k in ipairs(keys) do
  pcall(vim.keymap.del, "n", k)
end

nvim.lsp, nvim.coc = lsp, coc

