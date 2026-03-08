<p align='center'>
<img src="https://img.shields.io/badge/Maintained%3F-YES-cyan?style=for-the-badge">
<img src="https://img.shields.io/github/license/AndroidGeeksYT/dotfile_tmux?color=cyan&style=for-the-badge">
<img src="https://img.shields.io/github/stars/AndroidGeeksYT/dotfile_tmux?color=cyan&style=for-the-badge">
<img src="https://img.shields.io/github/forks/AndroidGeeksYT/dotfile_tmux?color=cyan&style=for-the-badge">
<img src="https://img.shields.io/github/issues/AndroidGeeksYT/dotfile_tmux?color=cyan&style=for-the-badge">
</p>

<p align="center">
  <img src="https://github.com/AndroidGeeksYT/AndroidGeeksYT/blob/main/assets/gif/shiroko.gif?raw=true" width="400" alt="Shiroko">
  </p>

<p>
<img src="https://github.com/AndroidGeeksYT/dotfile_tmux/blob/main/assets/sample.png">
</p>

---

## ⚙️ Requirements

- `tmux`
- A Nerd Font (e.g., [Hack Nerd Font](https://www.nerdfonts.com/))
```bash
pkg update && pkg upgrade -y
pkg install tmux
```

---

## 🚀 Quick Start

```bash
# Clone this repo
git clone https://github.com/AndroidGeeksYT/dotfile_tmux ~/.config/tmux/
# tpm
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
```
---

## 📂 Session Management
- `Ctrl + b + s`: List sessions to switch or manage.
- `Ctrl + b + $`: Name/Rename the current session.
- `Ctrl + b + d`: Detach from the session but keep it running.
- `Ctrl + b + (`: Switch to the previous session.
- `Ctrl + b + )`: Switch to the next session.
- `Ctrl + b + L`: Switch to the last used session.

## 🪟 Window Management
- `Ctrl + b + c`: Create a new window.
- `Ctrl + b + ,`: Rename the current window.
- `Ctrl + b + w`: Choose a window from a list.
- `Ctrl + b + n`: Go to the next window.
- `Ctrl + b + p`: Go to the previous window.
- `Ctrl + b + l`: Go to the last active window.
- `Ctrl + b + 0-9`: Select window by index number.
- `Ctrl + b + f`: Find a window by name.
- `Ctrl + b + &`: Kill/Close the current window.
- `Ctrl + b + .`: Move a window (change its index number).

## 🪟 Pane Management
- `Ctrl + b + %`: Vertical split.
- `Ctrl + b + "`: Horizontal split.
- `Ctrl + b + o`: Cycle through open panes.
- `Ctrl + b + ;`: Move to the previously active pane.
- `Ctrl + b + x`: Kill the current pane.
- `Ctrl + b + z`: Zoom (Toggle fullscreen) the active pane.
- `Ctrl + b + !`: Convert a pane into a new window.
- `Ctrl + b + {`: Move current pane left.
- `Ctrl + b + }`: Move current pane right.
- `Ctrl + b + Space`: Cycle through preset pane layouts.

## 📋 Copy & Search (Buffer)
- `Ctrl + b + [`: Enter Copy Mode (for scrolling and selecting).
- `Ctrl + b + ]`: Paste the most recent buffer.
- `Ctrl + b + #`: List all copy buffers.
- `Ctrl + b + =`: Choose a specific buffer to paste.

## ⚙️ System & Help
- `Ctrl + b + ?`: View all keybindings currently bound.
- `Ctrl + b + :`: Enter the tmux command line.
- `Ctrl + b + r`: Force a redraw of the screen.
- `Ctrl + b + t`: Show the digital clock.

## 🔌 TPM (Tmux Plugin Manager)
- `Ctrl + b + I`: (Capital I) Install new plugins.
- `Ctrl + b + U`: Update existing plugins.
- `Ctrl + b + alt + u`: Uninstall plugins not in your config file.

---

## 🎖️ Credits
- Colorscheme: Catppuccin for Tmux – for the aesthetic status bar and modules.
- Plugin Management: Tmux Plugin Manager (TPM) – for handling the plugin ecosystem.
- Optimization: Performance tweaks for Termux inspired by the Android/Termux community.

---

## :gift_heart: Support

If you would like to support it via donation

<p>
<img src="https://github.com/AndroidGeeksYT/AndroidGeeks-Kickstart-Nvim/blob/main/img/donate.jpg">
</p>
