-- NOTE(2026-09-25): `bootstrap.lua` uses `import="plugins"` so every
-- `lua/plugins/*.lua` is a standalone lazy spec. This `init.lua`'s
-- galaxy-based builder is legacy/duplicative — see plan for removal
-- proposal. Do not add new user specs here; add `lua/plugins/<name>.lua`.
local enabled = require("galaxy.configure.plugins")
local setup = require("galaxy.utils.setup")

nvim.plugins = nvim.lazytable()
nvim.dofile(nvim.fs.presets)

local plugins = {}
for name, cond in pairs(enabled) do
  local module = "galaxy.plugins." .. name
  local ok, plugin = pcall(require, module)
  local plugname = name:gsub("-", "_")
  if ok then
    local spec = setup.plugin(name, plugin.config(), cond)
    nvim.plugins[plugname] = spec
    plugins[plugname] = spec
  else
    vim.notify(("Failed to load plugin config: %s"):format(name), vim.log.levels.WARN)
  end
end

for _, plugin in pairs(plugins) do
  if type(plugin.dependencies) == "table" then
    plugin.dependencies = vim.tbl_values(plugin.dependencies)
  end
end

local specs = vim.tbl_values(nvim.materialize(plugins))
return specs
