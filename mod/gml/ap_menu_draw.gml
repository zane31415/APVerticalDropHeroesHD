// Draws the extra "Archipelago" entry on the Options page, and the whole
// Archipelago page itself.
//
// Appended to btnStartMenu's Draw rather than spliced into it: the vanilla
// page-2 block is a wall of five-language branches, and adding an entry by
// find/replace would have meant matching accented strings through the .csx
// encoding for no benefit.

if (!variable_global_exists("ap_menu_slot"))
{
    exit;
}

// --- extra entry on the Options page --------------------------------------
if (global.menu_page == 2)
{
    if (global.menu_choice == global.ap_menu_slot)
    {
        draw_set_color(c_white);
        draw_set_font(fnInterfaceMedium);
    }
    else
    {
        draw_set_color(make_color_rgb(50, 50, 50));
        draw_set_font(fnInterfaceSmall);
    }
    // Vanilla draws every Options row centred on x=1130; matching it keeps the
    // new row from looking right-aligned next to the others.
    draw_set_halign(fa_center);
    draw_text(1130, 505, "Archipelago");
    draw_set_halign(fa_left);
    exit;
}

if (global.menu_page != 6)
{
    exit;
}

// --- the Archipelago page --------------------------------------------------
draw_set_halign(fa_left);
draw_set_valign(fa_top);

draw_set_alpha(0.82);
draw_set_color(c_black);
draw_rectangle(90, 120, 900, 470, false);
draw_set_alpha(1);

draw_set_font(fnInterfaceLarge);
draw_set_color(c_white);
draw_text(110, 135, "Archipelago");

draw_set_font(fnInterfaceSmall);
draw_set_color(make_color_rgb(150, 150, 150));
draw_text(110, 180, "Up/Down to move, Enter to edit or activate, Ctrl+V to paste, Esc to go back.");

var labels;
labels[1] = "Server";
labels[2] = "Slot";
labels[3] = "Password";

var yy = 215;
for (var i = 1; i <= 3; i += 1)
{
    var val = ap_menu_field(i);
    if (i == 3 && string_length(val) > 0 && global.ap_menu_edit != 3)
    {
        // Do not leave a password sitting on screen.
        var stars = "";
        for (var k = 0; k < string_length(val); k += 1)
        {
            stars += "*";
        }
        val = stars;
    }
    if (val == "")
    {
        val = "(empty)";
    }

    if (global.ap_menu_edit == i)
    {
        draw_set_color(c_yellow);
        draw_set_font(fnInterfaceMedium);
        val += "_";
    }
    else if (global.menu_choice == i)
    {
        draw_set_color(c_white);
        draw_set_font(fnInterfaceMedium);
    }
    else
    {
        draw_set_color(make_color_rgb(120, 120, 120));
        draw_set_font(fnInterfaceSmall);
    }
    draw_text(110, yy, labels[i] + ":");
    draw_text(280, yy, val);
    yy += 34;
}

// --- actions ---------------------------------------------------------------
ap_menu_style(4);
draw_text(110, 330, "Connect");
ap_menu_style(5);
draw_text(110, 364, "Back");

// --- live status -----------------------------------------------------------
draw_set_font(fnInterfaceSmall);
var st = "not connected";
var stc = make_color_rgb(170, 170, 170);
if (global.ap_enabled)
{
    if (global.ap_state >= global.AP_STATE_SLOT_CONNECTED)
    {
        st = "connected";
        stc = c_lime;
    }
    else if (global.ap_state >= global.AP_STATE_SOCKET_CONNECTED)
    {
        st = "handshaking...";
        stc = c_yellow;
    }
    else
    {
        st = "connecting...";
        stc = c_orange;
    }
}
draw_set_color(stc);
draw_text(110, 408, "Status: " + st);

if (global.ap_log_count > 0)
{
    draw_set_color(make_color_rgb(150, 150, 150));
    draw_text(110, 432, global.ap_log_line[(global.ap_log_count - 1) mod 6]);
}

// --- where the mod lives ---------------------------------------------------
// This is the diagnostics page, so the working directory belongs here rather
// than on the gameplay HUD: it is the folder ap_debug.log and archipelago.ini
// are actually written to, which is not always the folder the exe sits in --
// under Program Files, Windows silently redirects both into
// %LOCALAPPDATA%\VirtualStore. Asking someone for a log they cannot find is
// how an evening goes missing.
draw_set_color(make_color_rgb(130, 130, 130));
draw_text(110, 470, "build " + global.ap_build);
draw_text(110, 492, "files: " + global.ap_diag_dir);

draw_set_color(c_white);
draw_set_alpha(1);
