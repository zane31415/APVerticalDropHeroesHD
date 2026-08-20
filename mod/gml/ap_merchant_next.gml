// ap_merchant_next() -- which merchant unlock this purchase should check.
//
// Locations are (level, slot), and a merchant standing on level L fills L's
// own slots first. Keying purely to global purchase order meant a merchant
// found on level 3 handed out "Level 1 Merchant Unlock 5" simply because that
// was the next number, which in turn meant an unbought level-1 slot could only
// ever be cleared by going back to level 1.
//
// If this level's slots are all checked we fall back to the deepest unchecked
// level below us rather than wasting the merchant. That stays logically sound:
// standing on level L proves every level below L is reachable.

var lvl = global.enemyLevel;
if (lvl < 1)
{
    lvl = 1;
}
if (lvl > global.ap_unlock_levels)
{
    lvl = global.ap_unlock_levels;
}

// this level first
for (var slot = 1; slot <= global.ap_unlocks_per_level; slot += 1)
{
    var order = ((lvl - 1) * global.ap_unlocks_per_level) + slot;
    if (global.ap_sent_unlock[order] < 1)
    {
        return order;
    }
}

// then mop up anything left behind on shallower levels
for (var l = lvl - 1; l >= 1; l -= 1)
{
    for (var slot = 1; slot <= global.ap_unlocks_per_level; slot += 1)
    {
        var order = ((l - 1) * global.ap_unlocks_per_level) + slot;
        if (global.ap_sent_unlock[order] < 1)
        {
            return order;
        }
    }
}
return 0;
