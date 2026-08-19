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

# --- between-run shops ------------------------------------------------------
# Each is an unbounded global.<x>level counter in the vanilla game; we cap it
# at MAX_SHOP_TIERS tiers and hand out the increments as progression items.
SHOPS = [
    # (key, gml global, display name, npc sprite, item name)
    ("blacksmith", "dlevel", "Blacksmith", "sprNPC_Blacksmith", "Progressive Damage"),
    ("apothecary", "hlevel", "Apothecary", "sprNPC_Healer",     "Progressive Max HP"),
    ("monk",       "plevel", "Monk",       "sprNPC_MonkC",      "Progressive Orb XP"),
]
MAX_SHOP_TIERS = 15

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

FILLER_NAME = "Coin Cache"
TRAP_NAME = "Fragile Hero Trap"


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
    for kind, arr, names in SKILL_GROUPS:
        for idx, name in enumerate(names):
            out.append((f"Unlock: {name}", nxt(), "skill",
                        {"kind": kind, "arr": arr, "index": idx, "skill": name}))
    for key, glob, disp, sprite, _item in SHOPS:
        for tier in range(1, MAX_SHOP_TIERS + 1):
            out.append((f"{disp} Upgrade {tier}", nxt(), "shop",
                        {"shop": key, "glob": glob, "tier": tier}))
    for lvl in SHORTCUT_LEVELS:
        out.append((f"Shortcut to Level {lvl}", nxt(), "shortcut", {"level": lvl}))
    for lvl in CLEAR_LEVELS:
        out.append((f"Level {lvl} Cleared", nxt(), "clear", {"level": lvl}))
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
    out.append((FILLER_NAME, nxt(), "filler", 0, {"filler": True}))
    out.append((TRAP_NAME, nxt(), "trap", 0, {"trap": True}))
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
