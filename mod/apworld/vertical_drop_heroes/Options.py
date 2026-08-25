from dataclasses import dataclass

from Options import DeathLink, DefaultOnToggle, PerGameCommonOptions, Range

from .defs import (DEFAULT_SHOP_PRICE_CLIFF, DEFAULT_SHOP_PRICE_STEP,
                   DEFAULT_SHOP_TIERS, DEFAULT_SHRINE_CHECKS, MAX_SHOP_TIERS,
                   MAX_SHRINES_PER_LEVEL, MIN_SHOP_TIERS)


class IncludeShortcuts(DefaultOnToggle):
    """Add the shortcut crystals as locations.

    Buying a shortcut crystal checks a location instead of unlocking the
    shortcut; Progressive Shortcut items unlock them instead.
    """
    display_name = "Include Shortcuts"


class IncludeLevelClears(DefaultOnToggle):
    """Add a location for clearing each of levels 1-10.

    A level counts as cleared when you take its exit portal, whether you
    killed the Guardian or opened the portal with keys.
    """
    display_name = "Include Level Clears"


class ShopUpgradeTiers(Range):
    """How many upgrades each of the three hub shops sells.

    The Blacksmith, Apothecary and Monk each sell this many tiers, so this is
    also three locations and three progression items per tier. Vanilla-style
    play is 15; the default of 20 spreads the same power over more checks.
    """
    display_name = "Shop Upgrade Tiers"
    range_start = MIN_SHOP_TIERS
    range_end = MAX_SHOP_TIERS
    default = DEFAULT_SHOP_TIERS


class ShopPriceStep(Range):
    """Coins a hub shop's price climbs per tier already bought.

    The Nth purchase from a shop costs N times this. Vanilla is 25, so the
    first upgrade is 25 coins and the tenth is 250.
    """
    display_name = "Shop Price Per Tier"
    range_start = 1
    range_end = 200
    default = DEFAULT_SHOP_PRICE_STEP


class ShopPriceCliff(Range):
    """Extra coins-per-tier added every 10 tiers bought.

    Vanilla raises the per-tier rate by 25 for every 10 upgrades you already
    own, which is the sudden price wall in the back half of a shop. Set this
    to 0 for a purely linear curve, or higher to make depth hurt more.
    """
    display_name = "Shop Price Cliff"
    range_start = 0
    range_end = 200
    default = DEFAULT_SHOP_PRICE_CLIFF


class LevelLocks(DefaultOnToggle):
    """Require an item before the hero may descend into each level.

    On (the default), levels 2-11 are locked and Progressive Level Access
    items open them in order. Taking the exit portal of a level whose
    successor is still locked still counts that level as cleared, but drops
    you back into the village with your hero, coins and unlocks intact --
    the descent simply stops there until Archipelago says otherwise.

    Off, every level is open from the start and only the shop-upgrade curve
    gates how deep the logic expects you to get.
    """
    display_name = "Level Locks"


class ShrineChecks(Range):
    """How many shrines on each level are Archipelago locations.

    Shrines spawn at random through a level and always do exactly what they
    always did; the first this many you activate on a level also check a
    location. After that the level is out of Archipelago slots and its shrines
    are back to being ordinary shrines.

    0 turns the feature off entirely.
    """
    display_name = "Shrine Checks Per Level"
    range_start = 0
    range_end = MAX_SHRINES_PER_LEVEL
    default = DEFAULT_SHRINE_CHECKS


class TrapFill(Range):
    """Percentage of the leftover filler slots that become traps instead.

    Only the slots no progression or skill item wanted are affected, so this
    never displaces anything that matters. At 0 there are no traps at all.
    """
    display_name = "Trap Fill Percentage"
    range_start = 0
    range_end = 100
    default = 0


@dataclass
class VDHOptions(PerGameCommonOptions):
    include_shortcuts: IncludeShortcuts
    include_level_clears: IncludeLevelClears
    shop_upgrade_tiers: ShopUpgradeTiers
    shop_price_step: ShopPriceStep
    shop_price_cliff: ShopPriceCliff
    level_locks: LevelLocks
    shrine_checks: ShrineChecks
    trap_fill: TrapFill
    death_link: DeathLink
