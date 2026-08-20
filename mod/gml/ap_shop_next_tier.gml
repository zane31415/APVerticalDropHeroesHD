// ap_shop_next_tier(shop) -- lowest tier not yet checked, 1..max, or 0.

for (var t = 1; t <= global.ap_max_shop_tier; t += 1)
{
    if (global.ap_sent_shop[argument0, t] < 1)
    {
        return t;
    }
}
return 0;
