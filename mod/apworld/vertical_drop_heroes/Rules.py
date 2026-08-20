"""Access rules.

Two curves, both linear at 1.5 shop tiers per level.

**What a level offers.** By the time you can play level L you are expected to
have been able to buy ``floor(1.5 * L)`` tiers of each hub shop:

    level   1  2  3  4  5  6  7  8  9  10
    tiers   1  3  4  6  7  9 10 12 13  15

So all fifteen tiers of each shop are purchasable by level 10.

**What a level demands.** Reaching level L expects the tiers the levels below
it offered, i.e. ``floor(1.5 * (L - 1))`` of both Progressive Damage and
Progressive Max HP:

    level   1  2  3  4  5  6  7  8  9 10 11
    need    0  1  3  4  6  7  9 10 12 13 15

Level 1 demands nothing, which is what puts the five level-1 merchant unlocks,
the first tier of each shop, and "Level 1 Cleared" in sphere 0.

Progressive Orb XP is not a requirement. It scales pacifist-orb XP gain, not
survivability, so demanding it would be claiming a dependency that does not
exist. It is still progression because it gates its own shop's locations.

Progressive Shortcut is likewise not a requirement: it lets you *start* deeper
but grants no power, so it cannot substitute for being able to survive there.
"""

import math

from BaseClasses import CollectionState

from .defs import FINAL_LEVEL, MAX_SHOP_TIERS

TIERS_PER_LEVEL = 1.5


def tiers_offered_by(level: int) -> int:
    """How many tiers of each shop are buyable once level `level` is playable."""
    return min(MAX_SHOP_TIERS, math.floor(TIERS_PER_LEVEL * level))


def depth_requirement(level: int) -> int:
    """Upgrades of each of damage and max HP expected to reach `level`."""
    return min(MAX_SHOP_TIERS, math.floor(TIERS_PER_LEVEL * (level - 1)))


def level_for_shop_tier(tier: int) -> int:
    """Shallowest level at which `tier` is on sale."""
    for level in range(1, FINAL_LEVEL + 1):
        if tiers_offered_by(level) >= tier:
            return level
    return FINAL_LEVEL


def can_reach_level(state: CollectionState, player: int, level: int) -> bool:
    need = depth_requirement(level)
    if need <= 0:
        return True
    return (state.has("Progressive Damage", player, need)
            and state.has("Progressive Max HP", player, need))


def set_rules(world, options) -> None:
    player = world.player
    multiworld = world.multiworld

    from .Locations import locations_for

    for name, data in locations_for(options).items():
        loc = multiworld.get_location(name, player)

        if data.category == "shop":
            level = level_for_shop_tier(data.meta["tier"])
        else:
            # unlock / clear / shortcut / goal all carry their own level.
            level = data.meta["level"]

        loc.access_rule = (
            lambda state, l=level: can_reach_level(state, player, l))

    multiworld.completion_condition[player] = (
        lambda state: can_reach_level(state, player, FINAL_LEVEL))
