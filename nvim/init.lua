vim.g.galaxypath = vim.fn.stdpath("data") .. "/galaxyvim"

-- Shared splash helper (config-side, no framework dependency).
-- Falls back to inline copy if the helper is unavailable.
local float
do
  local ok, mod = pcall(require, "galaxy.utils.ui.float")
  if ok and type(mod.float) == "function" then
    float = mod.float
  else
    float = function(msg)
	local text = {
		" ",
		"  " .. msg,
		" ",
		"  Please wait...",
		" ",
	}

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, text)

	local win = vim.api.nvim_open_win(buf, false, {
		width = math.max(20, vim.o.columns - 4),
		height = math.max(5, vim.o.lines - 4),
		style = "minimal",
		border = "rounded",
		relative = "editor",
		row = 1,
		col = 1,
	})

	vim.wo[win].winhl = "NormalFloat:Normal,FloatBorder:DiagnosticHint"
	vim.cmd("redraw")
	return win, buf
  end
  end
end

if not (vim.uv or vim.loop).fs_stat(vim.g.galaxypath) then
	local win = float("Installing galaxyvim...")
	local process = vim.fn.system({ "git", "clone", "https://github.com/galaxyvim/galaxyvim", vim.g.galaxypath })

	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to install galaxyvim:\n", "ErrorMsg" },
			{ process, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end

	if vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_close(win, true)
	end
end

vim.opt.rtp:prepend(vim.g.galaxypath)
local ok, err = pcall(require, "galaxy")

if not ok then
	vim.notify(err, vim.log.levels.ERROR)
end
