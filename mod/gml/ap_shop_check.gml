// ap_shop_check(shop) -- the player bought from a hub merchant.
// 0=Blacksmith(damage) 1=Apothecary(max HP) 2=Monk(orb XP).

if (!global.ap_enabled)
{
    exit;
}
var t = ap_shop_next_tier(argument0);
if (t > 0)
{
    global.ap_sent_shop[argument0, t] = 1;
    ap_check(global.ap_shop_loc[argument0, t]);
}
