from dataclasses import dataclass

from Options import DeathLink, DefaultOnToggle, PerGameCommonOptions, Range


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


class TrapFill(Range):
    """Percentage of filler slots replaced by traps."""
    display_name = "Trap Fill Percentage"
    range_start = 0
    range_end = 100
    default = 0


@dataclass
class VDHOptions(PerGameCommonOptions):
    include_shortcuts: IncludeShortcuts
    include_level_clears: IncludeLevelClears
    trap_fill: TrapFill
    death_link: DeathLink
