// Load this seed+slot's "how many items have I already consumed" mark.
//
// Everything else the mod tracks is derived from a tally and is therefore
// immune to Archipelago replaying the whole item list on connect. Filler and
// traps are not: a Coin Cache has *happened*, and there is no tally that can
// recompute it. Without a persisted mark, every reconnect would re-pay every
// coin and re-fire every trap in the run's history.
//
// Keyed by seed as well as slot so that starting a new multiworld with the
// same slot name does not inherit the old one's mark. Lives in the [Progress]
// section of archipelago.ini, which ini_open reads whole and rewrites whole,
// so it coexists with the connection settings the Options menu writes.

global.ap_item_hwm = 0;
global.ap_progress_key = "";

var seed = external_call(global.ext_ap_get_seed);
if (seed == "")
{
    // No seed means no safe key. Consuming nothing is the conservative
    // failure: a missed Coin Cache is a nuisance, a repeated trap is a bug.
    global.ap_item_hwm = 999999;
    ap_debug("no seed available; filler consumption disabled this session");
    exit;
}

global.ap_progress_key = seed + "|" + global.ap_slot;
ini_open("archipelago.ini");
global.ap_item_hwm = ini_read_real("Progress", global.ap_progress_key, 0);
ini_close();
ap_debug("progress mark for '" + global.ap_progress_key + "' = " +
         string(global.ap_item_hwm));
