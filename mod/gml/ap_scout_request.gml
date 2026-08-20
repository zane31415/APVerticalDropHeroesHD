// Ask the server what is sitting on every one of our locations, so the shop
// and Merchant UI can name what you are about to buy.
//
// create_as_hint = 0: this is a silent lookup for our own UI, not a hint the
// player spent points on, so it must not be broadcast.
//
// Arrays go to the DLL as a JSON string (see "API Limitations" in the
// gm-apclientpp README).

var ids = "[";
for (var i = 0; i < global.ap_loc_count; i += 1)
{
    if (i > 0)
    {
        ids += ",";
    }
    ids += string(global.ap_base_id + i);
}
ids += "]";

external_call(global.ext_ap_location_scouts, ids, 0);
global.ap_scout_sent = 1;
ap_debug("scout requested for " + string(global.ap_loc_count) + " locations");
