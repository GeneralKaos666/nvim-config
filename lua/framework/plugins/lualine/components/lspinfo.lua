local function nvim_lsp()
  local clients = vim.lsp.get_clients { bufnr = 0 }
  if #clients == 0 then
    return ""
  end

  local names = {}
  for _, client in ipairs(clients) do
    table.insert(names, client.name)
  end

  local count = #names
  local list = table.concat(names, "|")

  return count, list
end

return {
  function()
    local case = nvim.opt.style.lualine.component.lsp
    local count, names, show
    count, names = nvim_lsp()

    if case == "count" then
      show = count
    elseif case == "name" then
      show = names
    end

    return count > 0 and "󰆧 " .. nvim.hl.format("lualine_c_normal", show) or ""
  end,

  color = function()
    return {
      fg = nvim.hl.lualine_a_visual.bg,
      gui = "bold",
    }
  end,

  on_click = function()
    vim.cmd.checkhealth "vim.lsp"
  end,
}
