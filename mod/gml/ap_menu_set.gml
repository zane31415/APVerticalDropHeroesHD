// ap_menu_set(n, text) -- write a field back, stripped of anything the ini
// round-trip or the connect call cannot survive.

var v = argument1;
// keyboard_string can pick up the Enter that confirmed the edit.
var clean = "";
for (var i = 1; i <= string_length(v); i += 1)
{
    var ch = string_char_at(v, i);
    if (ch != chr(13) && ch != chr(10) && ch != chr(9))
    {
        clean += ch;
    }
}
if (string_length(clean) > 128)
{
    clean = string_copy(clean, 1, 128);
}

if (argument0 == 1)
{
    global.ap_host = clean;
}
else if (argument0 == 2)
{
    global.ap_slot = clean;
}
else
{
    global.ap_password = clean;
}
