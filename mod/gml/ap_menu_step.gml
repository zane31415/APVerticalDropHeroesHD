// Input handling for the Archipelago options page.
//
// Returns 1 when it has consumed this frame's input, in which case the
// prepended hook in btnStartMenu's Step exits before the vanilla menu code
// runs. That is the only way to stop the stock menu also reacting to the same
// keypress -- `exit` inside a script would only leave the script.
//
// Page 6 is ours; on page 2 we only claim the extra "Archipelago" entry.

var kEnter = keyboard_check_pressed(vk_space) || keyboard_check_pressed(vk_enter);
var kEsc = keyboard_check_pressed(vk_escape);
var kUp = keyboard_check_pressed(vk_up);
var kDn = keyboard_check_pressed(vk_down);

if (global.menu_page == 2)
{
    if (global.menu_choice == global.ap_menu_slot && kEnter)
    {
        global.menu_page = 6;
        global.menu_choice = 1;
        return 1;
    }
    return 0;
}

if (global.menu_page != 6)
{
    return 0;
}

if (kUp)
{
    global.menu_choice -= 1;
    if (global.menu_choice < 1)
    {
        global.menu_choice = 5;
    }
}
if (kDn)
{
    global.menu_choice += 1;
    if (global.menu_choice > 5)
    {
        global.menu_choice = 1;
    }
}

if (kEsc)
{
    ap_menu_save();
    global.menu_page = 2;
    global.menu_choice = global.ap_menu_slot;
    return 1;
}

if (kEnter)
{
    if (global.menu_choice <= 3)
    {
        global.ap_menu_edit = global.menu_choice;
        keyboard_string = ap_menu_field(global.menu_choice);
    }
    else if (global.menu_choice == 4)
    {
        ap_menu_save();
        ap_connect_now();
    }
    else
    {
        ap_menu_save();
        global.menu_page = 2;
        global.menu_choice = global.ap_menu_slot;
    }
}
return 1;
