# My Hyprland configuration

This repository stores the portable, user-authored parts of my Arch desktop configuration. Files are kept under `.config/` so they can be restored into `$HOME/.config` directly.

## Included

- **Hyprland** — monitor layout, keybindings, window behavior, idle, wallpaper, and night-light settings
- **Waybar** — module layout, styling, and power menu
- **Kitty** and **Dunst** — terminal and notification preferences
- **Desktop preferences** — MIME associations, PulseAudio control-panel layout, and Dolphin UI settings

## Restore

Review the files first, then copy them into your home configuration directory:

```bash
cp -a .config/. "$HOME/.config/"
```

`hyprpaper.conf` expects the wallpaper at `~/Pictures/wall.png`. Install the fonts referenced by Kitty, Waybar, and Dunst (including SF Pro Display and a Nerd Font) if you want the same appearance.

Browser profiles, cookies, tokens, application databases, logs, caches, and session state are deliberately excluded.
