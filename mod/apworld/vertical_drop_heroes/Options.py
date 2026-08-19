from dataclasses import dataclass

from Options import (Choice, DeathLink, DefaultOnToggle, PerGameCommonOptions,
                     Range, Toggle)


class ShopTiers(Range):
    """How many upgrade tiers each between-run merchant sells.

    The Blacksmith (damage), Apothecary (max HP) and Monk (orb XP) each get
    this many locations, and the matching progressive item gets this many
    copies. Lowering it makes for a shorter game.
    """
    display_name = "Shop Tiers"
    range_start = 5
    range_end = 15
    default = 15


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


class LogicDifficulty(Choice):
    """How much power the logic assumes you need to reach a given depth.

    relaxed  - expects more upgrades before requiring deep levels
    standard - a moderate curve
    tricky   - expects you to push deep with very little
    """
    display_name = "Logic Difficulty"
    option_relaxed = 0
    option_standard = 1
    option_tricky = 2
    default = 1


class TrapFill(Range):
    """Percentage of filler slots replaced by traps."""
    display_name = "Trap Fill Percentage"
    range_start = 0
    range_end = 100
    default = 0


@dataclass
class VDHOptions(PerGameCommonOptions):
    shop_tiers: ShopTiers
    include_shortcuts: IncludeShortcuts
    include_level_clears: IncludeLevelClears
    logic_difficulty: LogicDifficulty
    trap_fill: TrapFill
    death_link: DeathLink
