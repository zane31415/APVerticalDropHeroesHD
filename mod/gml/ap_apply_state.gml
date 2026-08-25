// Rebuilds all AP-controlled game state from the item tallies.
//
// This is a pure function of global.ap_recv_*: calling it twice changes
// nothing. Vanilla incremented dlevel/hlevel/plevel in place at the shop;
// under AP those counters become "1 + how many progressive items I hold".

// --- skill unlocks ---------------------------------------------------------
// Signature first. The hero-select screen bakes everything below into its
// three candidates at the moment it builds them, which under Archipelago is
// before the server has sent a single item -- so the tally changing is the one
// event that makes those candidates stale. Weighted per slot so that losing
// one skill and gaining another is not a wash. Shop levels are in it because
// generate_cbox reads dlevel/hlevel/plevel for the candidate's stats, so a
// batch of nothing but Progressive Damage still leaves the screen out of date.
var sig = 0;
for (var g = 0; g < 3; g += 1)
{
    for (var i = 0; i < global.ap_skill_count[g]; i += 1)
    {
        sig += (((g + 1) * 97) + i + 1) * global.ap_recv_skill[g, i];
    }
}
sig += 1000003 * global.ap_recv_shop[0];
sig += 1000033 * global.ap_recv_shop[1];
sig += 1000037 * global.ap_recv_shop[2];

for (var i = 0; i < global.ap_skill_count[0]; i += 1)
{
    global.tr_unlock[i] = global.ap_recv_skill[0, i];
}
for (var i = 0; i < global.ap_skill_count[1]; i += 1)
{
    global.p1_unlock[i] = global.ap_recv_skill[1, i];
}
for (var i = 0; i < global.ap_skill_count[2]; i += 1)
{
    global.p2_unlock[i] = global.ap_recv_skill[2, i];
}

// --- between-run shop levels ----------------------------------------------
global.dlevel = 1 + global.ap_recv_shop[0];
global.hlevel = 1 + global.ap_recv_shop[1];
global.plevel = 1 + global.ap_recv_shop[2];

// --- level access ----------------------------------------------------------
// Deepest level the hero is allowed to set foot in. With level locks off this
// is simply everything, so ap_level_open() stops asking.
global.ap_level_max = min(1 + global.ap_recv_level, global.ap_final_level);
if (!global.ap_level_locks)
{
    global.ap_level_max = global.ap_final_level;
}

// --- shortcuts -------------------------------------------------------------
// skipLevel is "deepest level reachable from the menu"; vanilla starts at 1.
//
// Capped by level access as well, because the village's Teleportation Shrine
// moves the hero a level deeper WITHOUT going through a portal -- so the
// portal gate in obGameControl's Step cannot see it. Capping skipLevel is the
// one place that closes that route, and it costs no extra hook: a shortcut you
// hold but have no access for simply waits until the access arrives.
if (global.ap_shortcuts_on)
{
    global.skipLevel = min(1 + global.ap_recv_short, global.ap_level_max);
    global.skipLevel = min(global.skipLevel, global.ap_final_level);
}
else if (global.ap_level_locks)
{
    // Shortcuts are the game's own again, but the shrine bypass still has to
    // respect level access, so the cap stays even though the floor does not.
    global.skipLevel = min(global.skipLevel, global.ap_level_max);
}

// global.startLevel is created in obGameControl's Create, so it does not exist
// while we are still on the main menu -- and items DO arrive there now that we
// connect from btnStartMenu. Reading it unguarded was a hard crash. Nothing is
// lost by skipping the clamp: obGameControl's Create assigns startLevel = 1
// before any of it matters.
if (variable_global_exists("startLevel") && global.startLevel > global.skipLevel)
{
    global.startLevel = global.skipLevel;
}

// --- catch up the hero-select screen --------------------------------------
// Last, so the reroll sees the derived dlevel/hlevel/plevel above and not the
// tallies they came from. The signature keeps this to the frames where the
// tally genuinely moved: this script runs on every ReceivedItems batch, and
// rerolling under the player on a batch that changed nothing would be its own
// bug. Shortcut and level-access items are deliberately not in it -- neither
// touches what a candidate hero looks like.
if (sig != global.ap_skill_sig)
{
    global.ap_skill_sig = sig;
    ap_reroll_select();
}
