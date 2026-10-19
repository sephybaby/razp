# razp
it is a cherry red dashboard for hyprland, which can be connected to waybar (the files are already added in the repo)

<img width="1882" height="701" alt="image" src="https://github.com/user-attachments/assets/f167399f-6877-4330-9778-b46bbdbc9fc8" />

inital looks, is currently in work

## Needs

- Hyprland, Waybar, Quickshell, qt6-5compat
- playerctl, networkmanager, iw, bluez, bluez-utils, wireplumber, brightnessctl, power-profiles-daemon
- Optional: iwgtk, blueman, kitty, obsidian, a Nerd Font

```sh
sudo pacman -S hyprland waybar quickshell qt6-5compat playerctl networkmanager iw \
    bluez bluez-utils wireplumber brightnessctl power-profiles-daemon \
    blueman kitty ttf-jetbrains-mono-nerd
paru -S iwgtk
```

## Install

```sh
# 1. get razp
git clone https://github.com/sephybaby/razp.git ~/.config/quickshell/razp

# 2. set your own paths (todoFolder, quoteFile) near the top of the file
nano ~/.config/quickshell/razp/shell.qml

# 3. start razp, then open it
qs -c razp -d
qs -c razp ipc call razp toggle
```

## Waybar button

```sh
cp ~/.config/quickshell/razp/waybar/razp-toggle.sh ~/.config/waybar/
chmod +x ~/.config/waybar/razp-toggle.sh
```

Add to `~/.config/waybar/modules.json`:

```json
"custom/razp": {
  "exec": "echo ✦",
  "interval": "once",
  "format": "✦",
  "tooltip": false,
  "on-click": "~/.config/waybar/razp-toggle.sh"
}
```

Add `"custom/razp"` to `modules-right` in `config.jsonc`, and `#custom-razp` to your pill rule in `style.css`. Then:

```sh
pkill waybar && waybar & disown
```

## Autostart

Add to `~/.config/hypr/hyprland.conf`:

```
exec-once = qs -c razp -d
```
---
