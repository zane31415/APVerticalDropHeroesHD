// ap_shortcut_open(level) -- is this level's shortcut crystal still for sale?
//
// Vanilla decided this from global.skipLevel, which under AP only rises when
// the server sends a Progressive Shortcut. That left the crystal on offer
// after its location had been checked, letting the player pay repeatedly to
// re-check the same location. Track the check instead.

if (!global.ap_enabled)
{
    return 1;
}
var l = argument0;
if (l < 2 || l > global.ap_final_level)
{
    return 0;
}
return (global.ap_sent_short[l] < 1);
