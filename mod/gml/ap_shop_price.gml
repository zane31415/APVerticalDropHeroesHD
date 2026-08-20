// ap_shop_price(shop) -- cost of the next purchase from a hub merchant.
//
// Vanilla priced this off global.<x>level, which under AP is driven by
// RECEIVED items -- so a player who had checked five tiers but received none
// would still pay tier-1 prices forever. Price off the number of purchases
// actually made instead.

var base;
if (argument0 == 0)
{
    base = global.dprice;
}
else if (argument0 == 1)
{
    base = global.hprice;
}
else
{
    base = global.pprice;
}

if (!global.ap_enabled)
{
    if (argument0 == 0)
    {
        return global.dlevel * base;
    }
    if (argument0 == 1)
    {
        return global.hlevel * base;
    }
    return global.plevel * base;
}

var t = ap_shop_next_tier(argument0);
if (t <= 0)
{
    return 999999999;   // sold out: never affordable, so the sale never fires
}
return t * base;
