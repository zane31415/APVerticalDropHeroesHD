// ap_menu_style(choice) -- highlight styling for a menu row.

if (global.menu_choice == argument0)
{
    draw_set_color(c_white);
    draw_set_font(fnInterfaceMedium);
}
else
{
    draw_set_color(make_color_rgb(120, 120, 120));
    draw_set_font(fnInterfaceSmall);
}
