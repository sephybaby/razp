# RAZP


A cherry-red dashboard for Hyprland, built with Quickshell. Opens from a button in Waybar. Shows music, Wi-Fi, volume, brightness, battery, Bluetooth, power profile, calendar, to-dos and an app launcher. Closes with `Esc` or by clicking outside.

<img width="1661" height="708" alt="razp" src="https://github.com/user-attachments/assets/aa40e914-84fc-45bf-910b-9516bd41a280" />

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
## Troubleshooting

**Nothing appears after `qs -c razp`.** That is normal. The dashboard starts hidden. Run `qs -c razp ipc call razp toggle` in a second terminal.

**`Cannot open: .../components/<song name>` warning.** Fixed in the current `MusicCard.qml`. If you still see it, update the repo.

**Clicking ✦ does nothing.** Check `cat /tmp/razp-toggle.log`. If the file doesn't exist, Waybar isn't running the script: run `waybar -l debug` and click the button.

**Wi-Fi / Bluetooth windows have no theme or don't open.** Check the folder is named `popup-theme` (lowercase), and that `iwgtk` / `blueman` are installed.

**Wi-Fi shows `-- dBm` or "Not connected".** Your interface probably isn't `wlan0`. See [Configuration](#configuration).

**razp doesn't close when clicking outside.** Your Hyprland / Quickshell may be too old for `HyprlandFocusGrab`. Update both.

**"Quickshell: Config reloaded" popup.** Shown when files change. The first line of `shell.qml`, `//@ pragma NoReloadPopup`, hides it.

**`WARN qt.qpa.wayland.textinput` in the terminal.** A harmless Qt warning.

---


