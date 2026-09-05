// ap_desc_draw(x, y, desc, target) -- REPLACES obInfoBar's single
// draw_text_ext of the description, so the Archipelago item name underneath
// it can be drawn in the colour of what it is.
//
// One draw call cannot carry two colours, which is the whole reason this
// script exists: ap_desc_suffix used to hand back "description##AP: item" as
// one string. It now returns the description alone and publishes the AP line
// separately, and the two are drawn one after the other here.
//
// The offset reproduces exactly what the single string used to render. Every
// AP line was joined on with "##" -- a blank line -- so it sat one line below
// the description's own last line, and string_height_ext measures the
// description at the same separation and wrap width the draw uses.

var dx = argument0;
var dy = argument1;

var body = ap_desc_suffix(argument2, argument3);
draw_text_ext(dx, dy, body, 20, 450);

if (global.ap_desc_line == "")
{
    exit;
}

var prev = draw_get_color();
draw_set_color(ap_item_colour(global.ap_desc_flags));
draw_text_ext(dx, dy + string_height_ext(body, 20, 450) + 20,
              global.ap_desc_line, 20, 450);
// obInfoBar goes on to draw other things in whatever colour it left set; this
// one is ours and must not leak out of it.
draw_set_color(prev);
