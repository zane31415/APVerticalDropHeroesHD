// ap_level_cleared(level) -- the hero took the portal out of `level`.
//
// Keyed to the portal rather than the Guardian's death because the portal
// tile can also be opened with 5 keys ("Defeat the <boss> OR Unlock with
// 5 Keys!"), and both routes should count as a clear.

if (!global.ap_enabled)
{
    exit;
}
var l = argument0;
if (l >= 1 && l < global.ap_final_level && global.ap_sent_clear[l] < 1)
{
    ap_check(global.ap_clear_loc[l]);
}
