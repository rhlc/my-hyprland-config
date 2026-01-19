# My Hyprland Config

Personal configuration files for [Hyprland](https://hyprland.org/) and related tools.

## Structure

```
.
├── hypr/
│   ├── hyprland.conf      # Main Hyprland configuration
│   ├── monitors.conf      # Monitor setup
│   ├── workspaces.conf    # Workspace rules
│   ├── hypridle.conf      # Idle daemon config
│   ├── hyprpaper.conf     # Wallpaper config
│   └── hyprsunset.conf    # Blue light filter config
├── config.jsonc           # Waybar configuration
├── style.css              # Waybar styling
└── power_menu.xml         # Custom power menu
```

## Installation

Clone and symlink to your config directory:

```bash
git clone git@github.com:rhlc/my-hyprland-config.git
ln -sf $(pwd)/my-hyprland-config/hypr ~/.config/hypr
ln -sf $(pwd)/my-hyprland-config/config.jsonc ~/.config/waybar/config.jsonc
ln -sf $(pwd)/my-hyprland-config/style.css ~/.config/waybar/style.css
ln -sf $(pwd)/my-hyprland-config/power_menu.xml ~/.config/waybar/power_menu.xml
```

## Dependencies

- [Hyprland](https://hyprland.org/)
- [Waybar](https://github.com/Alexays/Waybar)
- [hyprpaper](https://github.com/hyprwm/hyprpaper)
- [hypridle](https://github.com/hyprwm/hypridle)
