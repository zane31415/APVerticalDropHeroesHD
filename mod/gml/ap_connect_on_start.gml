// Connect when a run is actually starting, if the menu has not already done it.
//
// Deliberately NOT called from ap_boot. Connecting at boot meant the server's
// checked-location set landed on top of whatever the player was already doing,
// and ap_apply_state overwrote in-progress unlocks and shop levels. Connecting
// at the point a run begins (or when the player explicitly hits Connect) keeps
// that from happening behind their back.

if (global.ap_enabled)
{
    exit;   // menu already connected us
}
if (global.ap_slot == "")
{
    exit;   // not configured; stay dormant and play vanilla
}
ap_connect_now();
