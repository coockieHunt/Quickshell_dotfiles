# Quickshell Desktop Configuration

> **Note**
>
> These dotfiles were made for a **Lenovo ThinkPad T14 Gen 2**.
>
> They are provided as-is, with no guarantee that they will work correctly on
> other hardware. Differences in displays, GPUs, audio, networking, battery
> management, and power controls may require some adjustments.
>
> In short: it works on my machine. From there, Linux may have its own ideas.

## Features

### Top bar

- Hyprland workspace controls
- Clock
- Media controls
- Battery and system indicators
- Notifications
- Power menu

### Control panel

Quick access to:

- Wi-Fi
- Bluetooth
- Volume
- Airplane mode
- Brightness
- TLP power profiles
- Notification history
- System information
- Process and performance information

### Desktop widgets

- Clock
- Weather
- System usage
- Network status

### Wallpaper tools

The wallpaper system includes:

- Wallpaper picker
- Random wallpaper selection
- Matugen color generation
- Shared colors between the interface and Hyprland borders

Changing the wallpaper can therefore also change the overall color palette of
the desktop.

### Other panels

- Application launcher
- Power/session menu
- Volume OSD
- Brightness OSD

### Power management

Optional power-related features include:

- Low-battery profile fallback
- Eco mode
- Brightness adjustments
- TLP power profiles
- Battery charge thresholds

### Battery charge modes

Two charge modes are available:

- **Travel** — 0 / 95%
- **Safe** — 75 / 80%

These make it easy to switch between normal use and a more battery-friendly
charging range.

---

## Screenshots

| Application launcher | Desktop and media controls |
| --- | --- |
| ![Application launcher](./screen/app.webp) | ![Desktop with media controls](./screen/desk_musique.webp) |

| Performance and quick settings | Desktop overview |
| --- | --- |
| ![Performance panel and quick settings](./screen/panel.png) | ![Desktop overview](./screen/ff.webp) |

| Power menu | Wallpaper picker |
| --- | --- |
| ![Power and session menu](./screen/reboot.webp) | ![Wallpaper picker](./screen/wp.webp) |

---

## Requirements

The setup requires:

- Linux with **Wayland**
- **Hyprland**
- **Quickshell**
- The Quickshell modules used by this configuration:
  - Wayland
  - Hyprland
  - UPower
  - MPRIS
  - PipeWire
  - Notifications

Common utilities:

- `bash`
- `curl`
- `cat`
- `ps`
- `nmcli`
- `bluetoothctl`
- `wpctl`
- `brightnessctl`
- `notify-send`
- `systemctl`
- `hyprctl`

For power management:

- **TLP**
- A running **Polkit authentication agent**

For wallpaper colors:

- **Matugen**

Optional integrations:

- `pavucontrol`
- `nm-connection-editor`
- `xdg-open`
- `hyprshutdown`
- A Quickshell-compatible lock screen at `~/.local/share/quickshell-lockscreen`

A wallpaper collection is expected in:

```text
~/Pictures/wallpapers
```

The weather widget uses **Open-Meteo** and therefore requires an internet
connection.

Some system readings rely on Linux `/proc` and `/sys` interfaces being
available.

---

## Install and run

Place this directory at:

```text
~/.config/quickshell
```

Then run:

```sh
cd ~/.config/quickshell
./create-config.sh
qs -p ~/.config/quickshell
```

The shell is designed to run inside a Hyprland session.

Some commands use Hyprland IPC and will therefore require adjustments when
used with another compositor.

---

## Configuration

The main configuration is stored in [`config.jsonc`](./config.jsonc). It can
be used to change:

- Colors
- Widget positions
- Refresh intervals
- Weather coordinates
- Default control-panel view
- Power fallback settings
- Eco levels
- Wallpaper palette labels

[`create-config.sh`](./create-config.sh) creates a default `config.jsonc` if
one does not already exist. If the file already exists, it leaves it untouched.

The wallpaper picker reads images from:

```text
~/Pictures/wallpapers
```

Selected wallpapers and generated theme colors are stored under:

```text
~/.cache
```

---

## TLP profiles, charge limits and Polkit

The quick-settings panel provides three power profiles:

- **Eco**
- **Balanced**
- **Performance**

Selecting a profile closes the panel and runs the corresponding `/usr/bin/tlp`
command through `pkexec`.

A running Polkit authentication agent is therefore required.

Battery charge modes use the same mechanism through `tlp setcharge`.

The configured modes are:

- **Travel** — 0 / 95%
- **Safe** — 75 / 80%

These thresholds are temporary TLP settings and may be replaced when TLP
reapplies its configured battery thresholds.

No passwordless sudoers rule is required.

Make sure that:

- TLP is installed;
- a Polkit authentication agent is running;
- the system allows the authenticated user to run `/usr/bin/tlp`.

The scripts currently expect:

```text
/usr/bin/tlp
/usr/bin/tlp-stat
```

Adjust [`scripts/power-profile.sh`](./scripts/power-profile.sh) if they are
installed elsewhere.

The active TLP profile is read with `tlp-stat -s` without elevation.

Charge threshold information is read from the battery's sysfs interface.

If the battery hardware or driver does not support charge thresholds, these
controls will not be available.

---

## Hardware and portability

Some parts of the configuration depend on the hardware exposing specific Linux
interfaces.

### GPU

GPU usage is currently read from AMD-style paths:

```text
/sys/class/drm/card*/device/gpu_busy_percent
```

This may therefore be unavailable on other GPUs or kernels.

### System information

Temperature, battery, brightness, and power information depend on what the
hardware and kernel expose.

### Adapting the configuration

When using this setup on another machine, check:

- `panels/Notifications.qml`
- `components/PowerSlider.qml`
- `scripts/`

Some paths and commands may need to be changed depending on the installation.

Power, logout, reboot, lock, network, Bluetooth, and brightness controls
perform real system actions.

So yes, the buttons actually do things.

---

## Layout

```text
shell.qml
```

Main application entry point.

```text
panels/
```

Bar, widgets, launcher, notifications, performance, wallpaper, OSD, and power
interfaces.

```text
components/
```

Reusable UI components.

```text
theme/Theme.qml
```

Loads the JSONC configuration and generated wallpaper colors.

```text
scripts/
```

Wallpaper, TLP power-profile, and lock-screen helpers.

---

## About the project

This configuration started from a simple idea: bring the different parts of my
desktop together instead of maintaining a collection of separate tools and
scripts.

The goal is not to provide a universal Hyprland setup.

It is simply a desktop environment that I can understand, modify, and adapt
without relying on a large pre-made configuration.

I prefer knowing how things work rather than having something that simply
works.

There are probably cleaner ways to do some of this.

I just haven't found them yet.

---

## License

MIT License. See [`LICENSE`](./LICENSE).
