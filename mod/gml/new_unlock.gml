// REPLACES gml_Script_new_unlock.
//
// Vanilla set global.<arr>_unlock[i] = 1 directly. Under Archipelago, buying
// a skill from the Merchant checks its *location*; the skill itself only
// becomes usable when the matching item comes back from the server (see
// ap_apply_state). With AP disabled this falls back to vanilla behaviour so
// the data.win is still playable offline.

var skill = argument0;

for (var n = 0; n < global.ap_sk_total; n += 1)
{
    if (global.ap_sk_name[n] == skill)
    {
        var g = global.ap_sk_group[n];
        var i = global.ap_sk_index[n];

        if (global.ap_enabled)
        {
            global.ap_sent_skill[g, i] = 1;
            ap_check(global.ap_skill_loc[g, i]);
        }
        else
        {
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
        }
        exit;
    }
}
