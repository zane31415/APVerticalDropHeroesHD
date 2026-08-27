// ap_merchant_label(current) -- the item name a Merchant sale should announce.
//
// The unlock popup and the float-up text both read the Merchant's longtext2,
// which set_merchant wrote when that Merchant was placed. Under Archipelago
// that name is a snapshot of "whatever ap_merchant_next() said back then", and
// the answer moves the instant ANY Merchant is bought from -- so the second
// sale on a level announced the item belonging to the location the first sale
// had already taken. It checked the right location; only the name was stale.
//
// ap_merchant_restock was the first attempt at this and could not fix it: it
// can only reach Merchants that exist as instances right now, and place_tiles
// builds a level's rows as the player descends, so the Merchant further down
// is often not created yet when the one above it is sold (the live logs show
// "restock: 1 Merchant(s)" at every sale -- only the one just bought from).
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
