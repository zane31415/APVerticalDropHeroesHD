# Vertical Drop Heroes HD — Archipelago

An [Archipelago](https://archipelago.gg/) randomizer for **Vertical Drop
Heroes HD** by Nerdook.

Traits, powers and permanent upgrades become Archipelago items; the merchants,
shortcut crystals and level exits that used to grant them become checks. The
Archipelago client is compiled into the game itself — **there is no separate
client to run.** Connect from the in-game Options menu and play.

> **Windows only.** See [Platform support](#platform-support).
>
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
- **Shortcut crystals** are checks, and still cost coins to light, so a
  crystal is a real trade-off against shopping. `Progressive Shortcut` items
  are what actually let you start deeper, and *using* a shortcut you already
  own is free.
- **Clearing a level** checks a location, whether you killed the Guardian or
  opened the portal with keys.
- Every shop **shows the item it is about to hand over**, including whose
  world it belongs to.

Options: `include_shortcuts`, `include_level_clears`.

---

## Installing

### 1. The apworld (whoever generates the multiworld)

Drop `vertical_drop_heroes.apworld` from the
[latest release](https://github.com/zane31415/APVerticalDropHeroesHD/releases)
into your Archipelago install's `custom_worlds/` folder.

### 2. The game (every player)

Some pieces belong to other projects and are not ours to redistribute, so you
fetch those yourself:

- **Python** — <https://www.python.org/downloads/>.
  During setup, **tick "Add python.exe to PATH"**.
- **UndertaleModTool**, CLI build —
  [releases](https://github.com/UnderminersTeam/UndertaleModTool/releases).
  Grab `UTMT_CLI_<version>-Windows.zip`.
- **`gm-apclientpp.dll`, the 32-bit build** —
  [releases](https://github.com/black-sliver/gm-apclientpp/releases).
  **The 64-bit build will not work** — the GameMaker 1.4 runner is 32-bit.

Then:

1. **Copy your whole game folder** somewhere outside Steam and work on the
   copy. Steam can "verify" your real install and quietly undo everything.
2. **Extract `vdh-ap-patcher.zip` into that game folder.**
3. Put **`gm-apclientpp.dll`** in the same folder, next to `data.win`.
4. Extract **UndertaleModTool** into `build\utmt\`.
5. **Double-click `patch.bat`.**

You should end up with this, and nothing to type:

```
Vertical Drop Heroes HD\
    data.win
    Vertical Drop Heroes HD.exe
    gm-apclientpp.dll
    patch.bat
    build\
        build.py
        utmt\UndertaleModCli.exe
    gml\
```

The patcher needs no configuration because it is sitting in the folder it
patches. If you would rather keep it elsewhere, set `VDH_GAME_DIR` to the
folder holding `data.win` and run `python build\build.py`.

### 3. Connect

Launch the game, go to **Game Options → Archipelago**, fill in Server and Slot,
and choose Connect. `Ctrl+V` pastes. After that, picking **Single Player**
connects for you automatically.

Leave Slot empty and the mod stays completely dormant: it never even loads the
DLL, and the game plays as vanilla.

---

## Platform support

**Windows only.**

The game has no Linux build, so on Linux the Windows version under Proton is
the only target -- and that is what this patches, so it should work, though it
is untested.

macOS is the real gap. The game does ship a Mac build, but
[gm-apclientpp](https://github.com/black-sliver/gm-apclientpp/releases)
publishes Windows binaries only, so somebody would have to build the `.dylib`
themselves from its `build-posix.sh`. Beyond that the port is small: the DLL
name is already configurable via `DllPath` in `archipelago.ini`, and the
patcher would need to look for `game.ios` inside the `.app` bundle instead of
`data.win`. Not planned.

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

`mod/apworld/vertical_drop_heroes/defs.py` is the single source of truth for
every item and location id. `gen_gml.py` bakes those ids into GML and the
apworld imports the same module, so the two halves cannot disagree. See
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

## License

[MIT](LICENSE), covering the mod only -- the GML, the patcher and the
Archipelago world. Not the game.
