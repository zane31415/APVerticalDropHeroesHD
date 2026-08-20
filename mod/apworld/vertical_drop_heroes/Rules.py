"""Access rules.

What limits you is depth, and the game says so itself.

Merchant unlocks are capped by spawn_shop:

    (global.unlocked + merchantSpawned) < min(50, global.enemyLevel * 5)

so the Nth unlock you ever buy is unreachable until level ceil(N / 5). That is
a real, pre-existing constraint, not one this world invented, and the "Level N
Merchant Unlock M" locations are named to expose it.

Beyond that, enemies scale hard with global.enemyLevel,
and the only permanent power in the game is the Blacksmith's damage and the
Apothecary's max HP. So depth-dependent locations require those, and they are
what forms the progression spine.

Progressive Shortcut deliberately does *not* satisfy a depth requirement: it
lets you start deeper, but it grants no power, so it cannot substitute for
being able to survive down there.
"""

from BaseClasses import CollectionState

# level -> upgrades of *each* of damage/HP expected, per difficulty.
# Level 1 must come out at 0 on every setting: it is the game's opening level
# and is clearable with a starting hero and nothing else. Anything above 0
# there would make sphere 0 unable to reach even the first shop tier.
_CURVE = {
    0: lambda lvl: max(0, lvl - 1),      # relaxed  (assumes you need the most)
    1: lambda lvl: max(0, lvl - 3),      # standard
    2: lambda lvl: max(0, lvl - 5),      # tricky   (assumes you can push deep)
}


def depth_requirement(options, level: int) -> int:
    need = _CURVE[options.logic_difficulty.value](level)
    return min(need, options.shop_tiers.value)


def can_reach_level(state: CollectionState, player: int, options, level: int) -> bool:
    need = depth_requirement(options, level)
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

        if data.category == "clear":
            lvl = data.meta["level"]
            loc.access_rule = (
                lambda state, l=lvl: can_reach_level(state, player, options, l))

        elif data.category == "goal":
            # bind through a default arg: `data` is the loop variable
            loc.access_rule = (
                lambda state, l=data.meta["level"]:
                    can_reach_level(state, player, options, l))

        elif data.category == "shortcut":
            lvl = data.meta["level"]
            loc.access_rule = (
                lambda state, l=lvl: can_reach_level(state, player, options, l))

        elif data.category == "shop":
            # Upgrade tiers cost escalating coins, and coin income scales with
            # depth. Roughly a third of a level of depth per tier.
            lvl = max(1, -(-data.meta["tier"] // 3))
            loc.access_rule = (
                lambda state, l=lvl: can_reach_level(state, player, options, l))

        elif data.category == "unlock":
            # Depth requirement is the game's own merchant spawn cap.
            lvl = data.meta["level"]
            loc.access_rule = (
                lambda state, l=lvl: can_reach_level(state, player, options, l))

    from .defs import FINAL_LEVEL
    multiworld.completion_condition[player] = (
        lambda state: can_reach_level(state, player, options, FINAL_LEVEL))
