// REPLACES gml_Script_new_unlock.
//
// Vanilla set global.<arr>_unlock[i] = 1 for the named skill. Under
// Archipelago the purchase checks a location instead, and the skill itself
// only becomes usable when the matching item comes back from the server (see
// ap_apply_state). Which skill the Merchant was nominally showing is now
// irrelevant -- the location is the purchase, not the skill -- so the argument
// is only consulted on the offline path.

if (global.ap_enabled)
{
    ap_merchant_check();
    exit;
}

var skill = argument0;
for (var n = 0; n < global.ap_sk_total; n += 1)
{
    if (global.ap_sk_name[n] == skill)
    {
        var g = global.ap_sk_group[n];
        var i = global.ap_sk_index[n];
        if (g == 0)
        {
            global.tr_unlock[i] = 1;
        }
        else if (g == 1)
        {
            global.p1_unlock[i] = 1;
        }
        else
        {
            global.p2_unlock[i] = 1;
        }
        exit;
    }
}
