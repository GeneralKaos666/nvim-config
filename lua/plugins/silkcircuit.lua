return {
  "GeneralKaos666/silkcircuit",
  lazy = false,
  priority = 1000,
  config = function()
    require("silkcircuit").setup({ variant = "neon" })
    -- Defer past lazy.setup: the theme's auto-detected integrations
    -- require plugins (e.g. alpha), which must not load before lazy's
    -- LazyDone stat exists (GalaxyVim's alpha dashboard errors otherwise).
    vim.schedule(function()
      vim.cmd.colorscheme("silkcircuit")
    end)
  end,
}
