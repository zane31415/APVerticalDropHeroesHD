// ap_effect(kind, name, is_trap) -- a filler or trap item arrived.
//
// Only ever called for items the server has not handed us before (see the
// high-water mark in ap_progress_load). Archipelago replays the whole item
// list on every connect, and unlike a shop tier a Coin Cache cannot be
// recomputed from a tally -- it already happened. Without the high-water mark
// every reconnect would re-pay every coin and re-fire every trap.
//
// Coins are the only effect that works anywhere: global.coins persists across
// runs and exists at the main menu. Everything else needs a hero standing in a
// level, so it goes on a queue that ap_consume drains on the first frame that
// has one.

var kind = argument0;
var nm = argument1;
var is_trap = argument2;

if (kind == "coins")
{
    var gain = 25 * max(1, global.enemyLevel);
    global.coins += gain;
    ap_log(nm + ": +" + string(gain) + " coins");
    exit;
}

if (kind == "shrine")
{
    global.ap_pend_shrine += 1;
}
else if (kind == "mana")
{
    global.ap_pend_mana += 1;
}
else if (kind == "key")
{
    global.ap_pend_key += 1;
}
else if (kind == "alarm")
{
    global.ap_pend_alarm += 1;
}
else
{
    ap_debug("unknown filler effect '" + kind + "' (" + nm + ") -- ignored");
    exit;
}

// Traps announce themselves twice -- once on arrival and once when they
// actually fire -- because the gap between the two can be minutes if the item
// landed while you were at the menu.
if (is_trap)
{
    ap_log("Trap incoming: " + nm);
}
else
{
    ap_log(nm);
}
