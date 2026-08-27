// Draws the extra "End This Run Early" row on the pause menu's first page.
//
// Appended to obGameControl's Draw_64 rather than spliced into the vanilla
// page-1 block, for the same reason ap_menu_draw is appended to btnStartMenu's
// Draw: that block is a wall of five-language branches drawn twice (the second
// copy is the co-op variant), and threading a new row through it by
// find/replace would buy nothing. ap_pause_extra is false in co-op, so there
// is no risk of this drawing over the copy we are not part of.
//
// Vanilla's rows sit at y = 200, 300 and 400, selected in white/large and the
// rest in grey/medium, centred on x = 640 -- all matched here so the new row
// does not read as belonging to something else.

if (!global.PAUSED || global.gTutorial.visible)
{
    exit;
}
if (global.menu_page != 1 || !ap_pause_extra())
{
    exit;
}

if (global.menu_choice == 4)
{
    draw_set_color(c_white);
    draw_set_font(fnInterfaceLarge);
}
else
{
    draw_set_color(make_color_rgb(50, 50, 50));
    draw_set_font(fnInterfaceMedium);
}
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_text(640, 500, "End This Run Early");
draw_set_halign(fa_left);
draw_set_valign(fa_top);
