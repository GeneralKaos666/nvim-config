# Unify the Neovim config

**Date:** 2026-11-06
**Branch:** `refactor/flat-config`
**Repo:** `~/repos/nvim-config` (also the live `~/.config/nvim` via symlink)

## Goal

Remove every dormant alternative and duplicated helper from the flattened
config, then collapse the remaining directory tree one level so no module or
plugin has two competing definitions. End state: one completion engine, one LSP
provider, one colorscheme, one `lazytable`, and a directory layout where each
thing lives in exactly one place.

## Non-goals

- Do not convert the plugin factories into plain lazy specs. Factories stay
  modules that return `M` with an `M.config()` function.
- Do not change which plugins are enabled beyond the three dormant alternatives.
- Do not touch `LICENSE`, the galaxyvim credit in `README.md`, or the
  screenshots.
- No force-push; GPG-sign every commit.

## Background

The config was flattened from the vendored galaxyvim framework in an earlier
task. That flatten preserved the framework's internal structure, which still
carries alternatives that are now dead code behind a `provider` switch:

- Completion: `nvim-cmp` (active) vs `blink-cmp` (disabled by
  `nvim.opt.provider.cmp == "blink-cmp"`).
- LSP: native `lsp/nvim` (active) vs `lsp/coc` and the `coc` factory (disabled by
  `nvim.opt.provider.lsp == "coc"`).
- Colorscheme: `silkcircuit` (active) vs `pastel` factory (still enabled in
  `configure/plugins.lua`, unused).
- Helper: `lazytable` defined in both `utils/init.lua` and `utils/open.lua`.

## Decisions

1. **Delete, don't keep-as-switch.** The dormant alternatives are removed
   outright; the `provider` switch table is deleted and the active choice is
   hardcoded.
2. **Factories stay out of lazy's import path.** `lua/framework/plugins/` is
   renamed to `lua/factories/`. `lazy.nvim` imports `plugins`, so factories must
   never live under `lua/plugins/`.
3. **Flatten `lsp` and `utils` subdirectories into single-level files**, merging
   the small autoloaded submodules by hand.

## Changes

### 3.1 Deletions

Remove these files/directories:

- `lua/framework/plugins/blink-cmp.lua`
- `lua/framework/plugins/coc.lua`
- `lua/framework/plugins/pastel.lua`
- `lua/lsp/coc/` (entire directory)
- `lua/mappings/whichkey/coc.lua`

Also drop the matching entries from `lua/lazyconf/lockfile.json`: `coc`,
`pastel`, `blink.cmp`. Stale lockfile entries are harmless at runtime but must
not reference removed plugins.

### 3.2 Remove the `provider` switch, hardcode active choice

Delete the `nvim.opt.provider = { picker = ..., cmp = ..., lsp = ... }` block
from `lua/configure/settings.lua`.

- **LSP = native:**
  - `lua/utils/setup.lua`: drop the `coc` branch in the LSP setup dispatcher;
    keep only the native path.
  - `lua/lsp/init.lua`: no longer `nvim.load "lsp.coc"`; `nvim.coc` is gone.
  - `lua/framework/plugins/bufferline.lua`: `diagnostics_provider` is always
    `"nvim_lsp"`.
  - `lua/framework/plugins/autopairs.lua`: `map_cr = true` unconditionally.
  - `lua/framework/plugins/mason.lua`: `enabled = true` unconditionally.
  - `lua/framework/plugins/lualine/components/diagnostics.lua`: remove the `coc`
    branch.
  - `lua/framework/plugins/lualine/components/lspinfo.lua`: remove the
    `coc_lsp()` function and its branch; keep the native count.
- **Completion = nvim-cmp:**
  - `lua/framework/plugins/nvim-cmp/init.lua`: `enabled = true` (drop the
    `provider.lsp == "nvim" and provider.cmp == "nvim-cmp"` guard).
- **Picker = telescope:**
  - `lua/utils/open.lua`: hardcode the `telescope` case.
  - `lua/framework/plugins/alpha/styles/dashboard.lua`: bookmarks module is
    `factories.telescope.pickers.bookmarks`.
  - `lua/mappings/whichkey/bookmark.lua`: same hardcoded telescope module.
  - `lua/framework/plugins/neogit.lua`: `telescope = true`, `snacks = false`.

`silkcircuit` stays the colorscheme; `nvim.colorscheme = "silkcircuit"` is
unchanged.

### 3.3 Flatten the directories

- `lua/framework/plugins/` → `lua/factories/` (move only; 50 remaining factories).
- `lua/lsp/nvim/init.lua` → `lua/lsp/init.lua` (replaces the dispatcher).
- `lua/lsp/nvim/inlayhint.lua` → `lua/lsp/inlayhint.lua`.
- `lua/lsp/nvim/progress.lua` → `lua/lsp/progress.lua`.
- `lua/lsp/nvim/provider.lua` → `lua/lsp/provider.lua`.
- `lua/utils/toggle/init.lua` + `lua/utils/toggle/lsp.lua` → one
  `lua/utils/toggle.lua`; the `lsp.lua` functions are inlined under `M.lsp` so
  `nvim.toggle.lsp.*` keeps working.
- `lua/utils/ui/init.lua` + `float.lua` + `smartcase.lua` + `transparency.lua`
  → one `lua/utils/ui.lua`; submodule tables (`transparency`, `smartcase`,
  `float`) are inlined so `nvim.ui.transparency.*` keeps working.

### 3.4 Rewire module references

- Builder `lua/plugins/init.lua`: `"framework.plugins."` → `"factories."`.
- `lua/framework/plugins/alpha/init.lua`: `nvim.autoload("framework/plugins/alpha/styles")`
  → `nvim.autoload("factories/alpha/styles")`.
- `lua/framework/plugins/alpha/styles/dashboard.lua` and
  `lua/mappings/whichkey/bookmark.lua`: `framework.plugins.…` → `factories.…`.
- `lua/framework/plugins/nvim-cmp/init.lua`: `framework.plugins.nvim-cmp.dependencies`
  → `factories.nvim-cmp.dependencies`.
- `lua/framework/plugins/nvim-dap/init.lua`: `framework/plugins/nvim-dap/adapters`
  → `factories/nvim-dap/adapters`.
- `lua/framework/plugins/telescope/init.lua`: `framework.plugins.telescope.sources`
  → `factories.telescope.sources`.
- `lua/framework/plugins/lualine/init.lua`: `framework/plugins/lualine/components`
  → `factories/lualine/components`.
- `lua/lsp/nvim/init.lua` (now `lua/lsp/init.lua`) and friends:
  `lsp.nvim.provider/progress/inlayhint` → `lsp.provider/progress/inlayhint`.

### 3.5 Deduplicate helpers

- `lua/utils/open.lua` deletes its local `lazytable` and uses `nvim.lazytable`
  (already available from `utils/init.lua`, merged into `nvim`).

## Resulting tree

```
init.lua
lua/
  core.lua
  bootstrap.lua
  lazyconf/init.lua, lockfile.json
  configure/init.lua, options.lua, settings.lua, plugins.lua, icons.lua
  behaviors/init.lua, autocmds/*.lua, commands/*.lua
  mappings/init.lua, whichkey/*.lua        (no coc.lua)
  utils/*.lua, toggle.lua, ui.lua           (no toggle/, no ui/)
  lsp/init.lua, inlayhint.lua, progress.lua, provider.lua  (no coc/, no nvim/)
  factories/*.lua (50 files)
  plugins/init.lua, avante.lua, mcphub.lua, silkcircuit.lua, tether.lua
```

## Verification

- `rg -n 'coc|blink|pastel|galaxy' init.lua lua` returns nothing (except the
  README credit line, which is outside this scope).
- Headless start: `nvim --headless -c 'lua print(vim.g.colors_name); print(#vim.tbl_keys(nvim.plugins or {}))'`
  reports `silkcircuit` and the reduced plugin count, with no startup error.
- `:About` still shows `Kaos666`; `EditConf` opens all targets.
- Every `*.lua` file passes `luac -p` (LuaJIT load where `luac` 5.5 disagrees).
- `require("lazy")`, `require("lspconfig")` still resolve to the plugins, not
  the config modules.
