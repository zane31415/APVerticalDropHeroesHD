// ap_shortcut_check(level) -- the player bought the shortcut at `level`.

if (!global.ap_enabled)
{
    exit;
}

// With shortcuts left out of the multiworld the crystal is not a location, so
// it has to go back to being a crystal. The patch suppressed the two vanilla
// lines at the call site (they sit behind `if (!global.ap_enabled)`), so this
// is where they have to come back -- otherwise lighting a crystal would take
// the coins and do nothing at all.
if (!global.ap_shortcuts_on)
{
    global.skipLevel = argument0;
    global.startLevel = argument0 + 1;
    exit;
}

var l = argument0;
if (l >= 2 && l <= global.ap_final_level && global.ap_sent_short[l] < 1)
{
    ap_check(global.ap_short_loc[l]);
}
