-- Shared installer splash. Pure `vim.api` — no `nvim` global required,
-- so root `init.lua` can use it before the framework boots.
local M = {}

function M.float(msg)
  local text = {
    " ",
    "  " .. msg,
    " ",
    "  Please wait...",
    " ",
  }

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, text)

  local width = math.max(20, vim.o.columns - 4)
  local height = math.max(5, vim.o.lines - 4)
  local win = vim.api.nvim_open_win(buf, false, {
    width = width,
    height = height,
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

return M
