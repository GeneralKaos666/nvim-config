# nvim-config

Galaxyvim-based Neovim config. The live config lives in `nvim/` in this repo (mirrored from `~/.config/nvim`).

## Requirements

- Neovim 0.11+ (tested on 0.12.5)
- Nerd Font (recommended)
- `git`, `rg`, `node`, `npm`

## Install

Option A — use as your main config:

```sh
mv ~/.config/nvim ~/.config/nvim.backup
cp -r nvim ~/.config/nvim
nvim
```

Option B — try without replacing your current config:

```sh
NVIM_APPNAME=GeneralKaos666/nvim-config/nvim nvim
```

On first start `nvim/init.lua` clones `galaxyvim` into `stdpath("data") .. "/galaxyvim"`, prepends it to `rtp`, and loads `require("galaxy")`.

## Layout

```text
nvim/
├── init.lua                  # bootstraps galaxyvim, loads galaxy module
├── .gitignore                 # excludes lazy installs, shada, swap
├── LICENSE                   # GPLv3
├── README.md                  # upstream galaxyvim starter (mirrored)
├── lockfile.json              # 79 pinned plugins
├── dictionary/words           # spell word list
├── snippets/                  # luasnip + snipmate + vscode snippets
└── lua/
    ├── galaxy/                # framework: bootstrap, configure, behaviors,
    │                          # mappings/whichkey, lspconfig, plugins/*,
    │                          # utils, lazy/
    └── plugins/               # local extras: avante, mcphub, silkcircuit,
                               # tether (+ init)
```

`nvim/lua/galaxy/lazy/lockfile.json` is the framework lockfile; `nvim/lockfile.json` is the active pin set.

## Notes

- `nvim/README.md` is the upstream starter template, kept as mirrored from the live config.
- Excluded from the repo: `.git/`, `.superpowers/`, `docs/superpowers/`.
- Review code before installing a config you cloned.
