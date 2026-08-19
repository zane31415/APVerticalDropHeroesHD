// ap_shop_open(shop_index) -- does this between-run merchant still have a
// tier left to sell? Used to stop charging coins for nothing once all 15
// tiers of a shop have been checked.

if (!global.ap_enabled)
{
    return 1;
}
var s = argument0;
for (var t = 1; t <= global.ap_max_shop_tier; t += 1)
{
    if (global.ap_sent_shop[s, t] < 1)
    {
        return 1;
    }
}
return 0;
