# Archipelago mod for Vertical Drop Heroes HD

Patches the game's GameMaker: Studio 1.4 `data.win` to speak the Archipelago
protocol via [gm-apclientpp](https://github.com/black-sliver/gm-apclientpp).

```
mod/
  build/
    gen_gml.py    emits gml/ap_tables.gml from defs.py
    patch.csx     UndertaleModTool patch script
    build.py      patch a data.win
    package.py    build out/ for distribution
    utmt/         UndertaleModCli (not committed -- see below)
  gml/            the in-game client (hand-written, plus generated ap_tables.gml)
  apworld/vertical_drop_heroes/
    defs.py       canonical item/location tables and ids  <-- single source of truth
    ...           the rest of the Archipelago world
```

`defs.py` lives in the apworld package and has exactly one copy. `gen_gml.py`
imports it from there; `package.py` copies it into the patcher bundle at
package time. There is deliberately no second checked-in copy to drift.

## Building

```bash
python mod/build/build.py      # patch the local game copy
python mod/build/package.py    # build out/ for distribution
```

`out/` is gitignored because `package.py` reproduces it in seconds:

| file | who needs it |
|---|---|
| `out/vertical_drop_heroes.apworld` | whoever generates the multiworld |
| `out/vdh-ap-patcher.zip` | every player |

### Two build inputs are not committed

Both are third-party and gitignored; fetch them once:

- **UndertaleModCli** → `mod/build/utmt/` (or set `UTMT_CLI`).
  [releases](https://github.com/UnderminersTeam/UndertaleModTool/releases) —
  take `UTMT_CLI_<version>-Windows.zip`. ~130 MB, GPL-3.0.
- **`gm-apclientpp.dll`, 32-bit** → repo root (or set `VDH_DLL`).
  [releases](https://github.com/black-sliver/gm-apclientpp/releases)

`build.py` also honours `VDH_GAME_DIR` if your game copy lives elsewhere.

## Distribution

`out/` contains **no game files, and no patched `data.win`**. A patched
`data.win` is a derivative of the game's own content, so shipping one would be
redistributing the game. Players run the patcher against their own copy — the
same approach the rest of the Archipelago ecosystem uses.

See the [setup guide](apworld/vertical_drop_heroes/docs/setup_en.md) for the
player-facing walkthrough.

## How it fits together

`defs.py` assigns every id. `gen_gml.py` bakes those ids into `ap_tables.gml`,
and the apworld imports the same module directly, so the two halves cannot
disagree about what location `8830042` is.

`build.py` always patches from `data.win.vanilla` (snapshotted on first run),
because the patch appends to existing code entries and is not idempotent.

## The one interesting problem

The documented gm-apclientpp event flow is:

```gml
execute_string(apclient_poll());
```

**`execute_string` does not exist in GameMaker: Studio.** It was a GM7/8
function, removed in GM:S; the runner's builtin function table confirms it is
absent from this game. The README anticipates this ("For GMS, an alternative to
this is provided") but does not spell the alternative out.

Reading `src/gm-apclientpp.cpp`: every event handler calls
`queue_script(script, name, json)`, and `apclient_poll()` pops exactly one
queued event, setting `script_name` and `script_data` alongside the string it
returns. So the return value can be ignored entirely and used only as a
"was there an event?" flag, with the actual dispatch driven by
`apclient_json_source()` and the json proxies:

```gml
while (apclient_poll() != "") { ap_dispatch(); }   // ap_step.gml
```

`ap_dispatch` switches on `apclient_json_source()` and pulls arguments back
through `apclient_json_number_at` / `apclient_json_proxy`. See
`gml/ap_dispatch.gml`.

## Design notes

**Tally, then derive.** `ap_receive_item` only increments counters;
`ap_apply_state` recomputes all game state from those counters. This matters
because Archipelago replays your entire item history on every connect —
replaying into a tally is idempotent, replaying into `hpmax += 7` is not.

**The Merchant's stock predicate changed.** Vanilla offered skills whose
unlock flag was 0. Under AP that is wrong in both directions: a skill the
server granted would disappear from the shop while its location was still
unchecked, and a checked location would be offered forever. So `set_merchant`
now filters on "location not yet checked" (`global.ap_sent_skill`), which is
fed both by our own checks and by the server's `ap_location_checked` event —
including the full checked set it sends on connect.

**Level clears key to the portal, not the boss.** The portal tile reads
"Defeat the *boss* OR Unlock with 5 Keys!", so hooking the Guardian's death
would silently miss every key-opened exit.

**Self-contained save location.** The patch clears the
`UseAppDataSaveLocation` info flag, which vanilla ships set. That moves
`working_directory` from `%LOCALAPPDATA%\Vertical Drop Heroes HD\` to the game
folder, so the modded build keeps `vdh_save_11.ini`, `archipelago.ini` and
`ap_debug.log` beside its own exe and shares nothing with an untouched Steam
install. The modded build therefore starts from a blank save rather than
inheriting Steam unlocks — which is what an Archipelago run wants anyway.

**Offline still works.** Every hook is guarded by `global.ap_enabled`, and an
install with no `Slot` configured never even calls `external_define`. A missing
DLL cannot break a vanilla playthrough.

## Verified

- DLL/exe architecture match (both PE `014c`; the 64-bit DLL will not load).
- `__cdecl` calling convention, from `include/gm-apclientpp.h`.
- Patch applies with `ThrowOnNoOpFindReplace = true`, so all ten hook sites are
  confirmed to have matched real vanilla code.
- Patched `data.win` decompiles back with every hook in place.
- Item/location balance is non-negative across all 12 option combinations.
- Logic is solvable across all 36 option combinations (50 sphere-0 locations).

## Not verified

The game has **not been run**. Everything above is static analysis and
round-trip verification of the rebuilt `data.win`. The runtime behaviour of
`external_define` against the DLL, and the live protocol exchange, are
untested. See "Known unknowns" below.

## Known unknowns / next steps

- **DLL path resolution.** GM:S 1.4 normally resolves a bare DLL name against
  the game folder, which is where `build.py` puts it. If the runner instead
  looks in the save area, set `DllPath` to an absolute path in
  `archipelago.ini`.
- **`ap_debug.log`** is written beside the exe on every launch, fresh each run.
  It records how far `ap_boot` got and what the ini contained. If the mod
  appears to do nothing, read that file first -- if it does not exist at all,
  the patched `data.win` is not the one that ran.
- **DeathLink** is exposed as a slot option and passed through `slot_data`, but
  is *not* wired in the GML. Nothing sends or receives it yet.
- **Trap item** (`Fragile Hero Trap`) sets `global.ap_pending_trap` but nothing
  consumes it yet. Leave `trap_fill` at 0 until it does.
- **Multiplayer/co-op** paths (`obServer`/`obClient`) are untouched; the mod
  assumes single player.
- The 50 skill locations carry no logic requirement, because the game genuinely
  lets you buy any offered skill from level 1. They do get progressively more
  expensive (`5 + 15 * global.unlocked` coins), which is a grind gate but not a
  logic gate.
