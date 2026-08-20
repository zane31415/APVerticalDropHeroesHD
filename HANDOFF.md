# Vertical Drop Heroes HD — Archipelago mod: handoff

Context dump for continuing this work in a fresh session. Written 2026-08-19.

**Status: working.** The mod connects to a live server, sends checks and
receives items across every category. Last commit `1330f97`.

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
    archipelago.ini            connection config
    ap_debug.log               fresh each launch
  gm-apclientpp.dll            source copy (GITIGNORED, third-party)
  mod/
    build/
      gen_gml.py               emits gml/ap_tables.gml from defs.py
      patch.csx                the UndertaleModTool patch
      build.py                 patch data.win  <-- run after any GML change
      package.py               build out/      <-- run after any defs change
      utmt/                    UndertaleModCli (GITIGNORED, 130MB, GPL-3)
    gml/                       43 files: the in-game client
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

### Who does what

| step | who |
|---|---|
| patch `data.win`, copy DLL, write `steam_appid.txt` | automatic, `build.py` |
| rebuild `out/*.apworld` | automatic, `package.py` |
| copy apworld → `C:\ProgramData\Archipelago\custom_worlds\` | **user** |
| regenerate the seed | **user** |
| launch the game | **user** |

**Any change to `defs.py`, `Options.py` or `Rules.py` means the user must
recopy the apworld and regenerate.** Pure GML changes do not.

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

**4. Save location.** Vanilla ships `UseAppDataSaveLocation` set, sending saves
to `%APPDATA%\Vertical_Drop_Heroes_HD\` (Roaming, underscores — *not*
LOCALAPPDATA, that guess was wrong). The patch clears the flag so everything
lives beside the exe and cannot collide with a Steam playthrough.

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

## 5. Current game design

**116 locations** (ids 8830000–8830115), **56 item types**:

| category | count | notes |
|---|---|---|
| `unlock` | 50 | `Level N Merchant Unlock M`, N=1..10, M=1..5 |
| `shop` | 45 | Blacksmith / Apothecary / Monk × 15 tiers |
| `shortcut` | 10 | crystals, levels 2..11 |
| `clear` | 10 | levels 1..10, on taking the exit portal |
| `goal` | 1 | Defeat the Chosen One |

Items: 50 skill unlocks (useful) + 15 each Progressive Damage / Max HP / Orb XP
+ 10 Progressive Shortcut (all progression) + filler + a trap.

### Logic — two linear curves at 1.5 tiers/level

```
level     1  2  3  4  5  6  7  8  9 10 11
offers    1  3  4  6  7  9 10 12 13 15  -     floor(1.5 * L)
demands   0  1  3  4  6  7  9 10 12 13 15     floor(1.5 * (L-1))
```

"Demands" means that many of **each** of Progressive Damage, Max HP and Orb XP.
Orb XP counts because pacifist orbs drive hero levels and levels scale
everything.

The goal requiring all 15 of all three is **the point, not a side effect**: an
access rule constrains what may be placed *behind* a location, so requiring
them stops generation burying a Progressive Damage past the goal check.

Sphere 0 is exactly nine locations: the five level-1 merchant unlocks, tier 1
of each shop, and Level 1 Cleared.

Options: `include_shortcuts`, `include_level_clears`, `trap_fill`,
`death_link`. Difficulty and shop-tier sliders were deliberately removed.

---

## 6. Outstanding

- **DeathLink** is a slot option and rides in `slot_data` but is **not wired**
  in GML. Nothing sends or receives it.
- **Trap item** (`Fragile Hero Trap`) sets `global.ap_pending_trap`; nothing
  consumes it. Keep `trap_fill` at 0.
- **Co-op / Split Screen** untouched; deliberately does not connect.
- **`ap_debug.log`** is the first thing to read when something seems dead. If
  it does not exist at all, the patched `data.win` is not what ran.
- Shrine/statue AP annotations, merchant title/description, shortcut re-buy,
  and the menu alignment were all fixed in `ed3d583`; if any recur, the hooks
  are `ap_desc_suffix` / `ap_title_fix` / `ap_shortcut_open` / `ap_menu_draw`.

## 7. Verification habits worth keeping

- `patch.csx` sets `ThrowOnNoOpFindReplace = true`, so a hook that stops
  matching fails the build loudly instead of silently doing nothing.
- After every build, decompile the changed entries back out of `data.win` and
  grep them — `UndertaleModCli dump <win> -c <entry> -o <dir>`.
- Check runtime functions exist in the runner's builtin table before using
  them: `grep` the exe for the name. That is how `execute_string` was caught.
- Simulate logic feasibility after any rules change: capacity (locations
  reachable one tier down) must exceed 3 × the requirement at every level.
