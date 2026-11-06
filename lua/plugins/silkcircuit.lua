return {
  "GeneralKaos666/silkcircuit",
  lazy = false,
  priority = 1000,
  config = function()
    require("silkcircuit").setup({ variant = "neon" })
  end,
}
