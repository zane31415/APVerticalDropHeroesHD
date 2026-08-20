// ap_merchant_next() -- which merchant unlock this purchase should check.
//
// Locations are (level, slot): a Merchant standing on level L fills one of
// L's OWN five slots, and nothing else. If all five are taken this Merchant
// has nothing to sell.
//
// No falling back to shallower levels. This is a roguelite -- the player
// re-runs earlier levels constantly, so a slot left behind on level 1 is not
// stranded, it is simply picked up on the next descent. Letting a deep
// Merchant mop up shallow slots only makes the deep run do double duty and
// muddies which level a location actually belongs to.

var lvl = global.enemyLevel;
if (lvl < 1)
{
    lvl = 1;
}
if (lvl > global.ap_unlock_levels)
{
    lvl = global.ap_unlock_levels;
}

for (var slot = 1; slot <= global.ap_unlocks_per_level; slot += 1)
{
    var order = ((lvl - 1) * global.ap_unlocks_per_level) + slot;
    if (global.ap_sent_unlock[order] < 1)
    {
        return order;
    }
}
return 0;
