// ap_shop_next_tier(shop) -- lowest tier not yet checked, 1..tiers, or 0.
//
// Bounded by ap_shop_tiers (this slot's setting), not ap_max_shop_tier (the
// id space). Tiers past the slot's count have ids and table entries but no
// locations on the server, so offering them would sell nothing.

for (var t = 1; t <= global.ap_shop_tiers; t += 1)
{
    if (global.ap_sent_shop[argument0, t] < 1)
    {
        return t;
    }
}
return 0;
