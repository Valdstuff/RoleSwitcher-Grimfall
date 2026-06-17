# Role Switcher

A per-level role automation addon for **World of Warcraft: Wrath of the Lich King (3.3.5a)**.

Role Switcher automatically sets your combat role (Tank, Heal, or DPS) as you level, using the server's classless-role API (`SetClasslessRole`). It is built for custom servers where any class can fill any role — handy for power-leveling builds that change role at certain levels.

## Features

- **Automatic role switching** by level: as you ding, Role Switcher applies the role you've assigned to that level.
- **Per-level configuration** for levels 8–59 — assign **Tank**, **Heal**, or **DPS** to each level from the config panel.
- Sensible default table (even levels DPS, odd levels Tank) that you can fully customise.
- Compact **on-screen widget** showing your current level and active role, with a colour-coded icon.
- **Pause toggle** (the `P` button) to temporarily stop automatic switching.
- **Config button** (the `C` button) opens the scrollable per-level panel.
- Below level 8 the widget shows *Pending*; at level 60 it deactivates (max level needs no switching).
- Settings are saved **per character**.

> **Note:** This addon depends on the custom `SetClasslessRole` API. It only does anything on servers that implement classless roles.

## Screenshot

The per-level configuration panel — set the role applied at each level for odd (O) and even (E) levels:

![Role Switcher configuration panel](https://github.com/user-attachments/assets/a0cdcee6-ec3f-40e7-8f05-433514ba3cd9)

## Installation

1. Download or clone this repository.
2. Copy the `RoleSwitcher` folder into your WoW directory under `Interface\AddOns\`, so the path is `Interface\AddOns\RoleSwitcher\RoleSwitcher.toc`.
   - If you downloaded a ZIP from GitHub, the extracted folder may be named `RoleSwitcher-main`. Rename it to `RoleSwitcher`.
3. Restart the game or reload the UI (`/reload`) and enable **Role Switcher** on the character-select AddOns list.

## Usage

Role Switcher runs automatically — there are no slash commands. Use the on-screen widget:

- **`C`** — open the per-level configuration panel and assign Tank / Heal / DPS to each level.
- **`P`** — pause or resume automatic role switching.
- CTRL+Click to drag the widget to reposition it.

## Author

Valdstein - AI was used in the creation of this addon

## License

Released under the MIT License. See [LICENSE](LICENSE).
