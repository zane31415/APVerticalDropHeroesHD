// ap_shop_price(shop) -- cost of the next purchase from a hub merchant.
//
// Vanilla priced this off global.<x>level, which under AP is driven by
// RECEIVED items -- so a player who had checked five tiers but received none
// would still pay tier-1 prices forever. Price off the number of purchases
// actually made instead.
//
// The curve is vanilla's, re-derived from that purchase count so it has one
// definition rather than borrowing global.dprice (which obGameControl's Step
// recomputes from the received-item side and would therefore disagree):
//
//     global.dprice = 25 + floor(dlevel / 10) * 25
//     cost          = dlevel * global.dprice
//
// With the default step of 25, cliff of 25 and interval of 10 this reproduces
// vanilla's numbers exactly. The yaml can flatten the cliff to 0 for a purely
// linear climb, or steepen either term.

if (!global.ap_enabled)
{
    if (argument0 == 0)
    {
        return global.dlevel * global.dprice;
    }
    if (argument0 == 1)
    {
        return global.hlevel * global.hprice;
    }
    return global.plevel * global.pprice;
}

var t = ap_shop_next_tier(argument0);
if (t <= 0)
{
    return 999999999;   // sold out: never affordable, so the sale never fires
}

var rate = global.ap_shop_price_step
         + (floor(t / global.ap_shop_cliff_every) * global.ap_shop_price_cliff);
return t * rate;
