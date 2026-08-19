from typing import Dict, NamedTuple, Optional

from BaseClasses import Item, ItemClassification

from .defs import ITEMS


class VDHItem(Item):
    game = "Vertical Drop Heroes HD"


class ItemData(NamedTuple):
    code: int
    classification: ItemClassification
    max_count: int
    meta: dict


_CLASSIFICATION = {
    "progression": ItemClassification.progression,
    "useful": ItemClassification.useful,
    "filler": ItemClassification.filler,
    "trap": ItemClassification.trap,
}

item_table: Dict[str, ItemData] = {
    name: ItemData(code, _CLASSIFICATION[cls], count, meta)
    for name, code, cls, count, meta in ITEMS
}

item_name_to_id: Dict[str, int] = {n: d.code for n, d in item_table.items()}


def item_name_groups() -> Dict[str, set]:
    groups: Dict[str, set] = {"Traits": set(), "Powers": set(), "Upgrades": set()}
    for name, data in item_table.items():
        kind = data.meta.get("kind")
        if kind == "trait":
            groups["Traits"].add(name)
        elif kind in ("power1", "power2"):
            groups["Powers"].add(name)
        elif "shop" in data.meta or data.meta.get("shortcut"):
            groups["Upgrades"].add(name)
    return groups
