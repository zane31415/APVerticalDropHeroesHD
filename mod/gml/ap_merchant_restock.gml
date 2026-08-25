// ap_merchant_restock() -- re-run set_merchant on every Merchant still for
// sale on this level.
//
// What a Merchant advertises is "whatever ap_merchant_next() says is next",
// and that answer changes the moment ANY Merchant is bought from. set_merchant
// only ever ran at spawn time, so with two Merchants alive on one level the
// second one went on showing -- and, at the point of sale, announcing -- the
// item that belonged to the location the FIRST one had already taken. It still
// checked the correct location; only the name was a frame behind.
//
// Also called when scout results land, because a Merchant stocked before the
// server replied fell back to the placeholder "Unlock N".
//
// The Merchant just bought from is excluded by the "sold" test: activate_block
// sets that before this runs, which is exactly why the hook sits after it
// rather than inside ap_merchant_check.

if (!global.ap_enabled)
{
    exit;
}
var seen = 0;
var done = 0;
with (obDecor)
{
    if (sprite_index == sprNPC_Merchant)
    {
        seen += 1;
        if (longtext != "sold")
        {
            set_merchant(id);
            done += 1;
            ap_debug("  restocked a Merchant -> '" + string(longtext2) + "'");
        }
    }
}
ap_debug("restock: " + string(seen) + " Merchant(s) on this level, " +
         string(done) + " restocked");
