// Clears every local "this location is already checked" flag.
//
// The sent-state mirror must be rebuilt from the server on every connect, for
// the same reason the received-item tallies are (see ap_reset_tallies): it is
// slot-specific. Carrying it across a reconnect meant slot A's checked set
// silently applied to slot B -- buy from the Apothecary on a fresh seed and
// the mod would skip straight to Upgrade 3 because the previous slot had
// already checked 1 and 2.
//
// Safe to clear unconditionally: apclientpp replays the whole checked set
// through ap_location_checked immediately after ap_slot_connected, and only
// omits it when the set is genuinely empty -- which is exactly the case where
// zeroed state is correct.

for (var i = 1; i <= global.ap_unlock_total; i += 1)
{
    global.ap_sent_unlock[i] = 0;
}
for (var s = 0; s < 3; s += 1)
{
    for (var t = 0; t <= global.ap_max_shop_tier; t += 1)
    {
        global.ap_sent_shop[s, t] = 0;
    }
}
for (var l = 0; l <= global.ap_final_level; l += 1)
{
    global.ap_sent_short[l] = 0;
    global.ap_sent_clear[l] = 0;
    for (var n = 0; n <= global.ap_max_shrines; n += 1)
    {
        global.ap_sent_shrine[l, n] = 0;
    }
}
global.ap_sent_goal = 0;
for (var g = 0; g < 3; g += 1)
{
    for (var i = 0; i < global.ap_skill_count[g]; i += 1)
    {
        global.ap_sent_skill[g, i] = 0;
    }
}
global.ap_goaled = 0;

// Scouted names belong to the old slot's fill too.
for (var i = 0; i < global.ap_loc_count; i += 1)
{
    global.ap_scout[i] = "";
}

ap_refresh_counters();
