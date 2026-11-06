# Own Neovim Config: Flatten galaxyvim into `lua/`

Date: 2026-11-05
Status: Design approved, pending spec review

## Goal

Stop depending on the cloned `galaxyvim` repository and make the local copy the
single source of truth. Remove the `lua/galaxy/` wrapper so framework code lives
directly under `~/.config/nvim/lua/`. Keep the clone on disk as reference, but
remove it from `runtimepath` and from lazy.nvim's runtime paths.

After the change, no runtime file may reference `galaxy`, clone it, or load it.
The only remaining mentions are the untouched clone directory on disk, the GPL
license, and an attribution note in the README.

At the end, publish the result to
`https://github.com/GeneralKaos666/nvim-config`.

## Current state

- `~/.config/nvim` is a git repository on branch `main` with no remote. It
  contains uncommitted changes in `init.lua`, `lockfile.json`,
  `lua/galaxy/configure/options.lua`, `lua/galaxy/configure/settings.lua`,
  `lua/galaxy/plugins/treesitter.lua`, `lua/plugins/avante.lua`,
  `lua/plugins/mcphub.lua`, and an untracked `lua/plugins/tether.lua`.
- Root `init.lua` sets `vim.g.galaxypath`, clones
  `https://github.com/galaxyvim/galaxyvim` into
  `~/.local/share/nvim/galaxyvim` when missing, prepends that directory to
  `runtimepath`, then calls `require("galaxy")`.
- Because the prepend happens immediately before `require`, the **cloned** copy
  loads at startup. The local `lua/galaxy/` copy is a modified fork (165 files
  versus 164 in the clone) and is partially shadowed.
- `lua/galaxy/plugins/` contains 53 factory modules (`return M`, `M.config()`)
  consumed by `lua/plugins/init.lua` through `lua/galaxy/configure/plugins.lua`.
- `lua/plugins/` contains five standalone lazy specs (`avante.lua`,
  `mcphub.lua`, `silkcircuit.lua`, `tether.lua`, `init.lua`).
- Two module names collide with plugins already on `runtimepath`:
  `lazy` (lazy.nvim) and `lspconfig` (nvim-lspconfig).

## Non-goals

- Do not delete `~/.local/share/nvim/galaxyvim`.
- Do not convert the 53 plugin factories into standalone lazy specs.
- Do not change plugin selection, colorscheme, or keymaps.
- Do not rewrite documentation history.

## Target layout

```
init.lua                    entry: require("core") plus treesitter runtime append
lua/core.lua                former lua/galaxy/init.lua
lua/bootstrap.lua           former lua/galaxy/bootstrap.lua
lua/behaviors/              former lua/galaxy/behaviors
lua/configure/              former lua/galaxy/configure
lua/mappings/               former lua/galaxy/mappings
lua/utils/                  former lua/galaxy/utils
lua/lazyconf/               former lua/galaxy/lazy
lua/lsp/                    former lua/galaxy/lspconfig
lua/framework/plugins/      former lua/galaxy/plugins (53 factories)
lua/plugins/                user standalone specs and the legacy builder
```

`lua/galaxy/` disappears. The clone stays at
`~/.local/share/nvim/galaxyvim` but is never added to `runtimepath`.

## Required changes

### Entry point

Root `init.lua`:

- Remove `vim.g.galaxypath`, the clone/install block, the inline `float`
  fallback used only by that block, `vim.opt.rtp:prepend`, and
  `pcall(require, "galaxy")`.
- Keep the trailing nvim-treesitter runtime append.
- Add `require("core")`.

### Core module (`lua/core.lua`)

- Set `nvim.main = ""` instead of deriving it from the file's parent directory.
- Change `nvim.load` so the `nvim.main` prefix is applied only when
  `nvim.main` is non-empty.
- Change the startup load list entry `"lspconfig"` to `"lsp"`.

### Bootstrap (`lua/bootstrap.lua`)

- Change `nvim.load "lazy"` to `nvim.load "lazyconf"`.

### lazy.nvim configuration (`lua/lazyconf/init.lua`)

- Remove `vim.g.galaxypath` from `performance.rtp.paths`.
- Change the lockfile template path from `nvim.fs.main .. "/lazy/lockfile.json"`
  to `nvim.fs.main .. "/lazyconf/lockfile.json"`.

### Framework plugin references

- `lua/framework/plugins/alpha/init.lua`:
  `nvim.autoload("plugins/alpha/styles")` →
  `nvim.autoload("framework/plugins/alpha/styles")`.
- `lua/framework/plugins/alpha/styles/dashboard.lua`:
  `"plugins." .. nvim.opt.provider.picker .. ".pickers.bookmarks"` →
  `"framework.plugins." .. ...`.
- `lua/framework/plugins/nvim-cmp/init.lua`:
  `nvim.load "plugins.nvim-cmp.dependencies"` →
  `nvim.load "framework.plugins.nvim-cmp.dependencies"`.
- `lua/framework/plugins/telescope/init.lua`:
  `nvim.load "plugins.telescope.sources"` →
  `nvim.load "framework.plugins.telescope.sources"`.
- `lua/framework/mappings/whichkey/bookmark.lua`:
  `"plugins.%s.pickers.bookmarks"` → `"framework.plugins.%s.pickers.bookmarks"`.

### Legacy plugin builder (`lua/plugins/init.lua`)

- `require("galaxy.configure.plugins")` → `require("configure.plugins")`.
- `require("galaxy.utils.setup")` → `require("utils.setup")`.
- Module prefix `"galaxy.plugins."` → `"framework.plugins."`.
- Update the header comment so it no longer claims the builder is legacy in a
  galaxy sense; it remains the owner of the framework factories.

### Branding and documentation

- `lua/behaviors/commands/about.lua`: replace the galaxyvim name, repository,
  docs, discussions, Reddit, and Telegram entries with the user's repository
  (`GeneralKaos666/nvim-config`). Remove dead community links.
- `README.md`: rewrite as the user's own Neovim configuration. Keep a short
  Credits section naming galaxyvim as the upstream framework, per GPL-3.0.
- Remove `galaxy` wording from comments that describe live behavior.

### Zero-galaxy guarantee

After the refactor, all of the following must hold:

- `vim.g.galaxypath` is unset; no code assigns or reads it.
- No clone or install command runs for galaxyvim.
- `vim.opt.rtp:get()` contains no `galaxyvim` entry.
- lazy.nvim's `performance.rtp.paths` contains no galaxy path.
- No `require("galaxy...")` call exists.
- No module path contains `galaxy`.
- `rg -n galaxy init.lua lua lockfile.json snippets` returns no matches.
- The clone at `~/.local/share/nvim/galaxyvim` remains on disk, untouched and
  unreferenced.

## Behavior change

The local fork's edits become active because the clone no longer shadows it.
Expected differences:

- `wrap = false` and `showbreak = ""`.
- The duplicated zsh `BufRead`/`BufNewFile` autocmd block is absent (covered by
  `vim.filetype.add`).
- Corrected version guard (`major == 0` branch).
- `cc`/`gcc`/`clang` toolchain prerequisite check.
- `(vim.uv or vim.loop).hrtime()` usage.

These are intentional and already present in the local copy.

## Verification

1. `luac -p` passes for every moved `.lua` file.
2. `nvim --headless` starts with no error output.
3. `debug.getinfo(nvim.dofile).source` points at
   `~/.config/nvim/lua/core.lua`.
4. `nvim.plugins` still contains 55 entries.
5. `vim.opt.rtp:get()` contains no `galaxyvim` entry.
6. `EditConf` targets resolve: `project`, `configs`, `bootstrap`, `options`,
   `settings`, `plugins`, `mappings`.
7. `rg -n galaxy init.lua lua lockfile.json snippets` returns no matches.
8. `:About` shows `GeneralKaos666/nvim-config`, not galaxyvim.
9. Interactive launch: dashboard renders, major keymaps work, LSP attaches.

## Git and publishing

1. Commit current work-in-progress changes on `main`.
2. Create branch `refactor/own-config`.
3. Commit in two steps: file moves first, reference rewrites second.
4. Add remote `origin` =
   `https://github.com/GeneralKaos666/nvim-config.git`.
5. Fetch `origin/master` and compare histories. Local `main` and remote `master`
   are unrelated or divergent; do not force-push without explicit confirmation.
6. Push only after the user approves the comparison result.

## Risks and mitigations

- **Namespace collisions.** `lazy` and `lspconfig` are renamed to `lazyconf` and
  `lsp`. Factory modules stay out of lazy's import path under
  `lua/framework/plugins/`.
- **Dual plugin loader.** `lua/plugins/init.lua` still builds framework specs
  from `configure/plugins.lua`; this is preserved and only its module prefix
  changes.
- **Shadowed edits activated.** Covered by the verification checklist and an
  interactive launch.
- **Unrelated remote history.** Compare before pushing; never force-push
  without confirmation.
- **License.** `LICENSE` is GPL-3.0 from the galaxyvim starter. Keep it and
  retain attribution to the upstream project.

## Rollback

- All work lands on `refactor/own-config`; `main` keeps the pre-refactor state
  after the WIP commit.
- The clone at `~/.local/share/nvim/galaxyvim` is untouched and can be restored
  as the active framework by reverting the branch.
