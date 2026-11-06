local diagnostics_provider = "nvim_diagnostic"

return {
  "diagnostics",
  sources = { diagnostics_provider },
  symbols = {
    error = nvim.icons.diagnostics.Error .. " ",
    warn = nvim.icons.diagnostics.Warn .. " ",
    info = nvim.icons.diagnostics.Info .. " ",
    hint = nvim.icons.diagnostics.Hint .. " ",
  },
  on_click = function()
    nvim.open.picker("diagnostics")
  end,
}
