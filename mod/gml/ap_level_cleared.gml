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

// Before the clears_on test, not after: the depth high-water mark is what
// sizes a Coin Cache and it has to be right whether or not this slot turned
// the level-clear locations on.
ap_reach(l);

if (!global.ap_clears_on)
{
    exit;
}
if (l >= 1 && l < global.ap_final_level && global.ap_sent_clear[l] < 1)
{
    ap_check(global.ap_clear_loc[l]);
}
