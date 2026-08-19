// ap_shop_check(shop_index) -- called when the player buys from a between-run
// merchant. 0=Blacksmith(dmg) 1=Apothecary(hp) 2=Monk(orb xp).
//
// The tier checked is "the next unchecked tier", not the current <x>level:
// under AP the level counter is driven by received items, so it cannot double
// as a purchase counter.

if (!global.ap_enabled)
{
    exit;
}

var s = argument0;
for (var t = 1; t <= global.ap_max_shop_tier; t += 1)
{
    if (global.ap_sent_shop[s, t] < 1)
    {
        ap_check(global.ap_shop_loc[s, t]);
        exit;
    }
}
