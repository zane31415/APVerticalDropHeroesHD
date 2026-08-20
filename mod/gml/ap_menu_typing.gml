// Text entry for one field. GM:Studio's keyboard_string already accumulates
// typed characters and handles backspace, so we mirror it into the field each
// frame rather than decoding keys ourselves.

if (keyboard_check_pressed(vk_escape))
{
    global.ap_menu_edit = 0;
    keyboard_string = "";
    exit;
}

// Ctrl+V: connect strings are long and nobody wants to type one by hand.
if (keyboard_check(vk_control) && keyboard_check_pressed(ord("V")))
{
    if (clipboard_has_text())
    {
        keyboard_string = clipboard_get_text();
    }
}

if (keyboard_check_pressed(vk_enter))
{
    ap_menu_set(global.ap_menu_edit, keyboard_string);
    global.ap_menu_edit = 0;
    keyboard_string = "";
    ap_menu_save();
    exit;
}

ap_menu_set(global.ap_menu_edit, keyboard_string);
