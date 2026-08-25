"""Access rules.

Two curves, both linear, both scaled so that a shop is exhausted exactly as
the last ordinary level comes into reach. With the default 20 tiers that is
two tiers per level; with the vanilla 15 it is the original 1.5.

**What a level offers.** By the time you can play level L you are expected to
have been able to buy ``floor(rate * L)`` tiers of each hub shop, where
``rate = shop_tiers / 10``:

    level   1  2  3  4  5  6  7  8  9  10
    tiers   2  4  6  8 10 12 14 16 18  20     (shop_tiers = 20)

**What a level demands.** Reaching level L expects the tiers the levels below
it offered, i.e. ``floor(rate * (L - 1))`` of each of Progressive Damage,
Progressive Max HP and Progressive Orb XP:

    level   1  2  3  4  5  6  7  8  9 10 11
    need    0  2  4  6  8 10 12 14 16 18 20   (shop_tiers = 20)

Level 1 demands nothing, which is what puts the five level-1 merchant unlocks,
the first tier of each shop, and "Level 1 Cleared" in sphere 0.

Orb XP counts. Pacifist orbs are a primary source of hero levels and levels
scale everything, so orb XP is survivability just as much as max HP is -- and
it costs the same at the shop, so it belongs on the same curve.

The goal therefore requires all tiers of all three. That is the point rather
than a side effect: an access rule is a statement about what must not be placed
*behind* a location. If the goal did not require them, generation would be free
to bury a Progressive Damage behind the goal check, and a player who needed
that damage to finish would be stuck.

**Level locks**, when enabled, add a second and much blunter requirement on top
of the curve: L - 1 copies of Progressive Level Access to set foot in level L.
The curve says "you should survive down there"; the locks say "you are allowed
down there at all". They stack rather than replace, which is what makes the
option worth the name.

Progressive Shortcut is deliberately not a requirement in either mode: it lets
you *start* deeper but grants no power, so it cannot substitute for surviving
down there.
"""

import math

from BaseClasses import CollectionState

from .defs import FINAL_LEVEL, LEVEL_ITEM_NAME

# Levels 1..FINAL_LEVEL-1 are the ordinary descent; FINAL_LEVEL is the finale.
# A shop is meant to run dry exactly as the last ordinary level opens up.
LEVELS_OF_DESCENT = FINAL_LEVEL - 1


def tiers_per_level(shop_tiers: int) -> float:
    return shop_tiers / float(LEVELS_OF_DESCENT)


def tiers_offered_by(level: int, shop_tiers: int) -> int:
    """How many tiers of each shop are buyable once level `level` is playable."""
    return min(shop_tiers, math.floor(tiers_per_level(shop_tiers) * level))


def depth_requirement(level: int, shop_tiers: int) -> int:
    """Upgrades of each of damage, max HP and orb XP expected to reach `level`."""
    return min(shop_tiers,
               math.floor(tiers_per_level(shop_tiers) * (level - 1)))


def level_for_shop_tier(tier: int, shop_tiers: int) -> int:
    """Shallowest level at which `tier` is on sale."""
    for level in range(1, FINAL_LEVEL + 1):
        if tiers_offered_by(level, shop_tiers) >= tier:
            return level
    return FINAL_LEVEL


def can_reach_level(state: CollectionState, player: int, level: int,
                    shop_tiers: int, level_locks: bool) -> bool:
    if level_locks and level > 1:
        if not state.has(LEVEL_ITEM_NAME, player, level - 1):
            return False
    need = depth_requirement(level, shop_tiers)
    if need <= 0:
        return True
    return (state.has("Progressive Damage", player, need)
            and state.has("Progressive Max HP", player, need)
            and state.has("Progressive Orb XP", player, need))


def set_rules(world, options) -> None:
    player = world.player
    multiworld = world.multiworld
    shop_tiers = int(options.shop_upgrade_tiers)
    level_locks = bool(options.level_locks)

    from .Locations import locations_for

    for name, data in locations_for(options).items():
        loc = multiworld.get_location(name, player)

        if data.category == "shop":
            level = level_for_shop_tier(data.meta["tier"], shop_tiers)
        else:
            # unlock / clear / shortcut / shrine / goal carry their own level.
            level = data.meta["level"]

        loc.access_rule = (
            lambda state, l=level: can_reach_level(
                state, player, l, shop_tiers, level_locks))

    multiworld.completion_condition[player] = (
        lambda state: can_reach_level(
            state, player, FINAL_LEVEL, shop_tiers, level_locks))
