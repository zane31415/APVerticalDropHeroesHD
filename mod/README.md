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
    vendor.py     unpacks third-party/ archives on demand
    utmt/         UndertaleModCli, unpacked (not committed -- see below)
  gml/            the in-game client (hand-written, plus generated ap_tables.gml)
  third-party/    vendored UndertaleModTool + gm-apclientpp archives, verbatim
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

### The two third-party build inputs are vendored

Nothing to fetch. `mod/third-party/` holds the archives upstream published,
byte for byte, and `vendor.py` unpacks them on demand:

| archive | unpacks to | license |
|---|---|---|
| `UTMT_CLI_v0.9.1.2-Windows.zip` | `mod/build/utmt/` (~130 MB) | GPL-3.0 |
| `gm-apclientpp-v0.4.9-3-win32.zip` | `mod/build/gm-apclientpp.dll` | MIT |

The unpacked forms are gitignored build outputs; the archives are the committed
originals. `UndertaleModTool-0.9.1.2-source.zip` sits beside the UTMT binary
and is not a build input — it is the GPL Corresponding Source, and it ships in
the patcher bundle so it travels with the binary. Read
[third-party/README.md](third-party/README.md) before touching any of it,
especially before bumping a version.

`build.py` still honours `UTMT_CLI` and `VDH_DLL` if you want your own copies,
and `VDH_GAME_DIR` if your game copy lives elsewhere.

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

**Merchant locations are depth, not skill identity.** Naming them
`Unlock: <skill>` made all 50 sphere 0, because you can buy any offered skill
on level 1 and no honest requirement could be attached. They are now
`Level N Merchant Unlock M`, and a Merchant on level L fills one of *L's own*
five slots and nothing else. Keying to global purchase order instead meant a
merchant found on level 3 handed out "Level 1 Merchant Unlock 5" just because
that was the next number.

There is deliberately no falling back to shallower levels when L's five are
taken. This is a roguelite: the player re-runs earlier levels constantly, so a
slot left behind on level 1 is picked up on the next descent rather than being
stranded. Letting a deep Merchant mop up shallow slots would only make deep
runs do double duty and blur which level a location belongs to.

**Spawning has to ask the same question the stock does.** Both the Merchant and
the shortcut crystal originally kept vanilla's spawn condition, and both were
wrong for the same reason: vanilla gates them on things you *have*, while under
Archipelago they hand out things you *check*.

`spawn_shop` capped Merchants on `global.unlocked`, the total bought anywhere.
Fill level 3's five slots and level 1 fails `5 + 0 < min(50, 1 * 5)` forever --
its own five locations become unreachable. `ap_merchant_spawn_ok` counts this
level's remaining slots instead.

The crystal was worse. Vanilla spawns it exactly one level below the deepest
shortcut you own, so `Shortcut to Level L` needed L-2 Progressive Shortcut
*items* before it would even appear -- a requirement the logic knew nothing
about, leaving generation free to bury the item that spawns a crystal behind
that same crystal. `ap_crystal_spawn_ok` spawns one on any level whose shortcut
location is unchecked. Still one per run (`global.levelSkipped`) and still
`enemyLevel * 50` to light.

**Logic is two linear curves, `shop_tiers / 10` tiers per level.** A level
offers `floor(rate * L)` tiers of each shop, so the last tier goes on sale
exactly as level 10 comes into reach, whatever the tier count is set to.
Reaching level L demands what the levels below it offered,
`floor(rate * (L - 1))` of each of Progressive Damage, Progressive Max HP and
Progressive Orb XP.
Level 1 demands nothing, which is what makes sphere 0 exactly the five level-1
merchant unlocks, the first tier of each shop, and "Level 1 Cleared". At the
old fixed 15 tiers the rate is 1.5, so this is the original curve generalised
rather than replaced.

**The tier count is an option, but the id space is not.** Every player in a
multiworld has to agree on which id means what, so `defs.py` always describes
`MAX_SHOP_TIERS` (30) tiers and the slot's `shop_upgrade_tiers` selects how
many of them are in play. On the game side that is the difference between
`global.ap_max_shop_tier` (the tables) and `global.ap_shop_tiers` (this slot),
and getting the two the wrong way round means either offering upgrades the
server has no location for, or refusing ones it does.

**Options reach the game through `slot_data`, not the ini.** `ap_slot_data` is
called from the `ap_slot_connected` branch of `ap_dispatch` and nowhere else,
because proxy 0 is that event's argument -- which for `ap_slot_connected` *is*
the slot_data object -- and it stops being that on the next `poll()`. Every key
is read with a fallback baked into `ap_tables.gml`, so a slot generated by an
older apworld runs on the defaults instead of configuring the game to zero.

**Shrines cost exactly one hook.** Every one of `activate_block`'s thirteen
shrine arms ends by calling `destroy_shrine`, so `ap_shrine_check` is prepended
there and catches all of them. Two of `destroy_shrine`'s callers are not random
shrines (the shortcut crystal and the quest tablet), which is what
`ap_is_shrine` is for: a positive whitelist, because `ap_desc_suffix` runs for
every info-bar target in the game and an exclusion list would annotate half of
it.

**The info bar's item name is drawn separately from its description.** One
`draw_text_ext` can only be one colour, and the "AP:" line is coloured by what
Archipelago says the item is -- red trap, yellow progression, blue useful,
white filler. So `ap_desc_suffix` returns the description and *publishes* the
AP line in `global.ap_desc_line` / `global.ap_desc_flags`, and `ap_desc_draw`
(which replaced the vanilla draw call outright) draws both. The flags come from
the `flags` array in the scout reply, stored beside the name in
`global.ap_scout_flag`; a reply without them leaves 0, which reads as filler
and renders exactly as the uncoloured version did.

Shrine *spawning* is untouched. A level that has spent all its Archipelago
slots still grows shrines, and they still work -- `ap_shrine_check` just
returns early. Gating `place_tiles` as well was the wrong instinct: the
merchant cap it was copied from exists because a merchant with no unlock left
to sell has nothing to do, whereas a shrine always has its own effect to give.

That is also why, unlike a merchant, a shrine keeps its vanilla effect. A
merchant sells the unlock *instead of* the skill because the skill is the item;
a shrine's boost is not an item, so taking it away would just be a nerf. The
check rides along, the way a level clear does.

**Filler and traps are the one thing that cannot be re-derived.** Everything
else the mod tracks is a tally, which makes Archipelago's replay-everything-on-
connect behaviour harmless. A Coin Cache has already been spent and a trap has
already fired; there is no tally that recomputes them. So filler carries a
high-water mark -- how many items this seed+slot has consumed -- persisted in
`[Progress]` in `archipelago.ini` and compared against `index + i`, the item's
absolute position in the slot's history. Without it every reconnect would
re-pay every coin and re-spring every trap.

Effects that need a hero (everything but coins) are queued and drained by
`ap_consume` on the first frame that can take them -- which is `ap_can_act()`,
and that is a stronger question than "is there a hero". `ap_step` is *appended*
to obGameControl's Step, so it runs after the portal descent has already
advanced `global.mapCode` and called `room_restart()`; firing a trap there
spawns enemies into a room that is mid-teardown and crashes the game in Room
End. `global.gHero.visible` is what catches it, being false from the moment the
portal is touched until the room restarts.

They are queued rather than dropped, unlike a DeathLink. A Mana Refill that waits for the run to start is still a Mana
Refill; a DeathLink that waits is an execution seconds after the fact.

**Level locks stack with the curve rather than replacing it.** The curve says
"you should survive down there"; the locks say "you are allowed down there at
all".

**A refused descent ends the run.** `ap_to_village` clears `heroPicked` along
with `mapCode` and `enemyLevel`, which is exactly the state the game-over
screen's space-to-continue arm builds, so the village comes back with the
hero-select screen up. The level-clear check has already been sent by then —
the portal branch of `activate_block` runs fifteen frames earlier — so nothing
is lost but the hero.

Keeping the hero was the original behaviour and was wrong: obGameControl's
Create resets the entire run *around* it on that room restart — keys, phoenix,
`startLevel`, `levelSkipped`, the whole `else` branch — so a level-20 hero
reappeared in a fresh run's world, a combination the game reaches nowhere else
and handles accordingly.

All three shop items are required, Orb XP included: pacifist orbs are a primary
source of hero levels and levels scale everything, so orb XP is survivability
as much as max HP is, and it costs the same at the shop.

So the goal requires every tier of all three, and that is the point rather
than a side effect. An access rule is a claim about what must not be placed
*behind* a location. Without it, generation would be free to bury a Progressive
Damage behind the goal check, leaving a less-skilled player unable to finish.
Verified feasible: at every level the locations reachable one tier down exceed
3 x the requirement, with headroom from 6 slots at level 2 to 69 at level 11.

**Prices come from purchases made, not items received.** Vanilla priced the hub
shops off `global.<x>level`, which AP drives from received items — so checking
five tiers while receiving none would have meant paying tier-1 prices forever.
The same applies to `global.unlocked`, which sets both the unlock price and the
merchant spawn cap above, so `ap_refresh_counters` keeps it equal to locations
checked. Anything the player's *progress* should scale with has to count
checks; only the player's *power* counts items.

**Using a shortcut is free; enabling one still costs.** Enabling a crystal is
a real in-run decision -- coins spent there are coins not spent at a merchant
-- so `ap_shortcut_cost()` keeps the vanilla price. Using the Teleportation
Shrine, by contrast, spends a Progressive Shortcut the server already granted,
so `ap_teleport_cost()` returns 0: charging to use what Archipelago gave you
is a tax on progression. Both stay as scripts so each price has exactly one
definition that the affordability test, the deduction and the readouts all
share.

`global.skipFunds` (partial payments banked toward a crystal) is cleared on
connect. It persists in the save, and funds banked on one slot are meaningless
on the next -- left alone they also drove the readout negative once they
exceeded the price ("-,118 coins").

**Every connect starts from a blank slate.** The reset used to live in the
reconnect branch only, so a *first* connect skipped it -- and `save_game("load")`
on btnStartMenu Create had already restored the previous run's
dlevel/hlevel/plevel from the ini. Pressing Single Player then built that run's
first hero with stale upgrades. The reset is now unconditional and runs
synchronously before `room_goto`, so the hero is built from baseline and the
server's items raise it from there.

**Level clears key to the portal, not the boss.** The portal tile reads
"Defeat the *boss* OR Unlock with 5 Keys!", so hooking the Guardian's death
would silently miss every key-opened exit.

**Self-contained save location.** The patch clears the
`UseAppDataSaveLocation` info flag, which vanilla ships set. That moves the
game's save area from Roaming, `%APPDATA%\Vertical_Drop_Heroes_HD\`, to
Local, `%LOCALAPPDATA%\Vertical_Drop_Heroes_HD\`, so `vdh_save_11.ini`,
`archipelago.ini` and `ap_debug.log` share nothing with an untouched Steam
install. The modded build therefore starts from a blank save rather than
inheriting Steam unlocks — which is what an Archipelago run wants anyway.

It does **not** put those files beside the exe, and `working_directory` claims
otherwise: it reports the game folder either way, because GM:Studio's file
sandbox redirects the writes underneath it. Use `game_save_id` for "where do
the files actually go" — `ap_boot` logs both, labelled, and Options >
Archipelago shows the real one.

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
- Item/location balance checked across every option combination. It goes
  negative by 9 when level locks are on and exactly one of shortcuts or level
  clears is off -- ten added items against ten removed locations -- and the
  overflow comes out of the skill unlocks, which are `useful` and therefore
  droppable.
- Logic capacity holds for every tier count 15-30 crossed with every toggle;
  the tightest is 8 sphere-0 locations against 4 required items.
- A three-player multiworld covering the option extremes (15/20/30 tiers,
  locks on and off, DeathLink on, shortcuts and clears off) generates.

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

- **`ap_debug.log`** is written to the save area on every launch, fresh each
  run, and Options > Archipelago names the folder. It records the build stamp,
  how far `ap_boot` got, and what the ini contained. If the mod appears to do
  nothing, read that file first — if it does not exist at all, the patched
  `data.win` is not the one that ran. `Debug=1` in `archipelago.ini` adds a
  trace of every event and every server message; it is off by default because
  each line is a separate file write and the rate is set by how busy the
  multiworld is, not by this game.
- **DeathLink** is wired both ways. Sending hangs off `global.deadCount == 40`
  in obGameControl's Step -- an equality, so it is true on exactly one frame
  per run, after Phoenix has had its chance to revive. Receiving comes in as
  `ap_bounced`, is filtered by tag and by `source` (the server echoes DeathLink
  back to the sender), and is *applied* later, by `ap_dl_apply` from `ap_step`,
  because a bounce can land on a frame with no hero to kill. A death that a
  DeathLink caused never sends one back; the test for that is
  `global.death_cause == global.ap_dl_cause` rather than a flag, so nothing has
  to remember to clear it.
- **Death amnesty** filters the send side only. `death_amnesty_buffer`
  swallows the first N deaths outright and `death_amnesty_multiplier` then
  sends one death in every N; the count lives in `[Progress]` in
  `archipelago.ini` under the same seed+slot key as the item high-water mark,
  because a counter held in memory would hand out the whole buffer again every
  time the player quit to the menu. It sits *after* the "was this itself a
  DeathLink" test in `ap_death`, so deaths another world inflicted never eat
  the player's own allowance.
- **Level locks** divert the descent at the one place it happens: the portal
  countdown reaching zero in obGameControl's Step. The village Teleportation
  Shrine is a *second* way down that never touches a portal, and it is capped
  instead through `global.skipLevel` in `ap_apply_state`.
- **Multiplayer/co-op** paths (`obServer`/`obClient`) are untouched; the mod
  assumes single player.
- The 50 skill locations carry no logic requirement, because the game genuinely
  lets you buy any offered skill from level 1. They do get progressively more
  expensive (`5 + 15 * global.unlocked` coins), which is a grind gate but not a
  logic gate.
