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
    for name, data in location_table.items():
        if data.category == "shortcut" and not options.include_shortcuts:
            continue
        if data.category == "clear" and not options.include_level_clears:
            continue
        out[name] = data
    return out
