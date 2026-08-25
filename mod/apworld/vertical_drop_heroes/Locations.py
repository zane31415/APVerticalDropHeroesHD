from typing import Dict, NamedTuple

from BaseClasses import Location

from .defs import LOCATIONS


class VDHLocation(Location):
    game = "Vertical Drop Heroes HD"


class LocData(NamedTuple):
    code: int
    category: str
    meta: dict


location_table: Dict[str, LocData] = {
    name: LocData(code, cat, meta) for name, code, cat, meta in LOCATIONS
}

location_name_to_id: Dict[str, int] = {n: d.code for n, d in location_table.items()}


def locations_for(options) -> Dict[str, LocData]:
    """The subset of locations enabled by this slot's options."""
    out: Dict[str, LocData] = {}
    tiers = int(options.shop_upgrade_tiers)
    shrines = int(options.shrine_checks)
    for name, data in location_table.items():
        if data.category == "shortcut" and not options.include_shortcuts:
            continue
        if data.category == "clear" and not options.include_level_clears:
            continue
        # The tables always describe MAX_SHOP_TIERS tiers so that ids are the
        # same for everyone; this slot only plays the first `tiers` of them.
        if data.category == "shop" and data.meta["tier"] > tiers:
            continue
        # Same story for shrines: the table holds MAX_SHRINES_PER_LEVEL per
        # level and the slot plays the first `shrine_checks` of them. 0 drops
        # the category entirely.
        if data.category == "shrine" and data.meta["slot"] > shrines:
            continue
        out[name] = data
    return out
