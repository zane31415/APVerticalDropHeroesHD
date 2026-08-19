// On-screen Archipelago status + message feed.
// Appended to obGameControl's Draw GUI event.

if (!variable_global_exists("ap_booted"))
{
    exit;
}

draw_set_font(-1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_alpha(1);

// --- connection state pip --------------------------------------------------
var label = "AP: off";
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
        label = "AP: connecting";
        col = c_orange;
    }
}
draw_set_color(col);
draw_text(8, 8, label);

// --- transient boot/config message ----------------------------------------
if (global.ap_msg_timer > 0 && global.ap_msg != "")
{
    draw_set_color(c_white);
    draw_text_ext(8, 26, global.ap_msg, 16, 600);
}

// --- rolling event feed ----------------------------------------------------
if (global.ap_log_timer > 0 && global.ap_log_count > 0)
{
    global.ap_log_timer -= 1;
    draw_set_color(c_white);
    var shown = min(global.ap_log_count, 6);
    for (var i = 0; i < shown; i += 1)
    {
        // oldest first, newest at the bottom
        var slot = (global.ap_log_count - shown + i) mod 6;
        draw_text(8, 80 + (i * 16), global.ap_log_line[slot]);
    }
}

draw_set_color(c_white);
