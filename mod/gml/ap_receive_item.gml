// ap_receive_item(item_id) -- tally one received item.
//
// Only tallies; all game state is derived in ap_apply_state(). Keeping this
// split is what makes reconnects safe: the server replays every item it ever
// gave us, and replaying into a tally is idempotent where replaying into
// "hpmax += 7" would not be.

var iid = argument0;

// skills
for (var g = 0; g < 3; g += 1)
{
    for (var i = 0; i < global.ap_skill_count[g]; i += 1)
    {
        if (global.ap_skill_item[g, i] == iid)
        {
            global.ap_recv_skill[g, i] = 1;
            exit;
        }
    }
}

// progressive shop upgrades
for (var s = 0; s < 3; s += 1)
{
    if (global.ap_shop_item[s] == iid)
    {
        global.ap_recv_shop[s] += 1;
        exit;
    }
}

if (iid == global.ap_short_item)
{
    global.ap_recv_short += 1;
    exit;
}

if (iid == global.ap_filler_item)
{
    global.coins += (25 * max(1, global.enemyLevel));
    exit;
}

if (iid == global.ap_trap_item)
{
    global.ap_pending_trap = 1;
    exit;
}
