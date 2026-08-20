// ap_menu_field(n) -- current text of Archipelago menu field n.
// 1 = Host, 2 = Slot, 3 = Password.

if (argument0 == 1)
{
    return global.ap_host;
}
if (argument0 == 2)
{
    return global.ap_slot;
}
return global.ap_password;
