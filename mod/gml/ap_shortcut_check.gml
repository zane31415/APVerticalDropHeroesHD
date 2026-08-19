// ap_shortcut_check(level) -- the player bought the shortcut at `level`.

if (!global.ap_enabled)
{
    exit;
}
var l = argument0;
if (l >= 2 && l <= global.ap_final_level && global.ap_sent_short[l] < 1)
{
    ap_check(global.ap_short_loc[l]);
}
