"""Archipelago world for Vertical Drop Heroes HD (GameMaker: Studio 1.4).

The game side is a patched data.win talking to an Archipelago server through
black-sliver's gm-apclientpp. See mod/build/ for the patcher.
"""

from typing import Any, Dict, List

from BaseClasses import Item, ItemClassification, Region, Tutorial
from worlds.AutoWorld import WebWorld, World

from .defs import (FILLER_NAME, GAME_NAME, GOAL_LOCATION,
                   SHOP_PRICE_CLIFF_EVERY)
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
            if data.meta.get("shortcut") and not self.options.include_shortcuts:
                continue
            if data.meta.get("level_access") and not self.options.level_locks:
                continue
            count = data.max_count
            if "shop" in data.meta:
                # One progressive upgrade per tier this slot actually plays.
                count = int(self.options.shop_upgrade_tiers)
            pool += [self.create_item(name) for _ in range(count)]

        # Pad to the location count with filler.
        remaining = len(enabled) - len(pool)
        if remaining < 0:
            # More items than locations. Reachable with level locks on and one
            # of the optional location categories off -- turning shortcuts or
            # level clears off removes ten locations while level locks add ten
            # items. Progression must all be placed, so the overflow comes out
            # of the skill unlocks: those are `useful`, and a skill that is
            # never placed is simply a skill this seed does not offer.
            useful = [i for i in pool
                      if i.classification == ItemClassification.useful]
            for item in useful[remaining:]:
                pool.remove(item)
            remaining = len(enabled) - len(pool)

        # Whatever is left over is filler, of which some percentage is traps.
        # Traps only ever displace filler, never anything that carries power.
        traps = remaining * int(self.options.trap_fill) // 100
        trap_names = [n for n, d in item_table.items() if d.meta.get("trap")]
        if not trap_names:
            traps = 0
        for _ in range(traps):
            pool.append(self.create_item(self.random.choice(trap_names)))
        for _ in range(remaining - traps):
            pool.append(self.create_item(self.get_filler_item_name()))

        self.multiworld.itempool += pool

    def set_rules(self) -> None:
        set_rules(self, self.options)

    def get_filler_item_name(self) -> str:
        names = [n for n, d in item_table.items() if d.meta.get("filler")]
        return self.random.choice(names) if names else FILLER_NAME

    def fill_slot_data(self) -> Dict[str, Any]:
        # The game reads this on ap_slot_connected and reconfigures itself from
        # it, so every option that changes in-game behaviour has to ride along.
        # Booleans go over as 0/1: the GML side reads slot_data through
        # apclient_json_number_at.
        return {
            "include_shortcuts": int(bool(self.options.include_shortcuts)),
            "include_level_clears": int(bool(self.options.include_level_clears)),
            "shop_upgrade_tiers": int(self.options.shop_upgrade_tiers),
            "shop_price_step": int(self.options.shop_price_step),
            "shop_price_cliff": int(self.options.shop_price_cliff),
            "shop_price_cliff_every": SHOP_PRICE_CLIFF_EVERY,
            "level_locks": int(bool(self.options.level_locks)),
            "shrine_checks": int(self.options.shrine_checks),
            "death_link": int(bool(self.options.death_link)),
        }
