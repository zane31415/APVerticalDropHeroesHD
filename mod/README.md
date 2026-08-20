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

**Both mirrors are slot-specific.** `ap_reset_tallies` (received items) and
`ap_reset_sent` (checked locations) are cleared on every connect and rebuilt
from the server. Clearing only the first meant a reconnect to a *different*
slot inherited the old slot's checked set: buying from the Apothecary on a
fresh seed would skip to Upgrade 3 because the previous slot had checked 1
and 2. Safe to clear unconditionally, because apclientpp replays the whole
checked set through `ap_location_checked` right after `ap_slot_connected`,
and omits it only when the set is genuinely empty.

**Merchant locations are purchase order, not skill identity.** Naming them
`Unlock: <skill>` made all 50 sphere 0, because you can buy any offered skill
on level 1 and no honest requirement could be attached. They are now
`Level N Merchant Unlock M`, keyed to how many unlocks you have bought.

That gate is the game's own. `spawn_shop` caps unlocks at
`(global.unlocked + merchantSpawned) < min(50, enemyLevel * 5)`, so the Nth
unlock is unreachable until level `ceil(N/5)`. Exposing an existing constraint
beats inventing a parallel one. Sphere 0 fell from 82 locations to 47.

**Prices come from purchases made, not items received.** Vanilla priced the hub
shops off `global.<x>level`, which AP drives from received items — so checking
five tiers while receiving none would have meant paying tier-1 prices forever.
The same applies to `global.unlocked`, which sets both the unlock price and the
merchant spawn cap above, so `ap_refresh_counters` keeps it equal to locations
checked. Anything the player's *progress* should scale with has to count
checks; only the player's *power* counts items.

**Level clears key to the portal, not the boss.** The portal tile reads
"Defeat the *boss* OR Unlock with 5 Keys!", so hooking the Guardian's death
would silently miss every key-opened exit.

**Self-contained save location.** The patch clears the
`UseAppDataSaveLocation` info flag, which vanilla ships set. That moves
`working_directory` from `%APPDATA%\Vertical_Drop_Heroes_HD\` to the game
folder, so the modded build keeps `vdh_save_11.ini`, `archipelago.ini` and
`ap_debug.log` beside its own exe and shares nothing with an untouched Steam
install. The modded build therefore starts from a blank save rather than
inheriting Steam unlocks — which is what an Archipelago run wants anyway.

**The menu owns input before the stock menu does.** The Archipelago page is
reached from Options, and its handler is *prepended* to btnStartMenu's Step so
it can `exit` the whole event. A script-level `exit` only leaves the script, so
without the prepend a single keypress would both type a character and move the
stock menu cursor underneath.

**Offline still works.** Every hook is guarded by `global.ap_enabled`, and an
install with no `Slot` configured never even calls `external_define`. A missing
DLL cannot break a vanilla playthrough.

## Verified

Statically:

- DLL/exe architecture match (both PE `014c`; the 64-bit DLL will not load).
- `__cdecl` calling convention, from `include/gm-apclientpp.h`.
- Patch applies with `ThrowOnNoOpFindReplace = true`, so every find/replace
  hook site is confirmed to have matched real vanilla code.
- Boot hooks cover both `rmMenu` (btnStartMenu) and `rmGameplay`
  (obGameControl); obGameControl exists in the gameplay rooms *only*, verified
  by walking `Data.Rooms`, so menu-side hooks are required or the mod is inert
  until a run starts.
- Patched `data.win` decompiles back with every hook in place.
- Item/location balance is non-negative across all 12 option combinations.
- Logic solvable across all 36 option combinations; 47 sphere-0 locations
  spread across all four categories; deepest requirement 8 of 15 upgrades.

At runtime:

- Connects to a live server, sends checks and receives items across all
  categories (merchant unlocks, all three hub shops, shortcuts, level clears).

## Getting there: the Steam DRM trap

The shipped exe is Steam-DRM-wrapped. It calls
`SteamAPI_RestartAppIfNecessary(311480)` on launch, Steam takes over, and Steam
runs *its own* registered copy from `steamapps\common` — so double-clicking a
patched exe silently runs the UNPATCHED Steam install. Every symptom pointed
inward (no log file, invisible overlay, ini ignored, saves still in `%APPDATA%`)
while the actual cause was that the patched `data.win` was never loaded at all.

`build.py` now writes `steam_appid.txt` beside the exe, which makes that check
return false so the local copy runs.

The tell, in hindsight: clearing `UseAppDataSaveLocation` — a *runner-level*
header flag, nothing to do with any GML — also appeared to do nothing. When a
change at that layer has no effect, the runner is not reading your file, and no
amount of fixing things inside the file will help.

## Known unknowns / next steps

- **`ap_debug.log`** is written beside the exe on every launch, fresh each run.
  It records how far `ap_boot` got and what the ini contained. If the mod
  appears to do nothing, read that file first — if it does not exist at all,
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
