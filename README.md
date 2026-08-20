# Vertical Drop Heroes HD — Archipelago

An [Archipelago](https://archipelago.gg/) randomizer for **Vertical Drop
Heroes HD** by Nerdook.

Traits, powers and permanent upgrades become Archipelago items; the merchants,
shortcut crystals and level exits that used to grant them become checks. The
Archipelago client is compiled into the game itself — **there is no separate
client to run.** Connect from the in-game Options menu and play.

> **This repository contains no game files.** You patch your own copy. See
> [Installing](#installing).

---

## What gets randomized

| | |
|---|---|
| **116 locations** | 50 merchant unlocks, 45 shop upgrades, 10 shortcut crystals, 10 level clears, 1 goal |
| **Items** | 50 traits/powers, 15 each of Progressive Damage / Max HP / Orb XP, 10 Progressive Shortcut |
| **Goal** | Defeat the Chosen One |

- **Merchants** sell an unlock rather than a specific skill. A merchant on
  level *L* fills one of *that level's* five slots, so where you shop matters.
- **Blacksmith / Apothecary / Monk** each check a location per purchase. Your
  actual damage, max HP and orb XP come from the items Archipelago sends.
- **Shortcut crystals** are checks; `Progressive Shortcut` items are what
  actually let you start deeper. Using a shortcut you already own is free.
- **Clearing a level** checks a location, whether you killed the Guardian or
  opened the portal with keys.
- Every shop **shows the item it is about to hand over**, including whose
  world it belongs to.

Options: `include_shortcuts`, `include_level_clears`, `trap_fill`,
`death_link` (declared but not yet implemented — leave it off).

---

## Installing

### 1. The apworld (whoever generates the multiworld)

Drop `vertical_drop_heroes.apworld` from the
[latest release](https://github.com/zane31415/APVerticalDropHeroesHD/releases)
into your Archipelago install's `custom_worlds/` folder.

### 2. The game (every player)

You need three things, two of which are not ours to redistribute:

1. **Your own copy of Vertical Drop Heroes HD.** Steam or DRM-free — both use
   the same GameMaker `data.win`.
2. **UndertaleModTool**, CLI build —
   [releases](https://github.com/UnderminersTeam/UndertaleModTool/releases).
   Take `UTMT_CLI_<version>-Windows.zip` and unzip it into the patcher's
   `build/utmt/`, so that `build/utmt/UndertaleModCli.exe` exists.
3. **`gm-apclientpp.dll`, the 32-bit build** —
   [releases](https://github.com/black-sliver/gm-apclientpp/releases).
   Put it beside the patcher's `README.txt`.
   **The 64-bit build will not work** — the GameMaker 1.4 runner is 32-bit.

Then grab `vdh-ap-patcher.zip` from the release and:

```powershell
# Copy your game folder somewhere OUTSIDE Steam first.
$env:VDH_GAME_DIR = "C:\path\to\your\Vertical Drop Heroes HD"
python build\build.py
```

> In `cmd.exe` use `set VDH_GAME_DIR=...`. Note that `set` in **PowerShell** is
> an alias for `Set-Variable` and does *not* set an environment variable, so
> the `$env:` form is required there.

Copy the game folder rather than patching your live Steam install: Steam will
happily verify or update `data.win` out from under you.

The patcher rewrites `data.win`, drops the DLL beside the exe, and writes a
`steam_appid.txt` (see [Steam DRM](#a-note-on-steam-drm)).

### 3. Connect

Launch the game, go to **Game Options → Archipelago**, fill in Server and Slot,
and choose Connect — or just pick **Single Player**, which connects for you.
`Ctrl+V` pastes. Details are saved to `archipelago.ini` beside the exe.

Leave Slot empty and the mod stays completely dormant: it never even loads the
DLL, and the game plays as vanilla.

---

## A note on Steam DRM

The Steam build's exe calls `SteamAPI_RestartAppIfNecessary`, which hands off
to Steam — and Steam then launches **its own** registered copy from
`steamapps\common`. Double-clicking a patched exe therefore silently runs the
*unpatched* game, with no error to tell you so.

`build.py` writes `steam_appid.txt` next to the exe, which makes that check
return false so your patched copy actually runs. If the mod ever appears to do
nothing at all, check that this file still exists, and read `ap_debug.log`
beside the exe — if that file is absent, the patched `data.win` is not what ran.

---

## Building from source

```bash
python mod/build/build.py      # patch a local game copy
python mod/build/package.py    # build out/ release artifacts
```

`mod/build/defs.py` — actually `mod/apworld/vertical_drop_heroes/defs.py` — is
the single source of truth for every item and location id. `gen_gml.py` bakes
those ids into GML; the apworld imports the same module. See
[mod/README.md](mod/README.md) for architecture and design notes, and
[HANDOFF.md](HANDOFF.md) for a full context dump.

**Never commit decompiled game code.** Verification dumps from
`UndertaleModCli dump` are Nerdook's source, not ours; `.gitignore` excludes
them.

---

## Credits

- **[Vertical Drop Heroes HD](https://store.steampowered.com/app/311480/)** by
  [Nerdook](https://nerdook.itch.io/) — not affiliated with this project.
- **[gm-apclientpp](https://github.com/black-sliver/gm-apclientpp)** and
  **[apclientpp](https://github.com/black-sliver/apclientpp)** by black-sliver,
  which do all the actual protocol work.
- **[UndertaleModTool](https://github.com/UnderminersTeam/UndertaleModTool)**
  by the Underminers team.
- **[Archipelago](https://archipelago.gg/)**.

This is an unofficial fan project. It ships no game assets and requires you to
own the game.
