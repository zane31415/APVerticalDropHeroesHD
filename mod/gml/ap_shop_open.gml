// ap_shop_open(shop) -- does this hub merchant still have a tier to sell?
// Stops him taking coins for nothing once all tiers are checked.

if (!global.ap_enabled)
{
    return 1;
}
return (ap_shop_next_tier(argument0) > 0);
