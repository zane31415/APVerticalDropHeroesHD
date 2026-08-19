// Rebuilds all AP-controlled game state from the item tallies.
//
// This is a pure function of global.ap_recv_*: calling it twice changes
// nothing. Vanilla incremented dlevel/hlevel/plevel in place at the shop;
// under AP those counters become "1 + how many progressive items I hold".

// --- skill unlocks ---------------------------------------------------------
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

// --- shortcuts -------------------------------------------------------------
// skipLevel is "deepest level reachable from the menu"; vanilla starts at 1.
global.skipLevel = min(1 + global.ap_recv_short, global.ap_final_level);
if (global.startLevel > global.skipLevel)
{
    global.startLevel = global.skipLevel;
}
