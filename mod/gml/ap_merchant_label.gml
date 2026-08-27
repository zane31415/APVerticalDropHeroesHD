// ap_merchant_label(current) -- the item name a Merchant sale should announce.
//
// The unlock popup and the float-up text both read the Merchant's longtext2,
// which set_merchant wrote when that Merchant was placed. Under Archipelago
// that name is a snapshot of "whatever ap_merchant_next() said back then", and
// the answer moves the instant ANY Merchant is bought from -- so the second
// sale on a level announced the item belonging to the location the first sale
// had already taken. It checked the right location; only the name was stale.
//
// ap_merchant_restock was the first attempt at this and cannot fix it. Its
// `with (obDecor)` only reaches ACTIVE instances, and obGameControl's Step
// deactivates everything outside a band around the camera every time the top
// grid cell changes -- obDecor by name, then a region activate for the band.
// A Merchant off screen is a deactivated instance, invisible to `with`, which
// is why every live log says "restock: 1 Merchant(s)": the one just bought
// from, standing right there. (Rows are also built as the player descends, so
// a Merchant further down may not exist at all yet.)
//
// So the name is derived at the point of sale instead, from the location the
// purchase is about to check, which cannot be a frame behind anything. Called
// from activate_block's merchant branch immediately before new_unlock, i.e.
// while ap_merchant_next() still points at the slot being bought.
//
// argument0 is the Merchant's own longtext2, which is what an offline game --
// or a purchase with nothing left to sell -- should keep using.

if (!global.ap_enabled)
{
    return argument0;
}

var n = ap_merchant_next();
if (n <= 0)
{
    return argument0;
}

var nm = ap_scout_name(global.ap_unlock_loc[n]);
if (nm == "")
{
    nm = "Unlock " + string(n);
}

ap_debug("merchant label: slot " + string(n) + " -> '" + nm +
         "' (sign said '" + string(argument0) + "')");
return nm;
