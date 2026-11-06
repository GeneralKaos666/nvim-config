# Unify the Neovim config — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Delete the dormant alternatives (blink-cmp, coc, pastel), hardcode the active providers, and collapse the directory tree one level.

**Architecture:** Remove dead code first, then rehome the remaining modules and rewire their `require`/`nvim.load`/`nvim.autoload` paths in the same change (a move and its references must land together or startup breaks). Factories stay outside lazy's import path.

**Tech Stack:** Neovim 0.12.6 (LuaJIT), lazy.nvim `stable`, `luac` 5.5.1 as syntax check, git with GPG-signed commits.

**Spec:** `docs/specs/2026-11-06-unify-nvim-config-design.md`

## Global Constraints

- GPG-sign every commit (`-S`); verify `%G?` = `G`.
- Do not convert factory modules into plain lazy specs.
- `~/.config/nvim` is a symlink to `~/repos/nvim-config`; run all commands from
  `~/repos/nvim-config` (or `~/.config/nvim`).
- Verification is headless (`nvim --headless`); config-file changes use the
  plan's verification-first checks, not unit RED→GREEN (configuration exception).
- Never force-push; do not touch `LICENSE`, the README galaxyvim credit, or
  `screenshots/`.

## Review Focus

- Startup with the three plugins removed: no `coc`, `blink`, or `pastel`
  reference survives anywhere under `lua/` or `init.lua`.
- `require("lazy")` still resolves to lazy.nvim; `require("lspconfig")` to
  nvim-lspconfig (not the config's modules).
- `nvim.plugins.<name>.enabled` still exists for every keymap `cond` that reads it.
- `nvim.toggle.lsp.*` and `nvim.ui.transparency.*` still resolve after the
  `toggle`/`ui` subdirectories are merged into single files.
- Plugin count drops by exactly 3 (53 → 50 factories; total 55 → 52) with no
  startup error.

---

### Task 1: Delete dormant alternatives and hardcode providers

**Files:**
- Delete: `lua/framework/plugins/blink-cmp.lua`
- Delete: `lua/framework/plugins/coc.lua`
- Delete: `lua/framework/plugins/pastel.lua`
- Delete: `lua/lsp/coc/` (directory)
- Delete: `lua/mappings/whichkey/coc.lua`
- Modify: `lua/configure/plugins.lua`
- Modify: `lua/lazyconf/lockfile.json`
- Modify: `lua/configure/settings.lua`
- Modify: `lua/utils/setup.lua`
- Modify: `lua/lsp/init.lua`
- Modify: `lua/framework/plugins/bufferline.lua`
- Modify: `lua/framework/plugins/autopairs.lua`
- Modify: `lua/framework/plugins/mason.lua`
- Modify: `lua/framework/plugins/nvim-cmp/init.lua`
- Modify: `lua/framework/plugins/indent-blankline.lua`
- Modify: `lua/framework/plugins/lualine/components/diagnostics.lua`
- Modify: `lua/framework/plugins/lualine/components/lspinfo.lua`
- Modify: `lua/utils/open.lua`
- Modify: `lua/framework/plugins/alpha/styles/dashboard.lua`
- Modify: `lua/mappings/whichkey/bookmark.lua`
- Modify: `lua/mappings/whichkey/lsp.lua`
- Modify: `lua/framework/plugins/neogit.lua`

**Interfaces:**
- Consumes: current tree on `refactor/flat-config`.
- Produces: zero `coc|blink|pastel` references; provider values hardcoded; a
  tree that still starts with plugin count 52. Later tasks move files; this
  task only edits in place.

- [ ] **Step 1: Record the baseline plugin count**

```bash
cd ~/repos/nvim-config
timeout 150 nvim --headless -c 'lua local n=0; for _ in pairs(nvim.plugins or {}) do n=n+1 end; print("plugins", n)' -c 'qa!' 2>&1 | tail -2
```

Expected: `plugins 55`.

- [ ] **Step 2: Delete the five dormant files/directories**

```bash
cd ~/repos/nvim-config
git rm -r lua/framework/plugins/blink-cmp.lua \
  lua/framework/plugins/coc.lua \
  lua/framework/plugins/pastel.lua \
  lua/lsp/coc \
  lua/mappings/whichkey/coc.lua
```

- [ ] **Step 3: Remove the three entries from `lua/configure/plugins.lua`**

Delete the `["coc"] = true,`, `["pastel"] = true,`, and `["blink-cmp"] = true,`
lines.

- [ ] **Step 4: Remove the three plugin pins from `lua/lazyconf/lockfile.json`**

Delete the `"coc"`, `"pastel"`, and `"blink-cmp"` top-level entries (and their
trailing commas). Keep valid JSON.

- [ ] **Step 5: Delete the `provider` switch from `lua/configure/settings.lua`**

Remove the entire block:

```lua
nvim.opt.provider = {
  picker = "telescope",      -- telescope | snacks
  cmp = "nvim-cmp",          -- nvim-cmp | blink-cmp
  lsp = "nvim",              -- nvim | coc
}
```

- [ ] **Step 6: Hardcode the active choices**

- `lua/utils/setup.lua`: in the LSP dispatch, remove the `elseif provider ==
  "coc"` branch; keep only the native `nvim` path.
- `lua/lsp/init.lua`: delete `local coc = nvim.load "lsp.coc"` and the
  `nvim.lsp, nvim.coc = lsp, coc` line becomes `nvim.lsp = lsp`.
- `lua/framework/plugins/bufferline.lua`: `local diagnostics_provider =
  nvim.opt.provider.lsp == "nvim" and "nvim_lsp" or "coc"` →
  `local diagnostics_provider = "nvim_lsp"`. Also change the later comment
  `-- "nvim_lsp" | "coc"` to `-- "nvim_lsp"`.
- `lua/framework/plugins/autopairs.lua`: `map_cr = nvim.opt.provider.lsp ==
  "nvim" and true or false` → `map_cr = true`.
- `lua/framework/plugins/mason.lua`: `enabled = nvim.opt.provider.lsp ==
  "nvim"` → `enabled = true`.
- `lua/framework/plugins/nvim-cmp/init.lua`: `enabled = nvim.opt.provider.lsp
  == "nvim" and nvim.opt.provider.cmp == "nvim-cmp"` → `enabled = true`.
- `lua/framework/plugins/indent-blankline.lua`: remove the `if not
  vim.startswith(vim.g.colors_name, "pastel") then` guard so the highlight
  block inside runs unconditionally (drop the closing `end` too).
- `lua/framework/plugins/lualine/components/diagnostics.lua`: remove the
  `elseif nvim.opt.provider.lsp == "coc"` branch; keep the `nvim` case.
- `lua/framework/plugins/lualine/components/lspinfo.lua`: delete the
  `coc_lsp()` function and its branch; keep the native count. Also delete the
  stale `-- File: lua/coc_count.lua` header comment.
- `lua/utils/open.lua`: `local case = nvim.opt.provider.picker` → `local case
  = "telescope"`; delete the `elseif case == "snacks"` branch, the
  `pickers.snacks` table, and the `opts` table.
- `lua/framework/plugins/alpha/styles/dashboard.lua`: `nvim.load("framework.plugins."
  .. nvim.opt.provider.picker .. ".pickers.bookmarks")` → `nvim.load("framework.plugins.telescope.pickers.bookmarks")`.
- `lua/mappings/whichkey/bookmark.lua`: `nvim.load(string.format("framework.plugins.%s.pickers.bookmarks",
  nvim.opt.provider.picker))` → `nvim.load("framework.plugins.telescope.pickers.bookmarks")`.
- `lua/mappings/whichkey/lsp.lua`: `cond = nvim.opt.provider.lsp == "nvim" and
  nvim.plugins.lspconfig.enabled` → `cond = nvim.plugins.lspconfig.enabled`.
- `lua/framework/plugins/neogit.lua`: `telescope = nvim.opt.provider.picker ==
  "telescope"` → `telescope = true`; `snacks = nvim.opt.provider.picker ==
  "snacks"` → `snacks = false`.

- [ ] **Step 7: Verify no dormant references remain**

```bash
cd ~/repos/nvim-config
rg -n -i 'coc|blink|pastel' init.lua lua; echo "exit=$?"
```

Expected: `exit=1` (no output). Note `settings.lua` still has a `cmp`/`lsp`
comment line in its provider block — that block was deleted in Step 5.

- [ ] **Step 8: Verify startup and the reduced count**

```bash
cd ~/repos/nvim-config
timeout 150 nvim --headless -c 'lua local n=0; for _ in pairs(nvim.plugins or {}) do n=n+1 end; print("plugins", n); print("colors", vim.g.colors_name)' -c 'qa!' 2>&1 | tail -4
```

Expected: `plugins 52`, `colors silkcircuit`, no error or traceback.

- [ ] **Step 9: Syntax-check the touched Lua files**

```bash
cd ~/repos/nvim-config
for f in lua/configure/settings.lua lua/utils/setup.lua lua/lsp/init.lua \
  lua/framework/plugins/bufferline.lua lua/framework/plugins/autopairs.lua \
  lua/framework/plugins/mason.lua lua/framework/plugins/nvim-cmp/init.lua \
  lua/framework/plugins/indent-blankline.lua \
  lua/framework/plugins/lualine/components/diagnostics.lua \
  lua/framework/plugins/lualine/components/lspinfo.lua \
  lua/utils/open.lua lua/framework/plugins/alpha/styles/dashboard.lua \
  lua/mappings/whichkey/bookmark.lua lua/mappings/whichkey/lsp.lua \
  lua/framework/plugins/neogit.lua; do
  luac -p "$f" || echo "FAIL $f"
done
```

Expected: no `FAIL` lines.

- [ ] **Step 10: Commit**

```bash
cd ~/repos/nvim-config
git add -A
git commit -S -m "refactor: drop blink-cmp, coc, pastel and hardcode providers"
git log -1 --show-signature --format='%h %G?'
```

Expected: `%G?` = `G`.

---

### Task 2: Flatten directories and rewire references

**Files:**
- Rename: `lua/framework/plugins/` → `lua/factories/`
- Rename: `lua/lsp/nvim/init.lua` → `lua/lsp/init.lua` (replaces dispatcher)
- Rename: `lua/lsp/nvim/inlayhint.lua` → `lua/lsp/inlayhint.lua`
- Rename: `lua/lsp/nvim/progress.lua` → `lua/lsp/progress.lua`
- Rename: `lua/lsp/nvim/provider.lua` → `lua/lsp/provider.lua`
- Create: `lua/utils/toggle.lua` (merges `utils/toggle/{init,lsp}.lua`)
- Create: `lua/utils/ui.lua` (merges `utils/ui/{init,float,smartcase,transparency}.lua`)
- Delete: `lua/utils/toggle/`, `lua/utils/ui/`
- Modify: `lua/plugins/init.lua`
- Modify: `lua/framework/plugins/alpha/init.lua`
- Modify: `lua/framework/plugins/alpha/styles/dashboard.lua`
- Modify: `lua/framework/plugins/nvim-cmp/init.lua`
- Modify: `lua/framework/plugins/nvim-dap/init.lua`
- Modify: `lua/framework/plugins/telescope/init.lua`
- Modify: `lua/framework/plugins/lualine/init.lua`
- Modify: `lua/mappings/whichkey/bookmark.lua`
- Modify: `lua/lsp/init.lua` (already moved), `lua/lsp/inlayhint.lua`, `lua/lsp/progress.lua`, `lua/lsp/provider.lua`
- Modify: `lua/utils/open.lua`

**Interfaces:**
- Consumes: Task 1 tree (no `coc|blink|pastel`, providers hardcoded).
- Produces: `lua/factories/` (50 modules), flat `lua/lsp/`, single
  `lua/utils/toggle.lua` and `lua/utils/ui.lua`; all `require`/`nvim.load`/
  `nvim.autoload` paths resolved to the new locations; `keyproxy` renamed in
  `utils/open.lua`. Startup still yields `plugins 52`.

- [ ] **Step 1: Move the factories**

```bash
cd ~/repos/nvim-config
git mv lua/framework/plugins lua/factories
rmdir lua/framework
```

Expected: `lua/factories/` exists with 50 entries; `lua/framework/` is gone.

- [ ] **Step 2: Flatten `lua/lsp`**

```bash
cd ~/repos/nvim-config
git mv lua/lsp/nvim/inlayhint.lua lua/lsp/inlayhint.lua
git mv lua/lsp/nvim/progress.lua  lua/lsp/progress.lua
git mv lua/lsp/nvim/provider.lua  lua/lsp/provider.lua
git mv lua/lsp/nvim/init.lua      lua/lsp/init.lua.new
git mv lua/lsp/init.lua           lua/lsp/init.lua.old
git mv lua/lsp/init.lua.new       lua/lsp/init.lua
rm lua/lsp/init.lua.old
rmdir lua/lsp/nvim
```

(Net effect: the LSP dispatcher is replaced by the former `lsp/nvim/init.lua`;
`coc` and `nvim` subdirectories are gone.)

- [ ] **Step 3: Merge `utils/toggle/` into `lua/utils/toggle.lua`**

Create `lua/utils/toggle.lua` containing, in order:

1. `local M = {}` (replaces the old `local M = nvim.autoload "utils/toggle"`).
2. Every function from `lua/utils/toggle/init.lua` verbatim (`M.float`,
   `M.notify`, `M.background`, `M.opt`, `M.wrap`, `M.signcolumn`,
   `M.statusline`, `M.statuscolumn`, `M.tabline`, `M.autosave`, `M.gitdiff`,
   `M.ts_highlight`, `M.ts_context`, and the private locals they use).
3. `local lsp = {}`, then every function from `lua/utils/toggle/lsp.lua` with
   its `function M.<name>` rewritten to `function lsp.<name>` (and its internal
   `M.notify`/`M.<name>` self-calls to `lsp.notify`/`lsp.<name>`).
4. `M.lsp = lsp`.
5. `return M`.

Then `git rm -r lua/utils/toggle`.

- [ ] **Step 4: Merge `utils/ui/` into `lua/utils/ui.lua`**

Create `lua/utils/ui.lua` containing, in order:

1. `local M = {}` (replaces `local M = nvim.autoload "utils/ui"`).
2. Every function from `lua/utils/ui/init.lua` verbatim (`M.notify`,
   `M.vpaste`, `M.format`, `M.stop_all_lsp`, `M.background`,
   `M.reload_highlights`, `M.clear_highlights`, `M.window`, `M.popup`,
   `M.statusline`, plus the private `notify` local).
3. `local transparency = {}`, then the body of `lua/utils/ui/transparency.lua`
   with `function M.<name>` rewritten to `function transparency.<name>`
   (keeping its private `notify`, `step`, `clamp`, `change` locals); then
   `M.transparency = transparency`.
4. `local float = {}`, then the body of `lua/utils/ui/float.lua` with
   `function M.float` → `function float.float`; then `M.float = float`.
5. The `smartcase` function from `lua/utils/ui/smartcase.lua` assigned as
   `M.smartcase = smartcase`.
6. `return M`.

Then `git rm -r lua/utils/ui`.

- [ ] **Step 5: Rewire the module references**

- `lua/plugins/init.lua`: `"framework.plugins."` → `"factories."`.
- `lua/factories/alpha/init.lua`: `nvim.autoload("framework/plugins/alpha/styles")`
  → `nvim.autoload("factories/alpha/styles")`.
- `lua/factories/alpha/styles/dashboard.lua` and
  `lua/mappings/whichkey/bookmark.lua`: `"framework.plugins.…` → `"factories.…`.
- `lua/factories/nvim-cmp/init.lua`: `"framework.plugins.nvim-cmp.dependencies"`
  → `"factories.nvim-cmp.dependencies"`.
- `lua/factories/nvim-dap/init.lua`: `"framework/plugins/nvim-dap/adapters"`
  → `"factories/nvim-dap/adapters"`.
- `lua/factories/telescope/init.lua`: `"framework.plugins.telescope.sources"`
  → `"factories.telescope.sources"`.
- `lua/factories/lualine/init.lua`: `"framework/plugins/lualine/components"`
  → `"factories/lualine/components"`.
- `lua/lsp/init.lua` (and the moved `inlayhint.lua`, `progress.lua`,
  `provider.lua`): `lsp.nvim.provider`/`lsp.nvim.progress`/
  `lsp.nvim.inlayhint` → `lsp.provider`/`lsp.progress`/`lsp.inlayhint`.
- `lua/utils/open.lua`: rename the local `lazytable` to `keyproxy` (definition
  and both call sites). Keep the `utils/init.lua` `lazytable` untouched.

- [ ] **Step 6: Verify no stale path references remain**

```bash
cd ~/repos/nvim-config
rg -n 'framework/plugins|framework\.plugins|lsp\.nvim|lspconfig\.' init.lua lua; echo "exit=$?"
```

Expected: `exit=1` (no output). `lspconfig` may only appear as the plugin name
string, never a module path.

- [ ] **Step 7: Syntax-check every Lua file**

```bash
cd ~/repos/nvim-config
find lua -name '*.lua' -print0 | xargs -0 -n1 luac -p 2>&1 | grep -v 'remove.lua'; echo "done"
```

Expected: only the pre-existing `remove.lua` line (filtered); nothing else.

- [ ] **Step 8: Verify startup, count, and merged tables**

```bash
cd ~/repos/nvim-config
timeout 150 nvim --headless -c 'lua
print("source", debug.getinfo(nvim.dofile).source)
local n=0; for _ in pairs(nvim.plugins or {}) do n=n+1 end
print("plugins", n)
print("toggle.lsp", type(nvim.toggle and nvim.toggle.lsp))
print("ui.transparency", type(nvim.ui and nvim.ui.transparency))
print("open.keyproxy", type(require("utils.open")))' -c 'qa!' 2>&1 | tail -8
```

Expected: source is `…/lua/core.lua`; `plugins 52`; `toggle.lsp table`;
`ui.transparency table`; `open.keyproxy table` (the module loads without
error); no traceback.

- [ ] **Step 9: Commit**

```bash
cd ~/repos/nvim-config
git add -A
git commit -S -m "refactor: flatten factories, lsp, and utils subdirectories"
git log -1 --show-signature --format='%h %G?'
```

Expected: `%G?` = `G`.

---

### Task 3: Full verification

**Files:** none unless a check fails.

**Interfaces:**
- Consumes: Task 2 tree.
- Produces: evidence the unified config is correct and ready to push.

- [ ] **Step 1: Zero-dormant guarantee**

```bash
cd ~/repos/nvim-config
rg -n -i 'coc|blink|pastel|galaxy' init.lua lua; echo "exit=$?"
```

Expected: `exit=1`. (`galaxy` appears only in the README credit, outside scope.)

- [ ] **Step 2: Collision targets**

```bash
cd ~/repos/nvim-config
timeout 150 nvim --headless -c 'lua
local function src(m)
  if type(m)=="function" then return debug.getinfo(m).source end
  if type(m)=="table" then for _,v in pairs(m) do if type(v)=="function" then return debug.getinfo(v).source end end end
  return "no-function"
end
print("lazy", src(require("lazy")))
local ok, lspconfig = pcall(require, "lspconfig")
print("lspconfig", ok, ok and src(lspconfig) or lspconfig)' -c 'qa!' 2>&1 | tail -4
```

Expected: `lazy` source under `site/pack/lazy/lazy.nvim`; `lspconfig true`
with a source under `/lspconfig/`.

- [ ] **Step 3: `:About` and `EditConf`**

```bash
cd ~/repos/nvim-config
timeout 150 nvim --headless -c 'lua
for _, k in ipairs({ "project", "configs", "bootstrap", "options", "settings", "plugins", "mappings" }) do
  local ok, err = pcall(vim.cmd, "EditConf " .. k); print(k, ok, err or "")
end' -c 'About' -c 'lua
for _, b in ipairs(vim.api.nvim_list_bufs()) do
  if vim.api.nvim_buf_is_loaded(b) then
    for _, l in ipairs(vim.api.nvim_buf_get_lines(b, 0, -1, false)) do
      if l:find("Kaos666") or l:find("galaxy") then print(l) end
    end
  end
end' -c 'qa!' 2>&1 | tail -10
```

Expected: every `EditConf` line ends `true`; `:About` prints `Kaos666` and no
galaxy line.

- [ ] **Step 4: Startup with the clone unreachable**

```bash
mv ~/.local/share/nvim/galaxyvim ~/.local/share/nvim/galaxyvim.off
cd ~/repos/nvim-config
timeout 150 nvim --headless -c 'lua print("ok", debug.getinfo(nvim.dofile).source)' -c 'qa!' 2>&1 | tail -2
mv ~/.local/share/nvim/galaxyvim.off ~/.local/share/nvim/galaxyvim
```

Expected: `ok @…/.config/nvim/lua/core.lua`, no clone/network error; the clone
directory is restored.

- [ ] **Step 5: Commit any fixes**

If any check failed and was fixed, commit:

```bash
cd ~/repos/nvim-config
git add -A && git commit -S -m "fix: address unify verification"
git log -1 --show-signature --format='%h %G?'
```

Otherwise record "no changes". Do not push without explicit confirmation.
