local config = nvim.dofile(nvim.fs.configs)
local lazyconf = nvim.load "lazy"

-----------------------[ SET RUNTIME ]-------------------------------

for _, path in ipairs(nvim.fs.runtime) do
  if not vim.tbl_contains(vim.opt.rtp:get(), path) then
    vim.opt.rtp:prepend(path)
  end
end

------------------------[ LAZY SETUP ]-------------------------------

nvim.lazy = nvim.require "lazy"
nvim.lazy.setup({ { import = "plugins" } }, lazyconf)

-----------------------[ SETUP AFTER ]-------------------------------

nvim.setup.lsp()
nvim.setup.theme()
vim.schedule(config or function() end)
