// ap_reroll_select() -- rebuild the three hero-select candidates.
//
// generate_cbox bakes the current unlock set and shop levels into a candidate
// at the moment it is built, and obGameControl's Create builds all three
// before Archipelago has replied to the connect. Pressing Single Player from
// the main menu therefore produced three traitless, unupgraded heroes, and the
// only way to get a proper one was to quit back out and start again once the
// items had landed.
//
// So when the unlock set actually changes (ap_apply_state watches for that)
// and we are still sitting on the select screen, throw the candidates away and
// roll them again. Free: the vanilla reroll costs 5 coins because it is the
// player choosing to gamble, and this is the mod catching up with itself.
//
// Nothing to do once a hero is picked -- that hero already exists and
// ap_apply_state has applied the items to it directly.

if (!global.ap_enabled)
{
    exit;
}
if (!variable_global_exists("selectScreen") || !global.selectScreen)
{
    exit;
}
if (!variable_global_exists("heroPicked") || global.heroPicked)
{
    exit;
}
if (!variable_global_exists("hero_list"))
{
    exit;
}

// hero_list is global and outlives the room it was built for, so every entry
// is checked rather than trusting the count. Co-op fills six; it never
// connects, but the loop costs nothing.
var boxes = 3;
if (global.COOP)
{
    boxes = 6;
}
for (var i = 0; i < boxes; i += 1)
{
    var box = global.hero_list[i];
    if (instance_exists(box))
    {
        clear_cbox(box);
        generate_cbox(box);
    }
}
ap_debug("select screen rerolled: unlock set changed while choosing a hero");
