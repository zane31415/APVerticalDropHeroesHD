// ap_mark_sent(location_id) -- record a location as checked, locally.
//
// Drives what the Merchant still has in stock. Fed both by our own checks and
// by the server's ap_location_checked event (which fires on connect with the
// whole existing set), so a reconnect restores the correct stock list.

var lid = argument0;

for (var g = 0; g < 3; g += 1)
{
    for (var i = 0; i < global.ap_skill_count[g]; i += 1)
    {
        if (global.ap_skill_loc[g, i] == lid)
        {
            global.ap_sent_skill[g, i] = 1;
            exit;
        }
    }
}

for (var s = 0; s < 3; s += 1)
{
    for (var t = 1; t <= global.ap_max_shop_tier; t += 1)
    {
        if (global.ap_shop_loc[s, t] == lid)
        {
            global.ap_sent_shop[s, t] = 1;
            exit;
        }
    }
}

for (var l = 2; l <= global.ap_final_level; l += 1)
{
    if (global.ap_short_loc[l] == lid)
    {
        global.ap_sent_short[l] = 1;
        exit;
    }
}

for (var l = 1; l < global.ap_final_level; l += 1)
{
    if (global.ap_clear_loc[l] == lid)
    {
        global.ap_sent_clear[l] = 1;
        exit;
    }
}

if (lid == global.ap_goal_loc)
{
    global.ap_sent_goal = 1;
}
