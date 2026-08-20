from dataclasses import dataclass

from Options import DefaultOnToggle, PerGameCommonOptions


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


@dataclass
class VDHOptions(PerGameCommonOptions):
    include_shortcuts: IncludeShortcuts
    include_level_clears: IncludeLevelClears
