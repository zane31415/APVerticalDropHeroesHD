# Vertical Drop Heroes HD — Setup Guide

## Do I need a client?

**No.** The Archipelago client is compiled into the game itself, so there is no
separate client process to run — set up a Slot once, then choosing Single
Player connects you.

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

   In PowerShell:

   ```powershell
   $env:VDH_GAME_DIR = "C:\path\to\your\Vertical Drop Heroes HD"
   python build\build.py
   ```

   In `cmd.exe` it is `set VDH_GAME_DIR=...` instead. Note that `set` in
   PowerShell is an alias for `Set-Variable` and will *not* set an environment
   variable, so the `$env:` form is required there.

   It regenerates the id tables, patches `data.win`, and copies the DLL next to
   the exe.

## Installing the apworld

Drop `vertical_drop_heroes.apworld` into your Archipelago install's
`custom_worlds/` folder. Only the person generating the multiworld needs it.

## Connecting

Launch the game and go to **Game Options > Archipelago**.

```
Server:    archipelago.gg:38281
Slot:      YourSlotName
Password:  (leave empty if the room has none)
Connect
Back
```

Up/Down moves, Enter edits a field or activates a row, **Ctrl+V pastes**, Esc
goes back. Fields are saved as you leave them, so the details persist across
restarts, and `Connect` can be used again at any time to retarget a different
server without restarting the game.

You do not have to press `Connect`: if a Slot is filled in, choosing **Single
Player** connects automatically as the run starts. The mod deliberately does
*not* connect at launch, so the server's checked-location set never lands on
top of a session already in progress.

Status is shown live on that page, and as a small readout in the top-left
during play: `connecting` -> `handshaking` -> `connected`.

Everything is still written to `archipelago.ini` in the game folder, so you can
edit that by hand instead if you prefer. Leaving `Slot` empty keeps the mod
completely dormant -- it does not even load the DLL, and the game plays as
vanilla.

## What changed in the game

- **The Merchant** sells unlock purchases rather than specific skills. A
  Merchant standing on level L fills one of *that level's* five slots -- level
  1's five are on level 1, and only there. Once a level's five are taken, its
  Merchants have nothing left to sell. The traits and powers themselves arrive
  as Archipelago items.
- **Every shop shows what you are buying.** The Blacksmith, Apothecary, Monk
  and Merchant each display the actual item sitting on their next location,
  including whose world it belongs to.
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
