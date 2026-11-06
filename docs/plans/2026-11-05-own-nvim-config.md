# Own Neovim Config Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Flatten the vendored galaxyvim framework into `~/.config/nvim/lua/`, remove every runtime dependency on the clone, and publish the result to `GeneralKaos666/nvim-config`.

**Architecture:** Move-only commit first, then rewire module resolution (`nvim.main`, prefixed loads, lazy paths) so the local flat tree becomes the only source. Branding and README follow. The clone stays on disk but leaves `runtimepath` and lazy's `rtp.paths`. No factory-to-spec conversion.

**Tech Stack:** Neovim 0.12.6 (LuaJIT), lazy.nvim `stable`, Lua 5.1-compatible source, `luac` 5.5.1 as a syntax check, git with GPG-signed commits.

**Spec:** `docs/specs/2026-11-05-own-nvim-config-design.md`

## Global Constraints

- Every commit MUST be GPG-signed: run
  `sh "$HOME/.config/opencode/skills/gpg-commit/scripts/unlock-gpg.sh"` before
  the first commit, use `git commit -S`, and require `%G?` = `G`.
- Do not delete `~/.local/share/nvim/galaxyvim`.
- Do not convert the 53 plugin factories to plain lazy specs.
- Preserve GPL-3.0 `LICENSE` and keep a galaxyvim credit in `README.md`.
- Preserve `nvim.plugins` enabled-state table: `~25` keymap conditions read
  `nvim.plugins.<name>.enabled`.
- Never force-push to `GeneralKaos666/nvim-config` without explicit user
  confirmation.
- Verification runs from `~/.config/nvim`.

## File Structure

- `init.lua` — entry; treesitter runtime append + `require("core")`.
- `lua/core.lua` — `nvim` helper table, version/prereq checks, module loader.
- `lua/bootstrap.lua` — lazy.nvim setup and post-load hooks.
- `lua/lazyconf/init.lua` — lazy.nvim configuration.
- `lua/behaviors/`, `lua/configure/`, `lua/mappings/`, `lua/utils/` — framework modules.
- `lua/lsp/` — former `lspconfig/` (name collision with nvim-lspconfig).
- `lua/framework/plugins/` — 53 factory modules, outside lazy's import path.
- `lua/plugins/` — user standalone specs plus `init.lua` factory builder.
- `lua/behaviors/commands/about.lua`, `README.md` — branding.

## Review Focus

- Startup when `~/.local/share/nvim/galaxyvim` is absent and the network is
  down: must start without cloning anything.
- `require("lazy")` must resolve to lazy.nvim, never the config's lazy module.
- `require("lspconfig")` from plugins must resolve to nvim-lspconfig.
- `nvim.plugins.<name>.enabled` must still exist for every keymap `cond`.
- `EditConf` targets must resolve to existing files after the move.
- `nvim.fs.main`, `nvim.fs.root`, and `nvim.fs.configs` must point at the
  config tree, not the clone.
- Missing optional files (`configs.lua`, `presets.lua`, lockfile template)
  must not error.

---

### Task 1: Protect current work and branch

**Files:** none.

**Interfaces:**
- Consumes: current working tree.
- Produces: branch `refactor/own-config` with a clean tree.

- [ ] **Step 1: Inspect the working tree**

Run: `git -C ~/.config/nvim status --porcelain`
Expected: modified `init.lua`, `lockfile.json`, `lua/galaxy/configure/options.lua`,
`lua/galaxy/configure/settings.lua`, `lua/galaxy/plugins/treesitter.lua`,
`lua/plugins/avante.lua`, `lua/plugins/mcphub.lua`; modified
`.superpowers/sdd/nvim-config-fixes/progress.md`; untracked
`lua/plugins/tether.lua`.

- [ ] **Step 2: Unlock GPG signing**

Run: `sh "$HOME/.config/opencode/skills/gpg-commit/scripts/unlock-gpg.sh"`
Expected: `gpg unlocked: signing key 476FC230ECBBFDF0 ready ...`

- [ ] **Step 3: Commit work-in-progress on `main`**

```bash
cd ~/.config/nvim
git add -A
git commit -S -m "chore: checkpoint current config before flatten"
git log -1 --show-signature --format='%h %G?'
```

Expected: commit created, `%G?` is `G`.

- [ ] **Step 4: Create the refactor branch**

Run: `git switch -c refactor/own-config`
Expected: `Switched to a new branch 'refactor/own-config'`.

---

### Task 2: Move framework files (move-only commit)

**Files:**
- Move: `lua/galaxy/init.lua` → `lua/core.lua`
- Move: `lua/galaxy/bootstrap.lua` → `lua/bootstrap.lua`
- Move: `lua/galaxy/{behaviors,configure,mappings,utils}/` → `lua/`
- Move: `lua/galaxy/lazy/` → `lua/lazyconf/`
- Move: `lua/galaxy/lspconfig/` → `lua/lsp/`
- Move: `lua/galaxy/plugins/` → `lua/framework/plugins/`
- Remove: empty `lua/galaxy/`

**Interfaces:**
- Consumes: nothing.
- Produces: flat tree; startup still loads the clone, so this task is
  behavior-neutral.

- [ ] **Step 1: Move the files**

```bash
cd ~/.config/nvim
mkdir -p lua/framework
git mv lua/galaxy/init.lua lua/core.lua
git mv lua/galaxy/bootstrap.lua lua/bootstrap.lua
git mv lua/galaxy/behaviors lua/behaviors
git mv lua/galaxy/configure lua/configure
git mv lua/galaxy/mappings lua/mappings
git mv lua/galaxy/utils lua/utils
git mv lua/galaxy/lazy lua/lazyconf
git mv lua/galaxy/lspconfig lua/lsp
git mv lua/galaxy/plugins lua/framework/plugins
rmdir lua/galaxy
```

- [ ] **Step 2: Verify the tree**

Run: `find lua -maxdepth 2 -type d | sort; test ! -d lua/galaxy && echo "no galaxy dir"`
Expected: `lua/behaviors`, `lua/configure`, `lua/core.lua`, `lua/framework/plugins`,
`lua/lazyconf`, `lua/lsp`, `lua/mappings`, `lua/plugins`, `lua/utils`,
`no galaxy dir`.

- [ ] **Step 3: Verify startup is unchanged (clone still loads)**

Run:
```bash
timeout 120 nvim --headless -c 'lua print(debug.getinfo(nvim.dofile).source)' \
  -c 'qa!' 2>&1 | tail -3
```
Expected: source path contains `/.local/share/nvim/galaxyvim/lua/galaxy/init.lua`
and no startup error.

- [ ] **Step 4: Commit the move**

```bash
git add -A
git commit -S -m "refactor: move galaxyvim framework into lua/"
git show --stat --oneline HEAD | tail -20
```
Expected: commit lists renames, `%G?` = `G`.

---

### Task 3: Rewire modules and cut all galaxy pulls

**Files:**
- Modify: `init.lua`
- Modify: `lua/core.lua`
- Modify: `lua/bootstrap.lua`
- Modify: `lua/lazyconf/init.lua`
- Modify: `lua/framework/plugins/alpha/init.lua`
- Modify: `lua/framework/plugins/alpha/styles/dashboard.lua`
- Modify: `lua/framework/plugins/nvim-cmp/init.lua`
- Modify: `lua/framework/plugins/telescope/init.lua`
- Modify: `lua/framework/mappings/whichkey/bookmark.lua`
- Modify: `lua/plugins/init.lua`

**Interfaces:**
- Consumes: flat tree from Task 2.
- Produces: `nvim.main == ""`; unprefixed `nvim.load`; `lua/lazyconf` module;
  `lua/lsp` module; framework factory modules addressed as
  `framework.plugins.*`.

- [ ] **Step 1: Confirm the failure mode before rewiring**

Run: `rg -n 'galaxypath|require\("galaxy|galaxy\.plugins' init.lua lua | head`
Expected: matches in `init.lua`, `lua/plugins/init.lua`, and
`lua/lazyconf/init.lua`. These are the references that must disappear by the
end of the task.

- [ ] **Step 2: Replace root `init.lua`**

Make `init.lua` contain only the treesitter runtime append and the entry call:

```lua
require("core")

-- Expose nvim-treesitter's bundled highlight queries on the runtimepath.
-- The plugin ships them under its own `runtime/queries/` directory, which
-- lazy.nvim does not surface (only a few languages get symlinked into the
-- install dir). Without this, filetypes whose language isn't in the
-- treesitter install list (e.g. python, zsh) get no syntax highlighting.
local ts_runtime = vim.fn.stdpath("data") .. "/site/pack/lazy/treesitter/runtime"
if vim.fn.isdirectory(ts_runtime) == 1 and not vim.tbl_contains(vim.opt.rtp:get(), ts_runtime) then
	vim.opt.rtp:append(ts_runtime)
end
```

- [ ] **Step 3: Disable the module prefix in `lua/core.lua`**

Change line `nvim.main = nvim.path().head_tail` to:

```lua
nvim.main = ""
```

Change the prefix branch in `nvim.load` from:

```lua
    if main then
      name = string.format("%s.%s", nvim.main, name)
    end
```

to:

```lua
    if main and nvim.main ~= "" then
      name = string.format("%s.%s", nvim.main, name)
    end
```

In the startup load list, change `"lspconfig",` to `"lsp",`.

- [ ] **Step 4: Point bootstrap at the renamed lazy config**

In `lua/bootstrap.lua`, change `local lazyconf = nvim.load "lazy"` to
`local lazyconf = nvim.load "lazyconf"`. Leave
`nvim.lazy = nvim.require "lazy"` unchanged; that must stay lazy.nvim.

- [ ] **Step 5: Remove galaxy from lazy configuration**

In `lua/lazyconf/init.lua`:

- Replace `paths = { vim.g.galaxypath, },` with `paths = {},`.
- Change `nvim.fs.main .. "/lazy/lockfile.json"` to
  `nvim.fs.main .. "/lazyconf/lockfile.json"`.

Verify the template survived the move: `test -f lua/lazyconf/lockfile.json && echo ok`
Expected: `ok`.

- [ ] **Step 6: Rewrite the framework module references**

- `lua/lsp/init.lua`: `nvim.load "lspconfig.nvim"` → `nvim.load "lsp.nvim"`;
  `nvim.load "lspconfig.coc"` → `nvim.load "lsp.coc"`.
- `lua/lsp/nvim/init.lua`: `nvim.load "lspconfig.nvim.provider"` →
  `nvim.load "lsp.nvim.provider"`; `nvim.load "lspconfig.nvim.progress"` →
  `nvim.load "lsp.nvim.progress"`; `nvim.load "lspconfig.nvim.inlayhint"` →
  `nvim.load "lsp.nvim.inlayhint"`.
  Leave `nvim.plugins.lspconfig.enabled`, `require("mason-lspconfig")`, and the
  mason spec `{ "neovim/nvim-lspconfig", name = "lspconfig" }` unchanged: those
  name the plugin, not the config module.
- `lua/framework/plugins/alpha/init.lua`:
  `nvim.autoload("plugins/alpha/styles")` → `nvim.autoload("framework/plugins/alpha/styles")`
- `lua/framework/plugins/alpha/styles/dashboard.lua`:
  `"plugins." .. nvim.opt.provider.picker .. ".pickers.bookmarks"` →
  `"framework.plugins." .. nvim.opt.provider.picker .. ".pickers.bookmarks"`
- `lua/framework/plugins/nvim-cmp/init.lua`:
  `nvim.load "plugins.nvim-cmp.dependencies"` →
  `nvim.load "framework.plugins.nvim-cmp.dependencies"`
- `lua/framework/plugins/telescope/init.lua`:
  `nvim.load "plugins.telescope.sources"` →
  `nvim.load "framework.plugins.telescope.sources"`
- `lua/framework/mappings/whichkey/bookmark.lua`:
  `"plugins.%s.pickers.bookmarks"` → `"framework.plugins.%s.pickers.bookmarks"`

- [ ] **Step 7: Rewrite the factory builder**

In `lua/plugins/init.lua`:

```lua
-- Framework plugin factories live under `lua/framework/plugins/` and are
-- expanded here through `lua/configure/plugins.lua`. User specs are
-- standalone files in this directory; add `lua/plugins/<name>.lua`.
local enabled = require("configure.plugins")
local setup = require("utils.setup")

nvim.plugins = nvim.lazytable()
nvim.dofile(nvim.fs.presets)

local plugins = {}
for name, cond in pairs(enabled) do
  local module = "framework.plugins." .. name
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
```

- [ ] **Step 8: Syntax-check the touched files**

```bash
for f in init.lua lua/core.lua lua/bootstrap.lua lua/lazyconf/init.lua \
  lua/plugins/init.lua lua/lsp/init.lua lua/lsp/nvim/init.lua \
  lua/framework/plugins/alpha/init.lua \
  lua/framework/plugins/alpha/styles/dashboard.lua \
  lua/framework/plugins/nvim-cmp/init.lua \
  lua/framework/plugins/telescope/init.lua \
  lua/framework/mappings/whichkey/bookmark.lua; do
  luac -p "$f" || echo "FAIL $f"
done
```
Expected: no `FAIL` lines.

- [ ] **Step 9: Verify local core loads and galaxy is gone from runtime**

```bash
timeout 120 nvim --headless -c 'lua
print("source", debug.getinfo(nvim.dofile).source)
print("galaxypath", vim.g.galaxypath)
local n = 0; for _ in pairs(nvim.plugins or {}) do n = n + 1 end
print("plugins", n)
for _, p in ipairs(vim.opt.rtp:get()) do
  if p:find("galaxy") then print("RTP_GALAXY", p) end
end' -c 'qa!' 2>&1 | tail -10
```
Expected: `source @/data/data/com.termux/files/home/.config/nvim/lua/core.lua`,
`galaxypath nil`, `plugins 55`, no `RTP_GALAXY`, no `E5108` or traceback.

- [ ] **Step 10: Verify the zero-galaxy reference guarantee (branding pending)**

Run: `rg -n galaxy init.lua lua lockfile.json snippets -g '!lua/behaviors/commands/about.lua'`
Expected: exit status 1, no output. `lua/behaviors/commands/about.lua` still
carries upstream community links until Task 4; the full check runs in Task 5.

- [ ] **Step 11: Verify the lazy rtp path is empty**

Run:
```bash
timeout 120 nvim --headless -c 'lua print(vim.inspect(require("lazyconf").performance.rtp.paths))' -c 'qa!' 2>&1 | tail -3
```
Expected: `{}`.

- [ ] **Step 12: Commit**

```bash
git add -A
git commit -S -m "refactor: load flat local config and drop galaxy clone"
git log -1 --show-signature --format='%h %G?'
```
Expected: `%G?` = `G`.

---

### Task 4: Rebrand About and README

**Files:**
- Modify: `lua/behaviors/commands/about.lua`
- Modify: `README.md`

**Interfaces:**
- Consumes: moved tree from Task 2.
- Produces: `:About` shows `nvim-config` and the user's repository; README is
  the user's own while crediting galaxyvim.

- [ ] **Step 1: Update the About buffer**

In `lua/behaviors/commands/about.lua`, change:

- `"  • Name     : galaxyvim"` → `"  • Name     : nvim-config"`
- Delete the entire `Community` block:
  `" • Github ... discussions"`, `" • Reddit ..."`, `" • Discord ..."`,
  `" • Telegram ..."`, plus its preceding `"Community",` header and one
  surrounding blank line.
- Change the `Links` entries to:
  `"  • GitHub   : https://github.com/GeneralKaos666/nvim-config"` and
  `"  • Docs     : https://github.com/GeneralKaos666/nvim-config#readme"`.

- [ ] **Step 2: Rewrite `README.md`**

Include: title `# nvim-config`, a one-line description, requirements
(Neovim 0.11+, Nerd Font, `git`, `rg`, `node`, `npm`, `make`, a C compiler),
install (`git clone https://github.com/GeneralKaos666/nvim-config.git ~/.config/nvim`),
layout summary from the spec, and a `## Credits` section: "Framework code
derived from [galaxyvim](https://github.com/galaxyvim/galaxyvim), GPL-3.0."

- [ ] **Step 3: Verify branding**

Run: `rg -n 'galaxy' lua/behaviors/commands/about.lua README.md`
Expected: only the README Credits line matches.

Run:
```bash
timeout 120 nvim --headless -c 'About' -c 'lua
for _, b in ipairs(vim.api.nvim_list_bufs()) do
  if vim.api.nvim_buf_is_loaded(b) then
    for _, l in ipairs(vim.api.nvim_buf_get_lines(b, 0, -1, false)) do
      if l:find("nvim%-config") or l:find("galaxy") then print(l) end
    end
  end
end' -c 'qa!' 2>&1 | tail -6
```
Expected: only `nvim-config` lines; no galaxy lines.

- [ ] **Step 4: Commit**

```bash
git add lua/behaviors/commands/about.lua README.md
git commit -S -m "docs: rebrand about panel and README for own config"
git log -1 --show-signature --format='%h %G?'
```
Expected: `%G?` = `G`.

---

### Task 5: Full verification

**Files:** none unless a check fails.

**Interfaces:**
- Consumes: Tasks 1-4.
- Produces: evidence that the flat config works before publishing.

- [ ] **Step 1: Syntax-check every Lua file**

```bash
find lua -name '*.lua' -print0 | xargs -0 -n1 luac -p
```
Expected: no output, exit 0. If a file fails only because `luac` 5.5 differs
from LuaJIT, confirm with `nvim --headless -c 'lua assert(loadfile("<file>"))' -c 'qa!'`.

- [ ] **Step 2: Verify zero galaxy references**

Run: `rg -n galaxy init.lua lua lockfile.json snippets`
Expected: exit status 1, no output.

- [ ] **Step 3: Verify startup, plugin count, runtime path**

Re-run Task 3 Step 9. Expected: local `core.lua`, `galaxypath nil`,
`plugins 55`, no galaxy rtp entries, no errors.

- [ ] **Step 3b: Verify collision targets, enabled table, and config paths**

```bash
timeout 120 nvim --headless -c 'lua
local function src(m)
  if type(m) == "function" then return debug.getinfo(m).source end
  if type(m) == "table" then
    for _, v in pairs(m) do
      if type(v) == "function" then return debug.getinfo(v).source end
    end
  end
  return "no-function"
end
print("lazy", src(require("lazy")))
local ok, lspconfig = pcall(require, "lspconfig")
print("lspconfig", ok, ok and src(lspconfig) or lspconfig)
print("enabled", nvim.plugins.alpha.enabled, nvim.plugins.lspconfig.enabled)
print("fs", nvim.fs.main)
print("root", nvim.fs.root)
print("configs", nvim.fs.configs)' -c 'qa!' 2>&1 | tail -10
```
Expected: `lazy` source contains `site/pack/lazy/lazy.nvim`; `lspconfig true`
and a source under `/lspconfig/` (plugin, not `lua/lsp`); `enabled true true`;
`fs` ends in `/.config/nvim/lua`; `root` ends in `/.config/nvim`; `configs`
ends in `/.config/nvim/configs.lua`.

- [ ] **Step 4: Verify EditConf targets**

```bash
timeout 120 nvim --headless -c 'lua
for _, k in ipairs({ "project", "configs", "bootstrap", "options", "settings", "plugins", "mappings" }) do
  local ok, err = pcall(vim.cmd, "EditConf " .. k)
  print(k, ok, err or "")
end' -c 'qa!' 2>&1 | tail -10
```
Expected: every line ends in `true` with no error text.

- [ ] **Step 5: Verify zero-pull behavior with the clone unreachable**

Temporarily rename the clone, start Neovim, then restore it:

```bash
mv ~/.local/share/nvim/galaxyvim ~/.local/share/nvim/galaxyvim.off
timeout 120 nvim --headless -c 'lua print("ok", debug.getinfo(nvim.dofile).source)' -c 'qa!' 2>&1 | tail -3
mv ~/.local/share/nvim/galaxyvim.off ~/.local/share/nvim/galaxyvim
```
Expected: no clone attempt, `ok @/.../.config/nvim/lua/core.lua`, and no network
error. The clone directory is restored before continuing.

- [ ] **Step 6: Interactive launch**

Run: `nvim`
Expected: dashboard renders, no error notifications, `<leader>k` config menu
works, opening a Lua file still gets treesitter highlighting and LSP. Quit
with `:qa`.

- [ ] **Step 7: Commit any fixes**

If verification required edits, commit them: `git add -A && git commit -S -m "fix: address flatten verification"` and confirm `%G?` = `G`. Otherwise
record "no changes" in the task log.

---

### Task 6: Publish to GitHub (gated)

**Files:** none.

**Interfaces:**
- Consumes: verified branch `refactor/own-config`.
- Produces: remote `origin` configured; remote reconciled with the user's
  explicit decision; branch pushed.

- [ ] **Step 1: Add the remote**

```bash
git remote add origin https://github.com/GeneralKaos666/nvim-config.git
git remote -v
```
Expected: `origin` fetch/push point at `GeneralKaos666/nvim-config`.

- [ ] **Step 2: Fetch and compare histories**

```bash
git fetch origin
git rev-parse --verify origin/master
git merge-base refactor/own-config origin/master || echo "UNRELATED HISTORIES"
git log --oneline --graph --decorate --all -20
git diff --stat refactor/own-config origin/master | tail -5
```
Expected: either a merge-base commit, or `UNRELATED HISTORIES`. Record the
result.

- [ ] **Step 3: STOP and ask the user how to reconcile**

Present: local branch head, `origin/master` head, merge-base result, and diff
size. Offer (a) push `refactor/own-config` as a new branch only, (b) open a PR
from that branch to `master`, (c) replace `master` history (requires explicit
force-push approval). Do not run any push yet.

- [ ] **Step 4: Push the branch**

After approval:

```bash
git push -u origin refactor/own-config
```
Expected: remote branch created; no force flag.

- [ ] **Step 5: Reconcile `master` per the user's choice**

Only after explicit confirmation:

- For a PR: `gh pr create --repo GeneralKaos666/nvim-config --base master --head refactor/own-config --title "Own config: flatten galaxyvim" --body ...`
- For a history replacement: confirm once more, then
  `git push --force-with-lease origin refactor/own-config:master`. Never plain
  `--force`.

- [ ] **Step 6: Verify the remote**

Run: `git ls-remote origin | head -5`
Expected: `refs/heads/refactor/own-config` present, and `master` updated only
if that path was chosen.

---

## Rollback

- `refactor/own-config` can be discarded; `main` retains the checkpoint commit
  before the move.
- The clone at `~/.local/share/nvim/galaxyvim` is never modified by this plan.
- If the flat tree fails at runtime, `git switch main && git restore .` returns
  to the clone-backed configuration.
