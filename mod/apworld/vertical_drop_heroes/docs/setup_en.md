# Vertical Drop Heroes HD — Setup Guide

## Do I need a client?

**No.** The Archipelago client is compiled into the game itself, so there is no
separate client process to run — launch the game and it connects on its own.

A text client is still useful for chat, `!hint`, and release commands, but
nothing about items or checks depends on it.

## Required

- A copy of **Vertical Drop Heroes HD** (Steam or DRM-free; both use the same
  GameMaker: Studio 1.4 `data.win`).
- Python 3.10+ (to run the patcher).
- `vdh-ap-patcher.zip`.
- **UndertaleModTool**, CLI build —
  [releases](https://github.com/UnderminersTeam/UndertaleModTool/releases).
  Take `UTMT_CLI_<version>-Windows.zip` and unzip it into the patcher's
  `build/utmt/`, so `build/utmt/UndertaleModCli.exe` exists.
- **`gm-apclientpp.dll`, the 32-bit build** —
  [releases](https://github.com/black-sliver/gm-apclientpp/releases).
  Put it next to the patcher's `README.txt`. The 64-bit build will *not* load:
  the GameMaker 1.4 runner is 32-bit (`Vertical Drop Heroes HD.exe` reports PE
  machine `014c`).

The last two are separate downloads because they belong to other projects and
are not ours to redistribute.

## Patching the game

1. Copy your whole `Vertical Drop Heroes HD` folder somewhere outside Steam.
   The patcher rewrites `data.win` in place. It snapshots the original to
   `data.win.vanilla` on first run, so repeat builds always start clean — but
   patching your live Steam install is still a bad idea, because Steam will
   happily overwrite or verify it out from under you.

2. Run the patcher, pointing it at that copy:

   ```bash
   set VDH_GAME_DIR=C:\path\to\your\Vertical Drop Heroes HD
   python build\build.py
   ```

   It regenerates the id tables, patches `data.win`, and copies the DLL next to
   the exe.

## Installing the apworld

Drop `vertical_drop_heroes.apworld` into your Archipelago install's
`custom_worlds/` folder. Only the person generating the multiworld needs it.

## Connecting

There is no in-game connect screen; connection details come from a config
file.

`archipelago.ini` does **not** live in the game folder. GameMaker writes it to
the save area, which on Windows is:

```
%LOCALAPPDATA%\Vertical Drop Heroes HD\archipelago.ini
```

(That folder name comes from the game's own GEN8 `filename` field, not from
your install path -- it is the same regardless of where you put the game.)

The file does not exist until the game has been run at least once. Either
launch the game once and let it write a template -- it also prints the full
path on screen -- or create the folder and file yourself now. Either way, fill
it in:

```ini
[Archipelago]
Host=archipelago.gg:38281
Slot=YourSlotName
Password=
```

`DllPath` is also accepted if you need to point at the DLL by absolute path.

Restart the game. A status line in the top-left shows `AP: connecting` →
`AP: handshaking` → `AP: connected`, and incoming items scroll underneath.

If `Slot` is left blank the mod stays completely dormant — it never even loads
the DLL — and the game plays as vanilla.

## What changed in the game

- **The Merchant** still sells a random trait/power, but buying one *checks a
  location* instead of unlocking the skill. The skill itself arrives as an
  Archipelago item. He stocks whatever you have not checked yet.
- **Blacksmith / Apothecary / Monk** likewise check a location per purchase;
  your damage, max HP and orb XP levels are driven entirely by the
  `Progressive Damage` / `Progressive Max HP` / `Progressive Orb XP` items you
  receive. Each stops selling once all its tiers are checked.
- **Shortcut crystals** check a location; `Progressive Shortcut` items are what
  actually raise how deep you can start.
- **Clearing a level** (taking its exit portal, by boss or by keys) checks a
  location, for levels 1–10.
- **Defeating the Chosen One** is the goal.

Because the server replays your whole item list on every connect, reconnecting
mid-session restores your unlocks and upgrades exactly.
