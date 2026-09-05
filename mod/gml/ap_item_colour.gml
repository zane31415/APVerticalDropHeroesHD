// ap_item_colour(flags) -- what colour to draw an item name in, from the
// classification bitmask ap_scout_flags() returns.
//
//     red     trap
//     yellow  progression
//     blue    useful
//     white   filler, and anything we cannot name yet
//
// argument0 < 0 means "this line is not an item at all" -- "sold out",
// "(not scouted yet)" -- and gets the plain colour the rest of the info bar
// uses. Flags can carry more than one bit; the order below is the priority,
// with trap first because that is the one worth interrupting for.
//
// make_color_rgb rather than the c_* constants, which are compile-time names
// this patch has no reason to trust the compiler to resolve. The blue is
// lightened well past c_blue: the info bar draws its text white on a dark
// panel (draw_fchv(2, 16777215, ...) in obInfoBar's Draw), and pure blue is
// barely legible there.

var flags = argument0;

if (flags < 0)
{
    return make_color_rgb(255, 255, 255);
}
if ((flags & 4) != 0)
{
    return make_color_rgb(235, 85, 85);
}
if ((flags & 1) != 0)
{
    return make_color_rgb(245, 205, 65);
}
if ((flags & 2) != 0)
{
    return make_color_rgb(110, 170, 255);
}
return make_color_rgb(255, 255, 255);
