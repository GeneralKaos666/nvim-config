local M = {}

local pickers = {
  telescope = {
    explorer = "file_browser",
    zoxide = "zoxide list",
  },
}

local function keyproxy(tbl)
  tbl = tbl or {} -- optional initial table

  return setmetatable(tbl, {
    __index = function(_, key)
      return key or ""
    end,
  })
end

for key, value in pairs(pickers) do
  pickers[key] = keyproxy(value)
end

function M.picker(name)
  if not name then
    return nvim.plugins.telescope.enabled
  end

  name = pickers.telescope[name]

  if not pcall(nvim.require, "telescope") then
    return
  end
  return vim.cmd("Telescope " .. name)
end

return M
