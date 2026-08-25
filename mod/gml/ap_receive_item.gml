// ap_receive_item(item_id, is_new) -- tally one received item.
//
// Tallies only, for everything that can be tallied; all such game state is
// derived in ap_apply_state(). That split is what makes reconnects safe: the
// server replays every item it ever gave us, and replaying into a tally is
// idempotent where replaying into "hpmax += 7" would not be.
//
// Filler and traps are the exception -- there is no tally that can recompute
// a Coin Cache already spent or a trap already sprung -- so they are gated on
// `is_new`, which the caller derives from the persisted high-water mark.

var iid = argument0;
var is_new = argument1;

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

if (iid == global.ap_level_item)
{
    global.ap_recv_level += 1;
    exit;
}

// filler and traps
for (var f = 0; f < global.ap_fx_count; f += 1)
{
    if (global.ap_fx_item[f] == iid)
    {
        if (is_new)
        {
            ap_effect(global.ap_fx_kind[f], global.ap_fx_name[f],
                      global.ap_fx_trap[f]);
        }
        exit;
    }
}
