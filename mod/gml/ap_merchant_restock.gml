// ap_merchant_restock() -- re-run set_merchant on every Merchant still for
// sale on this level.
//
// What a Merchant advertises is "whatever ap_merchant_next() says is next",
// and that answer changes the moment ANY Merchant is bought from. set_merchant
// only ever ran at spawn time, so a Merchant that has been standing there
// since before the last sale is showing a location somebody else has taken.
//
// Also called when scout results land, because a Merchant stocked before the
// server replied fell back to the placeholder "Unlock N".
//
// What this does NOT fix is the sale itself. It can only reach Merchants that
// exist as instances right now, and place_tiles builds a level's rows as the
// player descends, so the Merchant further down usually does not exist yet
// when the one above it is sold -- which is why every live log shows
// "restock: 1 Merchant(s)", the one just bought from. The name announced by a
// purchase is therefore derived at the point of sale instead; see
// ap_merchant_label.
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
