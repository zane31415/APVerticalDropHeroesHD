// Ask the server what is sitting on every one of our locations, so the shop
// and Merchant UI can name what you are about to buy.
//
// ONLY the locations this slot actually has. The id tables describe the
// maximum -- 30 shop tiers, 10 shrines a level, shortcuts and clears whether
// or not they were asked for -- and the slot plays a subset of that. Scouting
// an id the slot does not have is not ignored by the server, it is fatal:
//
//     KeyError: 'No location 8830165 for player 3'
//     ctx.locations[client.slot][location]
//
// which kills the whole MultiServer command handler, for every player in the
// room. So this walks the same tables the rest of the mod does and applies the
// same bounds, which are exactly the apworld's `locations_for()` filter:
//
//     unlock    always
//     shop      tier <= shop_upgrade_tiers
//     shortcut  include_shortcuts
//     clear     include_level_clears
//     shrine    slot <= shrine_checks
//     goal      always
//
// create_as_hint = 0: this is a silent lookup for our own UI, not a hint the
// player spent points on, so it must not be broadcast.
//
// Arrays go to the DLL as a JSON string (see "API Limitations" in the
// gm-apclientpp README).

var ids = "[";
var n = 0;

for (var i = 1; i <= global.ap_unlock_total; i += 1)
{
    if (n > 0) { ids += ","; }
    ids += string(global.ap_unlock_loc[i]);
    n += 1;
}

for (var s = 0; s < 3; s += 1)
{
    for (var t = 1; t <= global.ap_shop_tiers; t += 1)
    {
        if (n > 0) { ids += ","; }
        ids += string(global.ap_shop_loc[s, t]);
        n += 1;
    }
}

if (global.ap_shortcuts_on)
{
    for (var l = 2; l <= global.ap_final_level; l += 1)
    {
        if (n > 0) { ids += ","; }
        ids += string(global.ap_short_loc[l]);
        n += 1;
    }
}

if (global.ap_clears_on)
{
    for (var l = 1; l < global.ap_final_level; l += 1)
    {
        if (n > 0) { ids += ","; }
        ids += string(global.ap_clear_loc[l]);
        n += 1;
    }
}

for (var l = 1; l < global.ap_final_level; l += 1)
{
    for (var k = 1; k <= global.ap_shrine_checks; k += 1)
    {
        if (n > 0) { ids += ","; }
        ids += string(global.ap_shrine_loc[l, k]);
        n += 1;
    }
}

if (n > 0) { ids += ","; }
ids += string(global.ap_goal_loc);
n += 1;

ids += "]";

external_call(global.ext_ap_location_scouts, ids, 0);
global.ap_scout_sent = 1;
ap_debug("scout requested for " + string(n) + " of " +
         string(global.ap_loc_count) + " table locations");
