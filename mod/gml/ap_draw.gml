// On-screen Archipelago status + message feed.
//
// Appended to btnStartMenu's Draw (rmMenu, views disabled, so room coords ==
// screen coords) and to obGameControl's Draw GUI.
//
// Font note: this used to call draw_set_font(-1). That is not a valid font
// asset in GM:Studio and text drawn under it does not render, which is why
// the overlay was invisible even when ap_boot had run. Use one of the game's
// own fonts instead. A filled backing rectangle guarantees contrast against
// whatever art happens to be underneath.

if (!variable_global_exists("ap_booted"))
{
    exit;
}

var lines = 3;
if (global.ap_log_timer > 0 && global.ap_log_count > 0)
{
    lines += min(global.ap_log_count, 6);
}

draw_set_alpha(0.75);
draw_set_color(c_black);
draw_rectangle(4, 4, 640, 12 + (lines * 18), false);

draw_set_alpha(1);
draw_set_font(fnInterfaceMedium);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

// --- connection state ------------------------------------------------------
var label = "AP: off (no Slot in archipelago.ini)";
var col = c_gray;
if (global.ap_enabled)
{
    if (global.ap_state >= global.AP_STATE_SLOT_CONNECTED)
    {
        label = "AP: connected";
        col = c_lime;
    }
    else if (global.ap_state >= global.AP_STATE_SOCKET_CONNECTED)
    {
        label = "AP: handshaking";
        col = c_yellow;
    }
    else
    {
        label = "AP: connecting to " + global.ap_host;
        col = c_orange;
    }
}
draw_set_color(col);
draw_text(8, 8, label);

// --- where the mod is reading and writing its files -----------------------
// Printed unconditionally: if the save-location flag did not take effect at
// runtime, this is what tells us where archipelago.ini and ap_debug.log
// actually went.
draw_set_color(c_white);
draw_text(8, 26, "dir: " + global.ap_diag_dir);
draw_text(8, 44, "ini: " + global.ap_diag_ini);

// --- rolling event feed ----------------------------------------------------
if (global.ap_log_timer > 0 && global.ap_log_count > 0)
{
    global.ap_log_timer -= 1;
    var shown = min(global.ap_log_count, 6);
    for (var i = 0; i < shown; i += 1)
    {
        var slot = (global.ap_log_count - shown + i) mod 6;
        draw_text(8, 62 + (i * 18), global.ap_log_line[slot]);
    }
}

draw_set_color(c_white);
draw_set_alpha(1);
