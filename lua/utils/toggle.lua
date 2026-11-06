local M = {}

local wins = {}

function M.float(name, args)
  local win = wins[name]

  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
    wins[name] = nil
  else
    vim.cmd[name](args)
    wins[name] = vim.api.nvim_get_current_win()
  end
end

function M.notify(text, cond)
  vim.notify(string.format("%s: %s", text, cond and "ON" or "OFF"))
end

function M.background()
  local bg = vim.o.background
  vim.o.background = bg == "dark" and "light" or "dark"
  vim.notify(string.format("Background switched to '%s'", vim.opt.background:get()), vim.log.levels.INFO)
end

-- helper opt toggle function
function M.opt(opt, name)
  local value = not vim.opt[opt]:get()
  vim.opt[opt] = value
  M.notify(name, value)
end

function M.wrap()
  vim.wo.wrap = not vim.wo.wrap
  vim.wo.linebreak = vim.wo.wrap
  vim.wo.breakindent = vim.wo.wrap
end

-- Toggle signcolumn
function M.signcolumn()
  if vim.wo.signcolumn == "no" then
    vim.wo.signcolumn = "yes"
  else
    vim.wo.signcolumn = "no"
  end
  vim.notify("Signcolumn:", vim.wo.signcolumn)
end

-- Toggle statusline
function M.statusline()
  if vim.o.laststatus == 0 then
    vim.o.laststatus = 3
  else
    vim.o.laststatus = 0
  end
  print("Statusline:", vim.o.laststatus)
end

-- Toggle statuscolumn
function M.statuscolumn()
  local value
  if vim.o.statuscolumn == "" then
    vim.o.statuscolumn = "%!v:lua.statuscol()"
    value = true
  else
    vim.o.statuscolumn = ""
    value = false
  end
  M.notify("Statuscolumn:", value)
end

-- Toggle tabline
function M.tabline()
  if vim.o.showtabline == 0 then
    vim.o.showtabline = 2
  else
    vim.o.showtabline = 0
  end
  print("Tabline:", vim.o.showtabline)
end

function M.autosave()
  nvim.opt.auto.save = not nvim.opt.auto.save
  M.notify("Autosave", nvim.opt.auto.save)
end

vim.b.gitdiff = true
function M.gitdiff()
  vim.b.gitdiff = not vim.b.gitdiff
  if vim.b.gitdiff then
    vim.cmd.DiffviewClose()
  else
    vim.cmd.DiffviewOpen()
    vim.cmd.DiffviewToggleFiles()
  end
end

------------------------[ Treesitter ]-------------------------------

--------------------------------------------------
-- Global Highlight Toggle
--------------------------------------------------

local ts_highlight = true
function M.ts_highlight()
  ts_highlight = not ts_highlight
  if ts_highlight then
    vim.treesitter.stop()
  else
    vim.treesitter.start()
  end
  M.notify("Treesitter Highlight", ts_highlight)
end

--------------------------------------------------
-- Global Context Toggle
--------------------------------------------------

local ts_context = true
function M.ts_context()
  ts_context = not ts_context
  vim.cmd "TSContext toggle"
  M.notify("Treesitter Context", ts_context)
end

local lsp = {}

function lsp.notify(text, cond)
  vim.notify(string.format("%s: %s", text, cond and "ON" or "OFF"))
end

---------------------------[ LSP ]-------------------------------

--------------------------------------------------
-- Formatter Toggle
--------------------------------------------------

function lsp.format_on_save()
  vim.g.format_on_save = not vim.g.format_on_save
  vim.notify("Format on save: " .. (vim.g.format_on_save and "ON" or "OFF"))
end

--------------------------------------------------
-- Inlay Hints Toggle
--------------------------------------------------
function lsp.inlay()
  local enabled = vim.lsp.inlay_hint.is_enabled()
  vim.lsp.inlay_hint.enable(not enabled)
  lsp.notify("Inlay Hints", not enabled)
end

--------------------------------------------------
-- Diagnostics Toggle
--------------------------------------------------
local diagnostics_active = true
function lsp.diagnostics()
  diagnostics_active = not diagnostics_active
  if diagnostics_active then
    vim.diagnostic.enable()
  else
    vim.diagnostic.disable()
  end
  lsp.notify("Diagnostics", diagnostics_active)
end

--------------------------------------------------
-- Virtual Text Toggle
--------------------------------------------------
local virtual_text = true
function lsp.virtual_text()
  virtual_text = not virtual_text
  vim.diagnostic.config {
    virtual_text = virtual_text,
  }
  lsp.notify("Virtual Text", virtual_text)
end

--------------------------------------------------
-- Semantic Tokens Toggle
--------------------------------------------------
local semantic = true
function lsp.semantic_tokens()
  semantic = not semantic

  for _, client in ipairs(vim.lsp.get_active_clients()) do
    if client.server_capabilities.semanticTokensProvider then
      client.server_capabilities.semanticTokensProvider = semantic and client.server_capabilities.semanticTokensProvider
        or nil
    end
  end

  vim.cmd "edit" -- refresh highlight
  lsp.notify("Semantic Tokens", semantic)
end

--------------------------------------------------
-- Codelens Toggle
--------------------------------------------------
local codelens = true
function lsp.codelens()
  codelens = not codelens
  if codelens then
    vim.lsp.codelens.refresh()
  else
    vim.lsp.codelens.clear()
  end
  lsp.notify("CodeLens", codelens)
end

M.lsp = lsp

return M
