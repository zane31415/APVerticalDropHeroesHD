// ap_purse_check() -- coins and keys belong to the slot that earned them.
//
// Everything else the mod carries across a connect is either derived from the
// server (unlocks, shop levels, the checked set) or explicitly zeroed by
// ap_connect_now, so a new slot starts clean. global.coins and global.keys are
// neither: they are vanilla save state, written to vdh_save by save_game and
// reloaded on the next launch, and nothing in the item stream can recompute
// them. So a player who finished one multiworld and connected to the next
// arrived in it with the previous world's whole purse -- enough to buy out
// several Merchants' worth of locations before earning a single coin.
//
// They cannot simply be zeroed on every connect either: coins are meant to
// survive between runs on one slot, and a mid-session reconnect (or the
// automatic connect at the start of every run) is not a new game.
//
// So the wipe is keyed on identity, not on the act of connecting. The mark is
// global.ap_progress_key -- seed + slot name, the same key the filler
// high-water mark uses -- remembered in archipelago.ini under [Progress]. Same
// key as last time: this is the same game, keep the purse. Different: this is
// a different fill, or a different slot in it, so the purse starts at zero.
// Being stored in the ini rather than in memory is what makes a close-and-
// reopen on one slot keep its coins.
//
// Called from ap_dispatch right after ap_progress_load, which is where the key
// is built: the seed only exists once the server has sent RoomInfo, so this is
// the earliest moment the question can be answered at all. On the connect that
// a run start triggers, that lands a few frames into level 1 -- early enough
// that nothing has been spent, late enough that the drop is visible on the HUD
// if the player is looking.

if (global.ap_progress_key == "")
{
    // No seed, so no way to tell this game from the last one. Keeping the
    // coins is the conservative failure: a wipe that should not have happened
    // destroys progress that nothing can restore.
    ap_debug("no progress key; leaving coins and keys alone");
    exit;
}

ini_open("archipelago.ini");
var last = ini_read_string("Progress", "Purse", "");
ini_write_string("Progress", "Purse", global.ap_progress_key);
ini_close();

if (last == global.ap_progress_key)
{
    ap_debug("purse kept for '" + global.ap_progress_key + "': " +
             string(global.coins) + " coins, " + string(global.keys) + " keys");
    exit;
}

ap_debug("new slot ('" + string(last) + "' -> '" + global.ap_progress_key +
         "'): wiping " + string(global.coins) + " coins and " +
         string(global.keys) + " keys");
global.coins = 0;
global.keys = 0;

// Persist immediately rather than waiting for whatever the player does next to
// save: a wipe that only lives in memory comes back on the next launch, and
// the ini already says this slot has been seen.
save_game("save");
