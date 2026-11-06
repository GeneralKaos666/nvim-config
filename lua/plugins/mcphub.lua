return {
    "ravitemer/mcphub.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
    },
    build = "npm install -g mcp-hub@4.2.1",  -- Pinned global install puts `mcp-hub` on PATH (npm prefix is $PREFIX).
    config = function()
        require("mcphub").setup()
    end
}
