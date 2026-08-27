# Vertical Drop Heroes HD — Archipelago mod: handoff

Context dump for continuing this work in a fresh session. Written 2026-08-19,
updated 2026-08-27 for **v0.3.1**.

**Status: released.** v0.2.0 was the first public release; v0.3.0 and v0.3.1
are built on what live play turned up. DeathLink is confirmed working in both
directions, a Merchant sale now names the item it actually bought, coins and
keys no longer follow the player from one multiworld into the next, and a run
can be ended from the pause menu without dying for it.

`defs.WORLD_VERSION` is the single source of truth for the version.
`archipelago.json` is checked against it at package time and the build refuses
on drift; `gen_gml.py` bakes it into the game as `global.ap_build`; and
`package.py` stamps it into the bundle's `BUILD.txt`. Bump `defs.py` and the
manifest together, or the build will tell you.

---

## 1. What this is

`C:\Users\Zane3\GenAI\APVerticalDropHeroes` — a **disposable copy** of the game
plus an Archipelago mod for it. The user's real install is in `steamapps` and is
untouched (verified md5-identical to vanilla).

The game is **GameMaker: Studio 1.4, bytecode 16**. The mod patches `data.win`
directly with UndertaleModTool, and talks to Archipelago through
[gm-apclientpp](https://github.com/black-sliver/gm-apclientpp) loaded via
`external_define`. **There is no separate client process** — the game *is* the
client.

### Layout

```
APVerticalDropHeroes/
  Vertical Drop Heroes HD/     game copy (GITIGNORED)
    data.win                   patched, rebuilt by build.py
    data.win.vanilla           pristine snapshot; every build starts here
    gm-apclientpp.dll          32-bit, copied in by build.py
    steam_appid.txt            311480 — see trap #1
    (archipelago.ini and ap_debug.log are NOT here -- see trap #4;
     they live in %LOCALAPPDATA%\Vertical_Drop_Heroes_HD\)
  mod/third-party/             VENDORED, COMMITTED: upstream archives, verbatim
    UndertaleModTool/          UTMT CLI zip + its GPL source zip + LICENSE
    gm-apclientpp/             win32 zip + LICENSE
  mod/
    build/
      gen_gml.py               emits gml/ap_tables.gml from defs.py
      patch.csx                the UndertaleModTool patch
      build.py                 patch data.win  <-- run after any GML change
      package.py               build out/      <-- run after any defs change
      vendor.py                unpacks third-party/ archives on demand
      utmt/                    UndertaleModCli (GITIGNORED, 130MB, GPL-3)
                               unpacked from third-party/, not downloaded
      gm-apclientpp.dll        (GITIGNORED) likewise unpacked from third-party/
    gml/                       63 files: the in-game client
    apworld/vertical_drop_heroes/
      defs.py                  ids and tables  <-- SINGLE SOURCE OF TRUTH
      Options.py Items.py Locations.py Rules.py __init__.py
      docs/setup_en.md
  out/                         build output (GITIGNORED, reproducible)
```

`defs.py` has exactly one copy. `gen_gml.py` imports it from the apworld;
`package.py` copies it into the patcher bundle. Do not create a second copy.

---

## 2. Build workflow

```bash
python mod/build/build.py      # regenerate tables, patch data.win, copy DLL + appid
python mod/build/package.py    # rebuild out/*.apworld and out/vdh-ap-patcher.zip
```

`build.py` always patches from `data.win.vanilla`. The patch **appends** to
existing code entries, so it is not idempotent — never patch a patched file.

The baseline rule is one line: **if `data.win.vanilla` exists, that is what is
patched, and the state of `data.win` does not matter** — it is only ever an
output. `data.win.vanilla` alone is enough to build from, and enough to
identify the game folder (`has_game()`), so carrying just the clean copy to
another machine works.

There is no snapshot to take in that case, which is the point: the snapshot is
taken once, on a folder that has never been patched, and trusted forever after.
Getting *that* moment wrong is permanent, so it is the only thing guarded.
`looks_patched()` greps the raw file for `ap_boot` and bails if `data.win` is
already modded with no `data.win.vanilla` beside it — copy a patched game
folder to a second machine, leave its `data.win.vanilla` behind, run the
patcher, and a patched file becomes the baseline for good. It bails the same
way if `data.win.vanilla` itself fails the test.

**Every build says what it is.** `gen_gml.py` bakes `global.ap_build` into
`ap_tables.gml` — the bundle's `BUILD.txt` line in a release, `git describe` in
the dev repo — and `ap_draw` puts it on the overlay next to the host/slot while
`ap_boot` writes it to `ap_debug.log`. Ask for that string before debugging
anything reported from another machine. A patch that landed somewhere other
than where the game launches from produces every symptom of a broken mod and
no evidence at all; this is the only thing that tells the two apart from
inside the game.

**Run `package.py` after ANY change that ships, GML included.** `build.py`
only patches the dev copy of the game; `out/` is a separate snapshot of `gml/`,
`patch.csx` and the build scripts, and nothing rebuilds it implicitly. Handing
someone a stale `out/` looks exactly like the mod not working — same game, same
patch step, none of the fixes. The bundle carries `BUILD.txt` for this reason
and `build.py` prints its first line on every run: every *other* file in the
bundle keeps its source mtime (`copy2`), so an unchanged `patch.bat` showing an
old date says nothing at all about how fresh the bundle is.

### Who does what

| step | who |
|---|---|
| patch `data.win`, copy DLL, write `steam_appid.txt` | automatic, `build.py` |
| rebuild `out/*.apworld` and `out/vdh-ap-patcher.zip` | automatic, `package.py` |
| copy apworld → `C:\ProgramData\Archipelago\custom_worlds\` | **user** |
| copy `out/` to whatever machine plays | **user** |
| regenerate the seed | **user** |
| launch the game | **user** |

**Any change to `defs.py`, `Options.py` or `Rules.py` means the user must
recopy the apworld and regenerate.** Pure GML changes do not — but they *do*
mean re-running `package.py` and re-copying the patcher bundle.

Note: the assistant's filesystem access outside the project directory is
sandboxed and **not** the user's real filesystem. Reads there may be stale and
writes do not land. Never claim to have created a file outside the project.

---

## 3. Traps already paid for — do not rediscover these

**1. Steam DRM relaunch.** The exe calls
`SteamAPI_RestartAppIfNecessary(311480)`; Steam then launches *its own*
registered copy from `steamapps\common`, so double-clicking a patched exe
silently runs the **unpatched** game. Fixed by `steam_appid.txt` beside the
exe. This cost an evening and presented as "the mod does nothing": no log, no
overlay, ini ignored, saves in the wrong place.

*The tell:* clearing `UseAppDataSaveLocation` — a runner-level header flag,
nothing to do with GML — also appeared to do nothing. **When a change at that
layer has no effect, the runner is not reading your file.**

**2. `execute_string` does not exist in GM:Studio.** gm-apclientpp documents
`execute_string(apclient_poll())` for event dispatch. That is GM7/8 only.
Instead: `apclient_poll()` pops one queued event and sets `script_name` /
`script_data`, so the return value is used only as a "was there an event?"
flag and dispatch runs off `apclient_json_source()` plus the json proxies.
See `gml/ap_step.gml` and `gml/ap_dispatch.gml`.

**3. `obGameControl` exists only in `rmGameplay`/`rmGameplay_Coop`.** Booting
solely from there left the mod inert at the splash and menu. It now also boots
and pumps from `btnStartMenu` (`rmMenu`). Verified by walking `Data.Rooms`.

**4. Save location, and `working_directory` lying about it.** Vanilla ships
`UseAppDataSaveLocation` set, sending saves to Roaming,
`%APPDATA%\Vertical_Drop_Heroes_HD\`. The patch clears the flag, which moves
the save area to **Local**, `%LOCALAPPDATA%\Vertical_Drop_Heroes_HD\`, so it
cannot collide with a Steam playthrough.

It does **not** put files beside the exe. That was believed for days because
`working_directory` returns the game folder — it does so regardless, since
GM:Studio's file sandbox redirects writes underneath it. Every relative-path
write (`ap_debug.log`, `archipelago.ini`, `vdh_save_11.ini`) lands in the save
area no matter what that string says.

**Use `game_save_id`, never `working_directory`, for "where do the files go".**
`ap_boot` logs both, labelled. Displaying `working_directory` on the Options
page sent the user hunting for a log in a folder the game had never once
written to, while the real log sat in Local the whole time.

Practical consequence: **editing `archipelago.ini` in the game folder does
nothing.** The game reads the copy in the save area. Configure through
Options > Archipelago in-game, or edit the copy the Options page names.

**5. `draw_set_font(-1)` renders nothing.** Use a real font
(`fnInterfaceMedium` etc.). This made the whole overlay invisible.

**6. GMS 1.4 has no array literals.** `var a[0] = "x";` fails to compile;
declare then index.

**7. Globals that do not exist at menu time.** `startLevel`, `dprice`,
`hprice`, `pprice` are gameplay-only. Everything else the mod touches is
created by `save_game("load")` on btnStartMenu Create line 102, which runs
before the appended `ap_boot`. Guard reads with `variable_global_exists`.

**8. PowerShell `set VAR=x` does not set an environment variable** — it is an
alias for `Set-Variable`. Use `$env:VAR = "x"`.

**10. Never commit decompiled game code.** `UndertaleModCli dump` output is
Nerdook's source. 22 such files were tracked before the first public push and
had to be pulled; `.gitignore` now excludes `chk*/`, `verify/`, `dump*/` and
any `CodeEntries/`.

**13. Vanilla spawn gates ask about items owned; AP locations are about
checks.** Two hit this. `spawn_shop` capped Merchants on `global.unlocked` (the
total bought anywhere) while a Merchant only ever fills its own level's five
slots -- so buying five unlocks on level 3 locked level 1 out of Merchants
permanently, stranding its own five locations. And the shortcut crystal spawns
on `global.enemyLevel == (global.skipLevel + 1)`, where skipLevel is derived
from Progressive Shortcut *items*, so the crystal *location* for level L needed
L-2 of those items to appear -- a chain the logic does not model, so generation
could put the item that spawns a crystal behind that crystal.

Both now ask "does this level still have an unchecked location":
`ap_merchant_spawn_ok`, `ap_crystal_spawn_ok`. When adding anything else that
spawns, check which side of that line its vanilla condition sits on.

**12. `ap_step` runs AFTER the room change has been queued.** It is appended
to obGameControl's Step, so every vanilla branch in that event has already
run -- including the portal descent, which sets `global.enemyLevel += 1` and
`global.mapCode = mapArray[...]` and then calls `room_restart()`. GameMaker
defers the actual room change to the end of the event, so the appended
`ap_step()` still executes, in a room that is already dead but with the *next*
level's globals in place.

An Alarm Trap queued in the village (`mapCode == 0`) therefore fired the
instant the portal advanced `mapCode` to 1, and `reinforcements()` spawned
enemies whose Create never completed. Room End's
`with (obHero) instance_destroy()` then read `has_light` off them:

```
Variable obHero.has_light not set before reading it
at gml_Object_obHero_Destroy_0
called from gml_Object_obGameControl_Other_5
```

*The tell:* it only ever happened on the frame a portal was taken.

Anything applied out of band -- queued filler, traps, DeathLink -- must go
through `ap_can_act()`, which is as much "will this room survive the frame" as
it is "is there a hero". `global.gHero.visible` is the load-bearing check:
activate_block sets it false at both transition sites and it stays false until
the room actually restarts.

**11. Scouting a location the slot does not have kills the server.** Not
"is ignored" -- MultiServer's LocationScouts handler does
`ctx.locations[client.slot][location]` and the KeyError takes down the command
handler for the whole room:

```
KeyError: 'No location 8830165 for player 3'
```

The id tables describe the MAXIMUM id space (30 shop tiers, 10 shrines a level,
shortcuts and clears whether or not the yaml asked for them) and the slot plays
a subset. `ap_scout_request` therefore walks the tables applying the same
bounds as the apworld's `locations_for()`, and `ap_shortcut_check` /
`ap_level_cleared` bail out when their category is off. Anything that reaches
`ap_check` must be inside the slot's own location set.

*The tell:* it fires the moment the game connects, and it looks like a server
bug rather than a client one.

**14. `apclient_init(1)` silently has no DeathLink.** Bounce arrived in
gm-apclientpp's **API version 2**, and that is what `apclient_death_link`,
`apclient_bounce`, `apclient_set_bounce_targets` and the `ap_bounced` event all
live in. Version 1 does not error when you call them -- it just never sends and
never delivers. So DeathLink was dead in both directions while looking exactly
like a yaml with `death_link: false`: connection fine, checks fine, items fine,
no errors anywhere, and nothing in the server log.

`ap_connect_now` now asks for 2 and falls back to 1 with
`global.ap_bounce_ok = 0`, which `ap_slot_data` folds into
`global.ap_death_link` so an old DLL says so in the log instead of going quiet.

Still the bare number, not 202: the `+200` variant only switches to GMS2 string
syntax, and this is GM:Studio 1.4. The version argument does two unrelated jobs
and only one of them is the one trap #2 is about.

*The tell:* nothing. That is the point -- both `apclient_death_link` and the
missing `ap_bounced` fail by doing nothing, so the only way to see it is to
check the return value, which `ap_death` now logs.

**9. Heredocs + Python + C# escaping.** Writing `patch.csx` through a bash
heredoc mangles `\n` and backticks. Use the Edit tool or a script file for
anything with escapes; use C# verbatim strings (`@"..."`) in the .csx.

---

## 4. Design decisions and why

**Tally, then derive.** `ap_receive_item` only increments counters;
`ap_apply_state` recomputes game state from them. Archipelago replays the
entire item history on every connect — replaying into a tally is idempotent,
replaying into `hpmax += 7` is not.

**Both mirrors are slot-specific.** `ap_reset_tallies` (received) *and*
`ap_reset_sent` (checked) are cleared on every connect and rebuilt from the
server. Clearing only the first let slot A's checked set leak into slot B.
Safe because apclientpp replays the full checked set right after
`ap_slot_connected`, omitting it only when genuinely empty.

**Shortcut pricing is split.** `ap_shortcut_cost()` (enable) keeps the vanilla
price -- it is a real trade-off. `ap_teleport_cost()` (use) returns 0, because
using a Progressive Shortcut the server granted should not be taxed.
`global.skipFunds` is cleared on connect.

**Every connect resets state.** `ap_connect_now` clears tallies, sent-state and
re-applies derived stats unconditionally -- not just on reconnect. A first
connect skipping this let `save_game("load")` values from the previous run
build the first hero.

**"End This Run Early" is a fourth pause-menu entry.** Vanilla's only exit
from a run is to die, and under Archipelago dying costs everyone else in the
multiworld a DeathLink -- so a run that is over (level ahead locked, nothing
left to check on this one) forced a choice between finishing it and killing
someone else's hero. `ap_pause_extra` decides whether the entry exists at all
and all three hooks ask it: `max_choices[1] = 3 + ap_pause_extra()` in
obGameControl's Step (pause_control wraps the cursor on that count),
`ap_pause_draw` appended to Draw_64, and `ap_end_run` on choice 4 in
`pause_control`. `ap_end_run` lands in exactly `ap_to_village`'s end state,
which is the game's own post-death state, so no DeathLink is possible: the
death test needs `deadCount == 40`, and the `room_restart` runs
obGameControl's Create, which zeroes deadCount and -- with `heroPicked`
cleared -- raises `selectScreen`, so deadCount can never climb.

**Coins and keys reset per slot, not per connect.** `global.coins` and
`global.keys` are vanilla save state that no item stream can recompute, so
they cannot be zeroed with everything else on connect -- coins are meant to
survive between runs on one slot, and every run start connects. They also
cannot be left alone: the next multiworld inherited the last one's whole
purse. `ap_purse_check` keys the wipe on identity instead, comparing
`global.ap_progress_key` (seed + slot) against a `[Progress] Purse` mark in
`archipelago.ini`. Same key, keep the purse; different key, zero it and
`save_game("save")` at once so it does not come back on the next launch.
Storing the mark in the ini is what lets one slot close and reopen with its
coins. It runs from `ap_dispatch` right after `ap_progress_load`, because the
key needs the seed, which only exists once RoomInfo has arrived -- a few frames
into level 1 on a run-start connect.

**Progress counts checks; power counts items.** Prices and the merchant spawn
cap derive from locations *checked* (`ap_shop_price`, `ap_refresh_counters`
maintaining `global.unlocked`). Stats derive from items *received*.

**Merchant locations are depth, not skill identity.** A Merchant on level L
fills one of *L's own* five slots and nothing else — no fallback to shallower
levels, because this is a roguelite and earlier levels get re-run constantly.

**Level clears key to the portal, not the boss.** The portal reads "Defeat the
*boss* OR Unlock with 5 Keys!", so hooking the Guardian's death would miss
every key-opened exit.

**The menu owns input before the stock menu.** The Archipelago page handler is
*prepended* to btnStartMenu's Step so it can `exit` the whole event. A
script-level `exit` only leaves the script.

**Offline still works.** Every hook is guarded by `global.ap_enabled`; with no
Slot configured the DLL is never even loaded.

---

**A refused descent ends the run.** `ap_to_village` clears `heroPicked` as
well as `mapCode`/`enemyLevel`, which is exactly the state the game-over
screen's space-to-continue arm builds. Carrying the hero through instead kept
its level, HP and XP across a village rebuild that resets everything *around*
it -- keys, phoenix, startLevel, levelSkipped, the whole `else` branch of
obGameControl's Create -- producing a level-20 hero in a fresh run's world,
which is not a state the game reaches any other way.

**A Merchant sale names its item at the point of sale.** What a Merchant
advertises is "whatever `ap_merchant_next()` says", and that moves the instant
*any* Merchant is bought from. `set_merchant` only ran at spawn, so the second
sale on a level announced the location the first had already taken:
`global.last_skill`, the "you have unlocked X" popup and the float-up text all
read `decor.longtext2`, a snapshot from when that Merchant was placed.
`ap_merchant_label` re-derives the name from the location the sale is about to
check and is hooked immediately before `new_unlock`, while
`ap_merchant_next()` still points at that slot.

`ap_merchant_restock` was the first attempt and never could have fixed it.
`with (obDecor)` visits only *active* instances, and obGameControl's Step
deactivates obDecor outside a band around the camera every time the camera's
top grid cell changes, re-activating just that band -- so a Merchant off
screen is invisible to it. That is why every live log reads
`restock: 1 Merchant(s)`: the one being bought from. It stays, for the signs
on Merchants that *are* on screen, and because it also runs when scout results
land, which is what clears the "Unlock N" placeholder.

**Culling is a trap for any `with (obDecor)`.** Anything that sweeps the level
sees only what is on screen. If a sweep has to cover the whole level, it needs
`instance_activate_object` first and the band restored after -- which is why
nothing in the mod does one.

**Item arrival rerolls the hero-select screen.** `generate_cbox` bakes the
unlock set and shop levels into a candidate when it builds it, and
obGameControl's Create builds all three before the server has replied to the
connect -- so Single Player from the main menu gave three traitless heroes and
the only cure was quitting out and back in. `ap_apply_state` now keeps a
weighted signature of the unlock tally and calls `ap_reroll_select` when it
moves. The signature is what keeps this to the frames that changed something:
the script runs on every ReceivedItems batch, and rerolling under the player
on a batch that changed nothing would be its own bug. Free, unlike the vanilla
reroll -- that costs 5 coins because it is the player gambling; this is the mod
catching up with itself.

**Tutorial pages are off under Archipelago; the unlock popup is not.** One
prepend on `showtutorial`, gated on `argument0 >= 0`. The pages pause the game
to explain vanilla mechanics to someone who just read a setup guide, and
`tutorpage` lives in the save so a fresh modded save replays all of them.
`showtutorial(-1)` is not a page -- it is the popup naming what a Merchant
purchase handed over, which under AP is the only place that is reported.

## 5. Current game design

**261 locations** (ids 8830000–8830260), **60 item types**. The id space is
fixed at the maximum; each slot plays a subset of it:

| category | count | notes |
|---|---|---|
| `unlock` | 50 | `Level N Merchant Unlock M`, N=1..10, M=1..5 |
| `shop` | 90 | Blacksmith / Apothecary / Monk × 30 tiers; the slot's `shop_upgrade_tiers` (15–30, default 20) picks how many are live |
| `shortcut` | 10 | crystals, levels 2..11 |
| `clear` | 10 | levels 1..10, on taking the exit portal |
| `shrine` | 100 | levels 1..10 × 10 slots; the slot's `shrine_checks` (0–10, default 5) picks how many are live |
| `goal` | 1 | Defeat the Chosen One |

Items: 50 skill unlocks (useful) + `shop_upgrade_tiers` each of Progressive
Damage / Max HP / Orb XP + 10 Progressive Shortcut + 10 Progressive Level
Access (all progression) + filler and traps.

Filler: Coin Cache (coins), Shrine Boost (a random shrine effect), Mana Refill,
Skeleton Key. Traps: Alarm Trap. `trap_fill` is the percentage of the leftover
filler slots that become traps, so traps never displace anything with power in
it. Adding another is a line in `defs.FILLERS`/`defs.TRAPS` plus a branch in
`gml/ap_effect.gml`.

At the defaults that is 181 locations and 130 non-filler items.

### Logic — two linear curves at `shop_tiers / 10` tiers per level

```
level     1  2  3  4  5  6  7  8  9 10 11
offers    2  4  6  8 10 12 14 16 18 20  -     floor(rate * L)
demands   0  2  4  6  8 10 12 14 16 18 20     floor(rate * (L-1))
```

(shown for the default 20 tiers; at 15 the rate is 1.5 and this is the
original curve.)

"Demands" means that many of **each** of Progressive Damage, Max HP and Orb XP.
Orb XP counts because pacifist orbs drive hero levels and levels scale
everything.

The goal requiring every tier of all three is **the point, not a side effect**:
an access rule constrains what may be placed *behind* a location, so requiring
them stops generation burying a Progressive Damage past the goal check.

With `level_locks` on (the default), reaching level L also wants L-1
Progressive Level Access. The two requirements stack.

Sphere 0 is exactly nine locations: the five level-1 merchant unlocks, tier 1
of each shop, and Level 1 Cleared.

Options: `include_shortcuts`, `include_level_clears`, `shop_upgrade_tiers`,
`shop_price_step`, `shop_price_cliff`, `level_locks`, `shrine_checks`,
`trap_fill`, `death_link`. They reach
the game through `slot_data`, read once in `ap_slot_data` from the
`ap_slot_connected` branch of `ap_dispatch` -- proxy 0 is that event's argument
and stops being it on the next `poll()`.

---

### Shop pricing

`ap_shop_price` derives the whole curve from the purchase count rather than
borrowing `global.dprice` (which obGameControl's Step recomputes from the
*received* side and would therefore disagree):

```
cost(tier) = tier * (shop_price_step + floor(tier / 10) * shop_price_cliff)
```

Defaults 25 / 25 / every 10 reproduce vanilla exactly. The cliff is every ten
tiers, not fifteen -- with the old 15-tier cap it fired once, at tier 10.

### Shrines

One hook: a prepend on `destroy_shrine`, which every one of `activate_block`'s
thirteen shrine arms calls. Prepended, not appended, because `destroy_shrine`
is what blanks the sprite to `spShrine_Dead` and `ap_shrine_check` needs to see
which shrine it was. `ap_is_shrine` is a positive whitelist: the shortcut
crystal and the quest tablet also go through `destroy_shrine`, and
`ap_desc_suffix` sees every info-bar target there is.

Shrine spawning is deliberately NOT gated. A level that has spent all
`shrine_checks` of its slots goes on growing shrines and they go on working;
`ap_shrine_check` simply returns early. The merchant cap this was briefly
modelled on exists because a merchant with nothing left to sell has nothing to
do -- a shrine always has its own effect to give.

The shrine also keeps that effect when it *is* a check. Unlike a merchant --
whose skill *is* the item, so selling the unlock instead makes sense -- a
shrine's boost is not an item, so removing it would be a plain nerf.

### Filler, traps, and the high-water mark

Filler is the one category that cannot be re-derived from a tally, and
Archipelago replays the whole item list on every connect. So `ap_progress_load`
reads a per-seed-per-slot count out of `[Progress]` in `archipelago.ini`, and
`ap_dispatch` compares each item's absolute position (`index + i`) against it
before calling `ap_effect`. Get this wrong and every reconnect re-pays every
Coin Cache and re-fires every trap.

Effects needing a hero are queued (`global.ap_pend_*`) and drained by
`ap_consume` from `ap_step`. Queued, not dropped -- the opposite of a DeathLink,
which *is* dropped, because a delayed buff is still a buff while a delayed kill
is an execution out of nowhere.

### Level locks

`ap_level_open(L)` gates the descent. The one place the game descends is the
portal countdown hitting zero in obGameControl's Step, and that is where
`ap_to_village()` is spliced in. The village Teleportation Shrine is a second
route down that never touches a portal; it is capped through `global.skipLevel`
in `ap_apply_state` instead of getting its own hook.

### DeathLink

Needs **API version 2** from the DLL; see trap #14. `global.ap_bounce_ok`
records whether we got it, and `global.ap_death_link` is the AND of that and
the yaml.

Confirmed working both ways in live play. What made it look dead for a while
was the multiworld, not the mod: the server routes a Bounce only to slots that
carry the DeathLink tag, so with no other DeathLink game connected there is
nobody to receive one and nothing comes back. Test it against a second tagged
slot before suspecting the code.

A refused descent (`ap_to_village`) is deliberately *not* a death and sends
nothing: `ap_death` hangs off `global.deadCount == 40`, deadCount only climbs
while gHero is missing and `selectScreen` is 0, and the village rebuild zeroes
the first and sets the second. The hero is retired, not killed.

Send: `global.deadCount == 40` in obGameControl's Step. An equality, so exactly
one frame per run, and after Phoenix has had its revive. The sentence names
`global.ap_slot`, not the hero: the hero's generated name means nothing to the
other worlds reading the line, which know this one only by its slot.
Receive: `ap_bounced` -> `ap_death_recv` (filter by tag, drop anything whose
`source` is us, because the server echoes to the sender) -> queued ->
`ap_dl_apply` from `ap_step` once there is a living hero, else dropped.
A DeathLink death never sends one back; the test is
`global.death_cause == global.ap_dl_cause`, which self-clears because every
other death overwrites `death_cause` and obGameControl's Create blanks it.
The same test is what `ap_death_line` uses to replace the game-over screen's
"Killed by ..." line with the sentence the other world sent.

## 6. Outstanding

**Known bugs, reported from live play:**

- **An intermittent `show_message` "Unknown exception" from the DLL.** Seen
  once, killing a boss that had already been killed -- which sends nothing, so
  it is likely inbound rather than outbound. `apclient_render_json` choking on
  another world's `PrintJSON` is the leading guess. `ap_dispatch` names every
  event and dumps the raw packet before rendering it, both under `Debug=1`.
- **`include_shortcuts: false` was quietly broken** before the scout fix: the
  patch suppresses the vanilla `global.skipLevel` / `global.startLevel` lines
  at the crystal, so with the category off a crystal took the coins and did
  nothing. `ap_shortcut_check` now restores them, and `ap_shortcut_open`,
  `ap_teleport_cost` and `ap_apply_state` fall back to vanilla too. Untested.
- **`loop_tile`'s `spShrine_Skip` "available" pip is dead code** either way:
  `available` is only created by `make_npc` for sprites 293/294/300 (the three
  hub vendors), so the branch is behind an `instance_exists(available)` that is
  never true for a shrine. The hook there is harmless but means nothing.
- **Co-op / Split Screen** untouched; deliberately does not connect.
- **`ap_debug.log`** is the first thing to read when something seems dead --
  in the save area, not the game folder (trap #4). Its first lines are the
  build stamp and the resolved paths. If it does not exist at all, the patched
  `data.win` is not what ran.
- Shrine/statue AP annotations, merchant title/description, shortcut re-buy,
  and the menu alignment were all fixed in `ed3d583`; if any recur, the hooks
  are `ap_desc_suffix` / `ap_title_fix` / `ap_shortcut_open` / `ap_menu_draw`.

Set `Debug=1` in `archipelago.ini` (the one in the save area) before trying to
reproduce any of these.

## 7. Verification habits worth keeping

- `patch.csx` sets `ThrowOnNoOpFindReplace = true`, so a hook that stops
  matching fails the build loudly instead of silently doing nothing.
- After every build, decompile the changed entries back out of `data.win` and
  grep them — `UndertaleModCli dump <win> -c <entry> -o <dir>`.
- Check runtime functions exist in the runner's builtin table before using
  them: `grep` the exe for the name. That is how `execute_string` was caught.
- Simulate logic feasibility after any rules change: capacity (locations
  reachable one tier down) must exceed 3 × the requirement at every level.
