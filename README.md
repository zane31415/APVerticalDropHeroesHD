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
| **181 locations** (default) | 50 merchant unlocks, 60 shop upgrades, 50 shrines, 10 shortcut crystals, 10 level clears, 1 goal |
| **Items** | 50 traits/powers, 20 each of Progressive Damage / Max HP / Orb XP, 10 Progressive Shortcut, 10 Progressive Level Access, filler and traps |
| **Goal** | Defeat the Chosen One |

The shop-upgrade and shrine counts are yaml settings, so the location and item
totals move with them.

- **Merchants** sell an unlock rather than a specific skill. A merchant on
  level *L* fills one of *that level's* five slots, so where you shop matters.
- **Blacksmith / Apothecary / Monk** each check a location per purchase. Your
  actual damage, max HP and orb XP come from the items Archipelago sends.
- **Shortcut crystals** are checks, and still cost coins to light, so a
  crystal is a real trade-off against shopping. `Progressive Shortcut` items
  are what actually let you start deeper, and *using* a shortcut you already
  own is free. A crystal appears on any level whose shortcut is still
  unchecked — one per run, as always.
- **Clearing a level** checks a location, whether you killed the Guardian or
  opened the portal with keys.
- **Levels are locked** by default. `Progressive Level Access` items open
  levels 2-11 in order; taking the exit portal of a level whose successor is
  still locked counts the clear and then **ends the run** — back to the village
  and the hero-select screen, exactly as if you had died. Coins, unlocks and
  shop tiers are permanent as always, so nothing is lost but the hero.
- **Shrines** are checks. The first few you activate on each level check a
  location, and they still do exactly what they always did — the check rides
  along. Once a level's are used up its shrines are back to being ordinary
  shrines; they keep spawning and keep working either way.
- **DeathLink**, when enabled, sends your death screen's own sentence out to
  the multiworld, and kills your hero when someone else's arrives.
- **Filler** is Coin Cache, Shrine Boost (a random shrine effect, free),
  Mana Refill and Skeleton Key. **Traps** are Alarm Trap, which does what
  stepping on an alarm does — including the permanent `global.alarms` bump
  that gives every enemy for the rest of the run extra health.
- Every shop **shows the item it is about to hand over**, including whose
  world it belongs to.

### Options

| option | default | what it does |
|---|---|---|
| `include_shortcuts` | on | shortcut crystals are locations |
| `include_level_clears` | on | clearing each of levels 1-10 is a location |
| `shop_upgrade_tiers` | 20 | tiers each hub shop sells, 15-30 |
| `shop_price_step` | 25 | coins the price climbs per tier already bought |
| `shop_price_cliff` | 25 | extra coins-per-tier added every 10 tiers |
| `level_locks` | on | levels 2-11 need `Progressive Level Access` |
| `shrine_checks` | 5 | shrines per level that also check a location, 0-10 (0 = off) |
| `trap_fill` | 0 | percent of leftover filler slots that become traps |
| `death_link` | off | standard Archipelago DeathLink |

The two price settings reproduce vanilla at their defaults: the Nth upgrade
from a shop costs `N * (step + floor(N / 10) * cliff)`. Vanilla's price wall is
that cliff, and it fires every **ten** tiers rather than fifteen — with the old
15-tier cap it therefore hit exactly once, at tier 10. Set `shop_price_cliff`
to 0 for a straight line.

---

## Installing

### 1. The apworld (whoever generates the multiworld)

Drop `vertical_drop_heroes.apworld` from the
[latest release](https://github.com/zane31415/APVerticalDropHeroesHD/releases)
into your Archipelago install's `custom_worlds/` folder.

### 2. The game (every player)

You need **Python** — <https://www.python.org/downloads/>, and during setup
**tick "Add python.exe to PATH"**. Nothing else: UndertaleModTool and
`gm-apclientpp.dll` are inside the patcher zip.

1. **Copy your whole game folder** somewhere outside Steam and work on the
   copy. Steam can "verify" your real install and quietly undo everything.
2. **Extract `vdh-ap-patcher.zip` into that game folder.**
3. **Double-click `patch.bat`.**

You should end up with this, and nothing to type:

```
Vertical Drop Heroes HD\
    data.win
    Vertical Drop Heroes HD.exe
    gm-apclientpp.dll        <-- from the zip
    patch.bat
    build\
        build.py
        utmt\UndertaleModCli.exe
    gml\
    third-party\             <-- licenses, and UTMT's GPL source
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
nothing at all, check that this file still exists, then read `ap_debug.log` —
if it is absent, the patched `data.win` is not what ran.

**`ap_debug.log` is not beside the exe.** GameMaker redirects the game's file
writes into its own save area, which for this build is
`%LOCALAPPDATA%\Vertical_Drop_Heroes_HD\`. `archipelago.ini` is there too, and
it is the copy the game actually reads — editing the one next to the exe does
nothing. **Game Options → Archipelago** prints the exact path, along with the
build stamp, which is the fastest way to confirm the patch you just ran is the
one the game is loading.

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

The release zip additionally bundles two components that belong to other
projects, unmodified and under their own licenses:

| component | license |
|---|---|
| [UndertaleModTool](https://github.com/UnderminersTeam/UndertaleModTool) 0.9.1.2 | GPL-3.0 |
| [gm-apclientpp](https://github.com/black-sliver/gm-apclientpp) v0.4.9-3 (win32) | MIT |

Both are vendored in [mod/third-party/](mod/third-party/) as the exact archives
their authors published, alongside their licenses and -- for the GPL binary --
its Corresponding Source. See
[mod/third-party/README.md](mod/third-party/README.md). The patcher runs
`UndertaleModCli.exe` as a separate process, so the GPL covers that component
alone and not this project's own code.
