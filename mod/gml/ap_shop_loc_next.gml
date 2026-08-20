// ap_shop_loc_next(shop) -- location id of the next tier, or -1 if sold out.

var t = ap_shop_next_tier(argument0);
if (t <= 0)
{
    return -1;
}
return global.ap_shop_loc[argument0, t];
