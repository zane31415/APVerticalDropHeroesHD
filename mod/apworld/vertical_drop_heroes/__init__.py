"""Archipelago world for Vertical Drop Heroes HD (GameMaker: Studio 1.4).

The game side is a patched data.win talking to an Archipelago server through
black-sliver's gm-apclientpp. See mod/build/ for the patcher.
"""

from typing import Any, Dict, List

from BaseClasses import Item, ItemClassification, Region, Tutorial
from worlds.AutoWorld import WebWorld, World

from .defs import FILLER_NAME, GAME_NAME, GOAL_LOCATION, TRAP_NAME
from .Items import VDHItem, item_name_groups, item_name_to_id, item_table
from .Locations import VDHLocation, location_name_to_id, locations_for
from .Options import VDHOptions
from .Rules import set_rules


class VDHWeb(WebWorld):
    theme = "dirt"
    tutorials = [Tutorial(
        "Multiworld Setup Guide",
        "A guide to setting up Vertical Drop Heroes HD for Archipelago.",
        "English", "setup_en.md", "setup/en",
        ["Zane"],
    )]


class VDHWorld(World):
    """Vertical Drop Heroes HD is a roguelike platformer where you descend
    procedurally generated levels, unlocking traits and powers between runs."""

    game = GAME_NAME
    options_dataclass = VDHOptions
    options: VDHOptions
    web = VDHWeb()

    item_name_to_id = item_name_to_id
    location_name_to_id = location_name_to_id
    item_name_groups = item_name_groups()

    def create_item(self, name: str) -> Item:
        data = item_table[name]
        return VDHItem(name, data.classification, data.code, self.player)

    def create_event(self, name: str) -> Item:
        return VDHItem(name, ItemClassification.progression, None, self.player)

    def create_regions(self) -> None:
        menu = Region("Menu", self.player, self.multiworld)
        self.multiworld.regions.append(menu)

        depths = Region("The Descent", self.player, self.multiworld)
        self.multiworld.regions.append(depths)
        menu.connect(depths)

        for name, data in locations_for(self.options).items():
            depths.locations.append(
                VDHLocation(self.player, name, data.code, depths))

    def create_items(self) -> None:
        enabled = locations_for(self.options)
        pool: List[Item] = []

        for name, data in item_table.items():
            if data.meta.get("filler") or data.meta.get("trap"):
                continue
            count = data.max_count
            if "shop" in data.meta:
                count = self.options.shop_tiers.value
            elif data.meta.get("shortcut"):
                if not self.options.include_shortcuts:
                    continue
            pool += [self.create_item(name) for _ in range(count)]

        # Pad to the location count with filler (and traps, if asked for).
        remaining = len(enabled) - len(pool)
        if remaining < 0:
            # More items than locations: trim useful skills last-in-first-out.
            # Should not happen with the shipped tables, but keep generation
            # from hard-failing if someone edits defs.py.
            useful = [i for i in pool
                      if i.classification == ItemClassification.useful]
            for item in useful[remaining:]:
                pool.remove(item)
            remaining = len(enabled) - len(pool)

        traps = remaining * self.options.trap_fill.value // 100
        pool += [self.create_item(TRAP_NAME) for _ in range(traps)]
        pool += [self.create_item(FILLER_NAME) for _ in range(remaining - traps)]

        self.multiworld.itempool += pool

    def set_rules(self) -> None:
        set_rules(self, self.options)

    def get_filler_item_name(self) -> str:
        return FILLER_NAME

    def fill_slot_data(self) -> Dict[str, Any]:
        return {
            "shop_tiers": self.options.shop_tiers.value,
            "include_shortcuts": bool(self.options.include_shortcuts),
            "include_level_clears": bool(self.options.include_level_clears),
            "logic_difficulty": self.options.logic_difficulty.value,
            "death_link": bool(self.options.death_link),
        }
