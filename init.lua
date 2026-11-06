require("core")

-- Expose nvim-treesitter's bundled highlight queries on the runtimepath.
-- The plugin ships them under its own `runtime/queries/` directory, which
-- lazy.nvim does not surface (only a few languages get symlinked into the
-- install dir). Without this, filetypes whose language isn't in the
-- treesitter install list (e.g. python, zsh) get no syntax highlighting.
local ts_runtime = vim.fn.stdpath("data") .. "/site/pack/lazy/treesitter/runtime"
if vim.fn.isdirectory(ts_runtime) == 1 and not vim.tbl_contains(vim.opt.rtp:get(), ts_runtime) then
	vim.opt.rtp:append(ts_runtime)
end
