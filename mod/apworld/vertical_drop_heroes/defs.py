"""Canonical Archipelago definitions for Vertical Drop Heroes HD.

This is the single source of truth for item/location names and IDs.
Both the GML tables (baked into data.win) and the apworld are generated
from here, so the two sides can never drift apart.

Ordering of the skill lists is load-bearing: the index of each name is the
index into the game's global.tr_unlock / p1_unlock / p2_unlock arrays.
Do not reorder them.
"""

BASE_ID = 8830000

GAME_NAME = "Vertical Drop Heroes HD"

# Version of this world. Single source of truth for it too: archipelago.json is
# checked against this at package time, gen_gml.py bakes it into the game as
# global.ap_build, and package.py stamps it into the patcher's BUILD.txt. A
# release where those three disagree is a release nobody can debug.
WORLD_VERSION = "0.2.0"

# The Archipelago this world is developed and generated against.
MIN_AP_VERSION = "0.6.7"

# --- skills -----------------------------------------------------------------
# Index == index into global.tr_unlock[] (see gml_Script_new_unlock).
TRAITS = [
    "Agile", "Ironfoot", "Greedy", "Wealthy", "Intelligent",
    "Gifted", "Aggressive", "Bloodlust", "Keymaster", "Lockpicks",
    "Tough", "Firewalker", "Finesse", "Knockback", "Smasher",
    "Necromancer", "Dodger", "Phoenix", "Slayer", "Tit for Tat",
]

# Index == index into global.p1_unlock[]
POWERS_1 = [
    "Stomp", "Triple Shot", "Fast Strike", "Fireball", "Swap",
    "Ice Bolt", "Shield", "Fire Trap", "Magic Blades", "Boomerang",
    "Magic Missile", "Plague", "Lightning", "Call Hero", "Polymorph",
]

# Index == index into global.p2_unlock[]
POWERS_2 = [
    "Omnislash", "Force Blast", "Recovery", "Raise Dead", "Ice Age",
    "Confusion", "Death Puppet", "Sanctuary", "Shadow", "Golem Shift",
    "Open All", "Red Dragon", "Dwarf Turret", "Midas Touch", "Sandworms",
]

# kind -> (gml global array, list)
SKILL_GROUPS = [
    ("trait", "tr", TRAITS),
    ("power1", "p1", POWERS_1),
    ("power2", "p2", POWERS_2),
]

TOTAL_SKILLS = len(TRAITS) + len(POWERS_1) + len(POWERS_2)   # 50

# --- merchant unlocks -------------------------------------------------------
# The skills are ITEMS. The LOCATIONS are the merchant purchases that pay for
# them, and those are already depth-gated by the vanilla game:
#
#   spawn_shop: (global.unlocked + merchantSpawned) < min(50, enemyLevel * 5)
#
# so the Nth unlock you ever buy is impossible until you reach level
# ceil(N / 5). Naming locations by that level makes the existing constraint
# legible to Archipelago's logic instead of inventing a parallel one.
UNLOCKS_PER_LEVEL = 5
UNLOCK_LEVELS = TOTAL_SKILLS // UNLOCKS_PER_LEVEL            # 10

# --- between-run shops ------------------------------------------------------
# Each is an unbounded global.<x>level counter in the vanilla game; we cap it
# at a configurable number of tiers and hand out the increments as progression
# items.
SHOPS = [
    # (key, gml global, display name, npc sprite, item name)
    ("blacksmith", "dlevel", "Blacksmith", "sprNPC_Blacksmith", "Progressive Damage"),
    ("apothecary", "hlevel", "Apothecary", "sprNPC_Healer",     "Progressive Max HP"),
    ("monk",       "plevel", "Monk",       "sprNPC_MonkC",      "Progressive Orb XP"),
]

# How many tiers each shop CAN have. This is the id space, not the slot's
# setting: ids must be identical for every player in a multiworld, so the
# tables always describe MAX_SHOP_TIERS tiers and the slot's own
# `shop_upgrade_tiers` selects how many of them are actually in play.
MIN_SHOP_TIERS = 15
MAX_SHOP_TIERS = 30
DEFAULT_SHOP_TIERS = 20

# Vanilla pricing, kept as the defaults so an unconfigured yaml plays exactly
# as the game always did:
#
#   global.dprice = 25 + floor(dlevel / 10) * 25
#   cost          = dlevel * global.dprice
#
# i.e. the price climbs by 25 coins for every tier already bought, and the
# *rate* of that climb steps up by another 25 every ten tiers. The step-up is
# every ten tiers, not fifteen -- with the vanilla 15-tier cap it therefore
# fires exactly once, at tier 10, which is what makes the back half of a shop
# feel like a wall.
SHOP_PRICE_CLIFF_EVERY = 10
DEFAULT_SHOP_PRICE_STEP = 25
DEFAULT_SHOP_PRICE_CLIFF = 25

# --- levels -----------------------------------------------------------------
# global.mapArray[1..11]; enemy_boss[11] == "Chosen One" is the finale.
#
# A level is "cleared" when the hero takes the portal out of it (activate_block,
# block_type == "portal"). That is deliberately not the same as "killed the
# Guardian" -- the portal tile reads "Defeat the <boss> OR Unlock with 5 Keys!",
# so keying to the portal is the only signal that covers both routes.
CLEAR_LEVELS = list(range(1, 11))   # levels 1..10

# The finale is the 10-round Chosen One gauntlet, which ends at
# `global.gameDone += 1` in obGameControl_Step_0. This is the goal.
GOAL_LOCATION = "Defeat the Chosen One"
FINAL_LEVEL = 11

# Shortcuts unlock travel to levels 2..11 (global.skipLevel).
SHORTCUT_LEVELS = list(range(2, FINAL_LEVEL + 1))

# --- shrines ----------------------------------------------------------------
# place_tiles drops a random shrine on roughly one tile in fifty, but only on
# real levels: the random-tile branch is gated on
# `global.mapCode != 0 && global.mapCode != 11 && global.linesPlaced > 6`, so
# neither the village nor the Chosen One gauntlet ever grows one.
#
# The first `shrine_checks` shrines you activate on a level are locations.
# After that the level is simply out of Archipelago slots -- shrines go on
# spawning and go on working, they just stop checking anything. Activating a
# shrine always does what it always did; the check rides along, the way a level
# clear does.
#
# As with shop tiers, the id space is the maximum and the slot picks how much
# of it is live.
MAX_SHRINES_PER_LEVEL = 10
DEFAULT_SHRINE_CHECKS = 5
SHRINE_LEVELS = list(range(1, 11))   # levels 1..10, same as CLEAR_LEVELS

# --- level access ------------------------------------------------------------
# Optional (see the `level_locks` option). Levels 2..11 each need to have been
# unlocked before the hero may descend into them; taking the exit portal of a
# level whose successor is still locked drops you back into the village with
# your hero intact, so the level clear still counts and the run continues from
# the top. Level 1 is always open -- there has to be somewhere to play.
LEVEL_ITEM_NAME = "Progressive Level Access"
ACCESS_LEVELS = list(range(2, FINAL_LEVEL + 1))

# --- filler and traps --------------------------------------------------------
# (name, effect key). The effect key is what the GML dispatches on, so adding
# one here plus a branch in gml/ap_effect.gml is the whole job.
#
# Everything except Coin Cache needs a living hero, so ap_effect queues those
# and ap_consume drains the queue on the first frame that has one. Coins are a
# global that persists across runs, so they land immediately.
FILLERS = [
    ("Coin Cache",   "coins"),
    ("Shrine Boost", "shrine"),
    ("Mana Refill",  "mana"),
    ("Skeleton Key", "key"),
]
TRAPS = [
    ("Alarm Trap", "alarm"),
]
FILLER_NAME = FILLERS[0][0]


# --- id assignment ----------------------------------------------------------
# IDs are assigned by walking the tables in a fixed order. Appending to a list
# is safe; inserting or reordering is not.

def _seq(start):
    n = [start]

    def nxt():
        v = n[0]
        n[0] += 1
        return v
    return nxt


def build_locations():
    """Returns list of (name, id, category, meta)."""
    nxt = _seq(BASE_ID)
    out = []
    # Merchant purchases, numbered 1..50 overall and grouped by the level that
    # the vanilla spawn cap first makes them reachable on.
    for i in range(1, TOTAL_SKILLS + 1):
        lvl = -(-i // UNLOCKS_PER_LEVEL)          # ceil
        slot = i - (lvl - 1) * UNLOCKS_PER_LEVEL
        out.append((f"Level {lvl} Merchant Unlock {slot}", nxt(), "unlock",
                    {"order": i, "level": lvl, "slot": slot}))
    for key, glob, disp, sprite, _item in SHOPS:
        for tier in range(1, MAX_SHOP_TIERS + 1):
            out.append((f"{disp} Upgrade {tier}", nxt(), "shop",
                        {"shop": key, "glob": glob, "tier": tier}))
    for lvl in SHORTCUT_LEVELS:
        out.append((f"Shortcut to Level {lvl}", nxt(), "shortcut", {"level": lvl}))
    for lvl in CLEAR_LEVELS:
        out.append((f"Level {lvl} Cleared", nxt(), "clear", {"level": lvl}))
    for lvl in SHRINE_LEVELS:
        for n in range(1, MAX_SHRINES_PER_LEVEL + 1):
            out.append((f"Level {lvl} Shrine {n}", nxt(), "shrine",
                        {"level": lvl, "slot": n}))
    out.append((GOAL_LOCATION, nxt(), "goal", {"level": FINAL_LEVEL}))
    return out


def build_items():
    """Returns list of (name, id, classification, count, meta)."""
    nxt = _seq(BASE_ID)
    out = []
    for kind, arr, names in SKILL_GROUPS:
        for idx, name in enumerate(names):
            out.append((f"Unlock: {name}", nxt(), "useful", 1,
                        {"kind": kind, "arr": arr, "index": idx, "skill": name}))
    for key, glob, disp, sprite, item in SHOPS:
        out.append((item, nxt(), "progression", MAX_SHOP_TIERS,
                    {"shop": key, "glob": glob}))
    out.append(("Progressive Shortcut", nxt(), "progression",
                len(SHORTCUT_LEVELS), {"shortcut": True}))
    out.append((LEVEL_ITEM_NAME, nxt(), "progression",
                len(ACCESS_LEVELS), {"level_access": True}))
    for name, effect in FILLERS:
        out.append((name, nxt(), "filler", 0,
                    {"filler": True, "effect": effect}))
    for name, effect in TRAPS:
        out.append((name, nxt(), "trap", 0,
                    {"trap": True, "effect": effect}))
    return out


LOCATIONS = build_locations()
ITEMS = build_items()

LOCATION_BY_NAME = {n: (i, c, m) for n, i, c, m in LOCATIONS}
ITEM_BY_NAME = {n: (i, c, cnt, m) for n, i, c, cnt, m in ITEMS}


if __name__ == "__main__":
    print(f"{len(LOCATIONS)} locations, id {LOCATIONS[0][1]}..{LOCATIONS[-1][1]}")
    print(f"{len(ITEMS)} item types, id {ITEMS[0][1]}..{ITEMS[-1][1]}")
    prog = sum(c for _n, _i, cl, c, _m in ITEMS if cl == "progression")
    useful = sum(1 for _n, _i, cl, _c, _m in ITEMS if cl == "useful")
    print(f"  useful copies: {useful}, progression copies: {prog}")
    print(f"  filler slots to fill: {len(LOCATIONS) - useful - prog}")
