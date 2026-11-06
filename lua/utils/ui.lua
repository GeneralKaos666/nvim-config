local M = {}

function M.notify(text, cond)
  vim.notify(string.format("%s: %s", text, cond and "ON" or "OFF"))
end

function M.vpaste()
  local reg = vim.fn.getreg '"' -- save current default register
  local regtype = vim.fn.getregtype '"' -- save register type
  vim.cmd 'silent normal! "_dP' -- delete selection + paste from default register
  -- restore default register
  vim.fn.setreg('"', reg, regtype)
end

function M.format()
  local ok, conform = pcall(require, "conform")
  if ok then
    conform.format {
      async = true,
      lsp_fallback = true,
    }
  else
    vim.lsp.buf.format()
  end
end

function M.stop_all_lsp()
  for _, client in ipairs(vim.lsp.get_active_clients()) do
    client.stop()
  end
end

local notify = function(msg)
  vim.notify(msg, vim.log.levels.INFO, { title = "UI" })
end

-- Background
function M.background()
  local bg = vim.opt.background:get()
  notify("Background: " .. bg)
end

-- Reload highlights
function M.reload_highlights()
  vim.cmd "hi clear"
  vim.cmd "syntax reset"
  vim.cmd.colorscheme(nvim.colorscheme)
  notify "Highlights reloaded"
end

-- Reset highlights
function M.clear_highlights()
  vim.cmd "hi clear"
  vim.cmd "syntax reset"
  notify "Highlights cleared"
end

-- Window UI
function M.window()
  notify("winblend: " .. vim.o.winblend)
end

-- Popup menu
function M.popup()
  notify("pumblend: " .. vim.o.pumblend)
end

-- Statusline
function M.statusline()
  notify(vim.o.laststatus == 0 and "Statusline hidden" or "Statusline visible")
end

local transparency = {}

local t_notify = function(msg)
  vim.notify(msg, vim.log.levels.INFO, { title = "UI" })
end

-- Transparency
local function step()
  return vim.v.count > 0 and vim.v.count or 5
end

local function clamp(v)
  return math.max(0, math.min(100, v))
end

local function change(kind, delta)
  nvim.opt.transparency[kind] = clamp(nvim.opt.transparency[kind] + delta)
  vim.notify(
    ("Transparency → float:%d popup:%d ui:%d"):format(
      nvim.opt.transparency.float,
      nvim.opt.transparency.popup,
      nvim.opt.transparency.ui
    ),
    vim.log.levels.INFO,
    { title = "UI Transparency" }
  )
end

function transparency.float_inc()
  change("float", step())
end
function transparency.float_dec()
  change("float", -step())
end
function transparency.float_reset()
  nvim.opt.transparency.float = 0
end

function transparency.popup_inc()
  change("popup", step())
end
function transparency.popup_dec()
  change("popup", -step())
end
function transparency.popup_reset()
  nvim.opt.transparency.popup = 10
end

function transparency.ui_inc()
  change("ui", step())
end
function transparency.ui_dec()
  change("ui", -step())
end
function transparency.ui_reset()
  nvim.opt.transparency.ui = 0
end

function transparency.reset()
  nvim.opt.transparency = {
    float = 0,
    popup = 10,
    ui = 0,
  }

  t_notify "Transparency reset"
end

M.transparency = transparency

local float = {}

function float.float(msg)
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

M.float = float

local function GetVisPos()
  -- Get the "live" positions
  local pos1 = vim.fn.getpos "v" -- Where you started selecting
  local pos2 = vim.fn.getpos "." -- Where your cursor is right now

  return pos1, pos2
end

local function normalize_pos(a, b)
  if a[2] > b[2] or (a[2] == b[2] and a[3] > b[3]) then
    return b, a
  end
  return a, b
end

local function GetVisCoordinate()
  local pos1, pos2 = normalize_pos(GetVisPos())

  local start_row = pos1[2] - 1
  local start_col = pos1[3] - 1
  local end_row = pos2[2] - 1
  local end_col = pos2[3] - 1

  return start_row, start_col, end_row, end_col
end

function CapLastVis()
  vim.cmd 'normal! gv"xy'
  local txt = vim.fn.getreg "x"
  local tbl = {}
  for line in txt:gmatch "[^\n]+" do
    table.insert(tbl, line)
  end
  return tbl
end

local function CapLiveVis()
  local pos1, pos2 = GetVisPos()
  -- Get the current mode (v, V, or <C-v>)
  local mode = vim.fn.mode()

  -- Grab the selected region text
  -- getregion handles it perfectly even if pos2 is "before" pos1
  local lines = vim.fn.getregion(pos1, pos2, { type = mode })

  -- Debug: See the result in the messages (:messages)
  local text = table.concat(lines, "\n")
  return text
end

local function replace_buffer(text)
  -- get current buffer
  local buf = vim.api.nvim_get_current_buf()

  -- split text into lines (required format)

  local lines = vim.split(text, "\n", { plain = true })

  -- replace all lines in buffer
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

local function replace_visual(text)
  local srow, scol, erow, ecol = GetVisCoordinate()
  local mode = vim.fn.mode()

  -- getregion handles it perfectly even if pos2 is "before" pos1
  -- local lines = vim.fn.getregion(pos1, pos2, { type = mode })

  local lines = vim.split(text, "\n", { plain = true })
  vim.api.nvim_buf_set_text(0, srow, scol, erow, ecol, lines)
end

local function returnCase(text)
  local result
  if text:match "^%l+$" then
    result = text:upper()
  elseif text:match "^%u+$" then
    result = text:lower()
  elseif text:match "^%u%l+$" then
    result = text:lower()
  else
    result = text:upper()
  end

  return result
end

local function smartcase()
  local mode = vim.fn.mode()

  if mode:match "[vV]" then
    local text = CapLiveVis()

    replace_visual(returnCase(text))

    -- vim.cmd('normal! gU')
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
    return
  end

  local word = vim.fn.expand "<cword>"
  if word == "" then
    return
  end

  if word:match "^%l+$" then
    vim.cmd "normal! gUiw"
  elseif word:match "^%u+$" then
    vim.cmd "normal! guiw"
  elseif word:match "^%u%l+$" then
    vim.cmd "normal! guiw"
  else
    local fixed = word:lower():gsub("^%l", string.upper)
    vim.cmd("normal! ciw" .. fixed)
  end
end

M.smartcase = smartcase

return M
