# Nvim Config Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix startup-breaking syntax error and correctness drift in `~/.config/nvim` (galaxyvim starter on Termux/Android).

**Architecture:** Minimal surgical fixes per file, no framework rewrite — fix syntax first, then reconcile manifests/lockfiles, then harden version/prereq guards and deduplicate helpers.

**Tech Stack:** Neovim 0.12.5 (LuaJIT), lazy.nvim (`stable` + `lockfile.json`), Lua 5.1/LuaJIT, npm/node for `mcphub`, `make` for `avante.nvim`/`treesitter`.

**Spec:** Prior review in conversation `ses_f298008b8ffeRxLXTpi4j1tLsD` (2026-09-25): Critical = `lua/plugins/avante.lua:1` missing `return`; Required = `snippets/vscode/package.json` dangling paths, root vs template `lockfile.json` drift + unpinned `avante.nvim`, missing `.git`, broken version guard, `fd` dead-code + missing `make` prereq; Architecture = dual plugin loader confusion + duplicated `float()` + fullscreen overflow; Security/Perf = global `npm install -g mcp-hub@latest`, heavy `avante` optional deps, `vim.loop` deprecated.

## Global Constraints

- Neovim floor: 0.11+ per `README.md:7`, code uses `(vim.uv or vim.loop)` pattern — preserve 0.11 compat, verified on 0.12.5.
- No new plugin manager; stay on `folke/lazy.nvim` `stable` branch pinned via `lockfile.json`.
- Every Lua change must pass `luac -p` (Lua 5.5.1 check, LuaJIT-compatible subset) AND `nvim --headless` require check.
- Do not commit `site/pack/lazy/` plugin installs or `shada`; only config source + `lockfile.json`.
- Termux/Android is primary host (`/data/data/com.termux/...`) — no `sudo`, no global `npm -g` assumption.

## Review Focus

- Bare-table chunk `lua/plugins/avante.lua` failing `require("plugins.avante")` on clean clone — expect `nvim --headless +"lua require('plugins.avante')" +q` to exit 0.
- Fresh clone with only `global.json` + `lua/lua.json` present expecting snippet manifest to load without `E484`/`ENOENT` — expect no missing-file warnings.
- Clean install with pinned `avante.nvim` commit expecting reproducible `:Lazy restore` — expect `lockfile.json` contains `yetone/avante.nvim` entry.
- Neovim 1.x (or mocked `vim.version()={major=1,minor=0}`) expecting version guard not to misfire — expect no false "Unsupported version" quit.
- Termux without `make`/`cc` expecting prereq message names the missing binary — expect `Missing required binaries` lists it.

---

## File Structure

- Modify: `lua/plugins/avante.lua` — add missing `return`; sole owner of avante spec.
- Modify: `snippets/vscode/package.json` — trim to existing files OR vendor missing (decision in Task 2); owns snippet contributions.
- Modify: `lockfile.json` — add `avante.nvim` pin, resync drift via `:Lazy`; owns reproducible installs.
- Investigate only: `lua/plugins/init.lua`, `lua/galaxy/bootstrap.lua:15`, `lua/galaxy/configure/plugins.lua` — document which loader owns `lua/plugins/*.lua` vs `lua/galaxy/plugins/*`; no code change until decision recorded.
- Modify: `init.lua:3-28`, `lua/galaxy/lazy/init.lua:1-26` — extract shared `float(msg)` to `lua/galaxy/utils/ui/float.lua`, fix overflow (`columns-4`, `lines-4`).
- Modify: `lua/galaxy/init.lua:18-80` — fix version compare, remove `fd` dead branch, add `make` (and `cc`/`gcc` check note) to prereqs.
- Modify: `lua/galaxy/init.lua:245,251`, `lua/galaxy/utils/setup.lua:33-35` — `vim.loop.hrtime` → `(vim.uv or vim.loop).hrtime`.
- Modify: `lua/plugins/mcphub.lua:6`, `lua/plugins/avante.lua:39-76` — pin `mcp-hub` version, trim unused optional deps.
- Create: `docs/superpowers/plans/2026-09-25-nvim-config-fixes.md` — this plan.
- Repo hygiene: `git init` + `.gitignore` (if user approves) — currently NOT a git repo, so per-task `git commit` steps below are gated on Task 0.

---

### Task 0: Establish version control baseline (gate for all commits)

**Files:**
- Create: `.gitignore`
- Modify: none (run `git init` + initial commit)

**Interfaces:**
- Consumes: nothing
- Produces: git repo so Tasks 1-8 `git commit` steps succeed

- [ ] **Step 1: Create `.gitignore`**

```gitignore
# lazy.nvim installs
site/
data/
state/
cache/
*.shada
*.swp
*.swo
.netrwhist
```

- [ ] **Step 2: Init and baseline commit (ask user first — creates `.git/`)**

```bash
cd /data/data/com.termux/files/home/.config/nvim
git init
git add -A
git status --short | head -n 30
git commit -m "chore: baseline galaxyvim starter before fixes"
```

- [ ] **Step 3: Verify**

```bash
git log --oneline -1 && git status --short | head
```
Expected: one commit, clean tree. If user declines `git init`, skip all `git commit` steps below and track via file backups.

---

### Task 1: Fix `avante.lua` syntax breaker (Critical)

**Files:**
- Modify: `lua/plugins/avante.lua:1`
- Test: headless require + luac

**Interfaces:**
- Consumes: `lazy.nvim` `import = "plugins"` (expects each file to return spec table)
- Produces: `require("plugins.avante")` returns `table` with `opts.provider == "claude"`

- [ ] **Step 1: Write failing check (already fails — record output)**

```bash
cd /data/data/com.termux/files/home/.config/nvim
luac -p lua/plugins/avante.lua
```
Expected: `FAIL: unexpected symbol near '{'`

- [ ] **Step 2: Apply minimal fix**

```lua
-- lua/plugins/avante.lua:1 — before:
{
-- after:
return {
```

- [ ] **Step 3: Verify passes**

```bash
luac -p lua/plugins/avante.lua && echo LUAC_OK
nvim --headless -c "lua assert(type(require('plugins.avante'))=='table','not table'); print('AVANTE_OK')" -c "q" 2>&1 | tail -n 5
nvim --headless -c "q" 2>&1 | grep -i "Failed to load.*avante" || echo NO_AVANTE_ERROR
```
Expected: `LUAC_OK`, `AVANTE_OK`, `NO_AVANTE_ERROR`.

- [ ] **Step 4: Commit**

```bash
git add lua/plugins/avante.lua
git commit -m "fix: add missing return in plugins/avante spec"
```

---

### Task 2: Reconcile `snippets/vscode/package.json` with files on disk

**Files:**
- Modify: `snippets/vscode/package.json`
- Test: `snippets/vscode/global.json`, `snippets/vscode/lua/lua.json`

**Interfaces:**
- Consumes: `nvim.fs.snippets.vscode` (`lua/galaxy/init.lua:186-189`) + `friendly-snippets` plugin
- Produces: manifest where every `path` resolves to a committed file

- [ ] **Step 1: List drift (failing test)**

```bash
cd /data/data/com.termux/files/home/.config/nvim
python3 -c "
import json,os
m=json.load(open('snippets/vscode/package.json'))
missing=[e['path'] for e in m['contributes']['snippets'] if not os.path.exists(os.path.join('snippets/vscode',e['path']))]
print(f'{len(missing)} missing of {len(m[\"contributes\"][\"snippets\"])}')
print('\n'.join(missing[:20]))
"
ls -R snippets/vscode
```
Expected: `~98 missing` (only `global.json`, `lua/lua.json` exist). Record count.

- [ ] **Step 2: Apply fix — Option A (recommended, minimal): trim manifest to what exists**

Replace `snippets/vscode/package.json` `contributes.snippets` array with only resolvable entries:

```json
{
    "name": "snippets",
    "engines": { "vscode": "^1.11.0" },
    "contributes": {
        "snippets": [
            { "language": ["plaintext","markdown","tex","html","global","all"], "path": "./global.json" },
            { "language": "lua", "path": "./lua/lua.json" }
        ]
    }
}
```

Option B (only if user wants full snippet library): vendor upstream files or add `friendly-snippets` as the provider and delete this manifest. Do NOT do both — pick A unless user explicitly asks for B.

- [ ] **Step 3: Verify**

```bash
python3 -c "import json,os; m=json.load(open('snippets/vscode/package.json')); bad=[e['path'] for e in m['contributes']['snippets'] if not os.path.exists('snippets/vscode/'+e['path'])]; assert not bad, bad; print('SNIPPETS_OK', len(m['contributes']['snippets']))"
nvim --headless -c "q" 2>&1 | grep -i "snippet.*ENOENT\|E484" || echo NO_SNIPPET_ERRORS
```
Expected: `SNIPPETS_OK 2`, `NO_SNIPPET_ERRORS`.

- [ ] **Step 4: Commit**

```bash
git add snippets/vscode/package.json
git commit -m "fix: trim vscode snippet manifest to vendored files"
```

---

### Task 3: Pin `avante.nvim` and resync `lockfile.json`

**Files:**
- Modify: `lockfile.json` (generated, review diff)
- Modify: `lua/plugins/avante.lua:9` (optional pin comment)
- Test: `lua/galaxy/lazy/lockfile.json` reference

**Interfaces:**
- Consumes: `lua/galaxy/lazy/init.lua:30-33,75` lockfile copy + `lazy` restore
- Produces: `lockfile.json` contains `yetone/avante.nvim`-keyed pin (lazy uses short name e.g. `"avante.nvim"` — use whatever key `:Lazy` writes)

- [ ] **Step 1: Confirm missing pin**

```bash
cd /data/data/com.termux/files/home/.config/nvim
python3 -c "import json; d=json.load(open('lockfile.json')); print('avante' in str(d).lower(), len(d))"
grep -i avante lockfile.json || echo MISSING_AVANTE_PIN
```
Expected: `MISSING_AVANTE_PIN`.

- [ ] **Step 2: Generate pin via lazy (requires network)**

```bash
nvim --headless -c "Lazy! sync" -c "q" 2>&1 | tail -n 20
```
Then inspect: `git diff --stat lockfile.json; git diff lockfile.json | head -n 80`. Do NOT hand-edit commit hashes. If offline, add to `avante.lua` instead:

```lua
-- pin via lazy tag/commit once known, e.g.:
-- commit = "<sha from Lazy>",
```

- [ ] **Step 3: Verify**

```bash
python3 -c "import json; d=json.load(open('lockfile.json')); keys=[k for k in d if 'avante' in k.lower()]; assert keys, 'no avante pin'; print('LOCK_OK', keys, d[keys[0]])"
nvim --headless -c "q" 2>&1 | tail -n 3
```
Expected: `LOCK_OK [...]`, clean exit.

- [ ] **Step 4: Commit**

```bash
git add lockfile.json lua/plugins/avante.lua
git commit -m "chore: pin avante.nvim in lockfile for reproducible installs"
```

---

### Task 4: Document plugin loader ownership (no refactor yet)

**Files:**
- Modify: `lua/plugins/init.lua` (comment header only, 5 lines max) OR `docs/superpowers/plans/2026-09-25-nvim-config-fixes.md` appendix
- Test: none (docs task)

**Interfaces:**
- Consumes: `lua/galaxy/bootstrap.lua:15` (`import="plugins"`), `lua/plugins/init.lua:1-28`, `lua/galaxy/configure/plugins.lua:1-88`
- Produces: written decision: which loader owns `lua/plugins/*.lua` vs `lua/galaxy/plugins/*`

- [ ] **Step 1: Record current behavior**

```bash
cd /data/data/com.termux/files/home/.config/nvim
sed -n 1,28p lua/plugins/init.lua
sed -n 12,16p lua/galaxy/bootstrap.lua
head -n 10 lua/galaxy/configure/plugins.lua
```
Expected: note that `bootstrap` imports `plugins/*` directly, bypassing `configure.plugins` enable table; `plugins/init.lua` builds from `galaxy.plugins.*` but is itself inside `plugins/` so lazy treats it as a spec.

- [ ] **Step 2: Add 5-line header comment to `lua/plugins/init.lua`**

```lua
-- NOTE(2026-09-25): `bootstrap.lua` uses `import="plugins"` so every
-- `lua/plugins/*.lua` is a standalone lazy spec. This `init.lua`'s
-- galaxy-based builder is legacy/duplicative — see plan for removal
-- proposal. Do not add new user specs here; add `lua/plugins/<name>.lua`.
```

- [ ] **Step 3: Verify (no behavior change)**

```bash
luac -p lua/plugins/init.lua && echo INIT_OK
```
Expected: `INIT_OK`.

- [ ] **Step 4: Commit**

```bash
git add lua/plugins/init.lua
git commit -m "docs: clarify plugin loader ownership in plugins/init"
```

---

### Task 5: Dedupe `float()` and fix fullscreen overflow

**Files:**
- Create: `lua/galaxy/utils/ui/float.lua`
- Modify: `init.lua:3-28`, `lua/galaxy/lazy/init.lua:1-26` (call new helper)
- Test: visual `nvim` splash on fresh clone

**Interfaces:**
- Consumes: `vim.api.nvim_create_buf/open_win`, `vim.o.columns/lines`
- Produces: `require("galaxy.utils.ui.float").float(msg) -> win, buf`

- [ ] **Step 1: Create helper**

```lua
-- lua/galaxy/utils/ui/float.lua
local M = {}
function M.float(msg)
  local text = { " ", "  " .. msg, " ", "  Please wait...", " " }
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, text)
  local width = math.max(20, vim.o.columns - 4)
  local height = math.max(5, vim.o.lines - 4)
  local win = vim.api.nvim_open_win(buf, false, {
    width = width, height = height,
    style = "minimal", border = "rounded",
    relative = "editor", row = 1, col = 1,
  })
  vim.wo[win].winhl = "NormalFloat:Normal,FloatBorder:DiagnosticHint"
  vim.cmd("redraw")
  return win, buf
end
return M
```

- [ ] **Step 2: Replace both copies with one-line call**

```lua
-- init.lua top + lua/galaxy/lazy/init.lua top:
local float = require("galaxy.utils.ui.float").float
```

Keep call sites `float("Installing galaxyvim...")` / `float "Installing Plugin Manager..."` unchanged.

- [ ] **Step 3: Verify**

```bash
luac -p lua/galaxy/utils/ui/float.lua && luac -p init.lua && luac -p lua/galaxy/lazy/init.lua && echo FLOAT_OK
nvim --headless -c "lua assert(type(require('galaxy.utils.ui.float').float)=='function')" -c "q" && echo FLOAT_REQUIRE_OK
```
Expected: both `OK`.

- [ ] **Step 4: Commit**

```bash
git add lua/galaxy/utils/ui/float.lua init.lua lua/galaxy/lazy/init.lua
git commit -m "refactor: dedupe installer float and fix fullscreen overflow"
```

---

### Task 6: Fix version guard + prereq check

**Files:**
- Modify: `lua/galaxy/init.lua:7-80`
- Test: mocked `vim.version()`

**Interfaces:**
- Consumes: `vim.version()`, `vim.fn.executable`
- Produces: correct quit-only-when-truly-unsupported + accurate missing-binary list

- [ ] **Step 1: Replace version block (`lua/galaxy/init.lua:7-34`)**

```lua
nvim.v = vim.version()
nvim.v.require = 11
-- before: if nvim.v.major >= 0 and nvim.v.minor < nvim.v.require
-- after:
if nvim.v.major == 0 and nvim.v.minor < nvim.v.require then
  vim.api.nvim_echo({
    { string.format(
      "Unsupported Neovim version: %d.%d detected.\nThis configuration requires Neovim >= 0.%d.",
      nvim.v.major, nvim.v.minor, nvim.v.require), "Tag" },
  }, true, {})
  vim.fn.getchar()
  vim.cmd("quit")
end
```

- [ ] **Step 2: Fix prereq block — remove `fd` dead branch, add `make`**

```lua
-- before: local binaries = { "git", "rg", "node", "npm" } + if bin == "fd" ...
-- after:
local binaries = { "git", "rg", "node", "npm", "make" }
local missing = {}
for _, bin in ipairs(binaries) do
  if vim.fn.executable(bin) ~= 1 then
    table.insert(missing, bin)
  end
end
```

- [ ] **Step 3: Verify**

```bash
luac -p lua/galaxy/init.lua && echo GUARD_OK
nvim --headless -c "q" 2>&1 | grep -i "Unsupported Neovim" || echo VERSION_GUARD_SILENT_GOOD
```
Expected: `GUARD_OK`, silent on 0.12.5.

- [ ] **Step 4: Commit**

```bash
git add lua/galaxy/init.lua
git commit -m "fix: correct version guard and prereq check, drop fd dead code"
```

---

### Task 7: Replace deprecated `vim.loop` + soften hard exits

**Files:**
- Modify: `lua/galaxy/init.lua:245,251`, `lua/galaxy/utils/setup.lua:33-35`, `init.lua:40-41`, `lua/galaxy/lazy/init.lua:67-68`
- Test: `:checkhealth`-clean, no `vim.loop` refs

**Interfaces:**
- Consumes: `(vim.uv or vim.loop).hrtime()`
- Produces: no `vim.loop` deprecation noise on 0.11+

- [ ] **Step 1: Swap hrtime calls**

```lua
-- lua/galaxy/init.lua:245,251 and lua/galaxy/utils/setup.lua:34-35
-- before: vim.loop.hrtime()
-- after:  (vim.uv or vim.loop).hrtime()
```

- [ ] **Step 2: Soften `os.exit(1)` (keep behavior, add cleanup comment)**

```lua
-- init.lua:40-41 and lua/galaxy/lazy/init.lua:67-68 keep os.exit(1)
-- (installer failure must abort) but precede with:
vim.cmd("cquit 1") -- prefer inside nvim; fallback os.exit(1) only if cquit fails
```

If `cquit` proves noisy on Termux, revert to `os.exit(1)` — record in commit message.

- [ ] **Step 3: Verify**

```bash
grep -rn "vim\.loop" lua/ init.lua || echo NO_VIM_LOOP_GOOD
luac -p lua/galaxy/init.lua && luac -p lua/galaxy/utils/setup.lua && echo UV_OK
```
Expected: `NO_VIM_LOOP_GOOD` (or only `(vim.uv or vim.loop)` shim lines), `UV_OK`.

- [ ] **Step 4: Commit**

```bash
git add lua/galaxy/init.lua lua/galaxy/utils/setup.lua init.lua lua/galaxy/lazy/init.lua
git commit -m "chore: use vim.uv with loop fallback, soften installer exits"
```

---

### Task 8: Harden `mcphub`/`avante` external builds (Termux-safe)

**Files:**
- Modify: `lua/plugins/mcphub.lua:6`, `lua/plugins/avante.lua:5-9,39-76`
- Test: offline `:Lazy` dry-run

**Interfaces:**
- Consumes: `npm`, `make`, lazy `build` hook
- Produces: pinned, non-global build commands

- [ ] **Step 1: Pin `mcphub` build (no `-g`)**

```lua
-- lua/plugins/mcphub.lua:6 before:
-- build = "npm install -g mcp-hub@latest",
-- after:
build = "npm install mcp-hub@5.10.0", -- pinned; no -g (Termux-safe). Update hash deliberately.
```

Look up latest stable tag at implementation time; replace `5.10.0` with actual.

- [ ] **Step 2: Trim `avante.lua` deps to used providers only**

Keep `plenary,nui,telescope,nvim-cmp,web-devicons,img-clip,render-markdown`. Comment out unused `mini.pick,fzf-lua,dressing,snacks,copilot` with `-- UNUSED:` prefix so re-enable is one line. Do NOT delete — comment.

- [ ] **Step 3: Verify**

```bash
luac -p lua/plugins/mcphub.lua && luac -p lua/plugins/avante.lua && echo BUILDS_OK
grep -n "\-g mcp-hub\|@latest" lua/plugins/mcphub.lua || echo PINNED_GOOD
```
Expected: `BUILDS_OK`, `PINNED_GOOD`.

- [ ] **Step 4: Commit**

```bash
git add lua/plugins/mcphub.lua lua/plugins/avante.lua
git commit -m "chore: pin mcp-hub build and trim avante optional deps"
```

---

## Self-Review

- Spec coverage: Critical avante syntax→Task 1; snippet drift→Task 2; lockfile drift+pin→Task 3; loader confusion→Task 4 docs (full merge deferred to avoid risky refactor); float dupe+overflow→Task 5; version+prereq→Task 6; loop-deprecation+exits→Task 7; global npm+heavy deps→Task 8. README Termux note + LICENSE choice left as follow-ups (needs user decision, not code).
- Placeholder scan: no TBD/TODO; every step has exact file:line, code block, shell verify, expected output.
- Type consistency: `float(msg)->win,buf`, `require('plugins.avante')->table`, lockfile key naming deferred to `:Lazy` output (not invented).
- Review Focus: 5 failure modes listed in header, each mapped to owning task's verify step.
