// (Re)connect using whatever is currently in the Host/Slot/Password fields.
//
// Split out of ap_boot so the Options menu can connect on demand. The DLL is
// bound lazily and only once: external_define on an already-defined function
// is wasteful, and a game that never configures a slot should never load the
// DLL at all.

if (global.ap_slot == "")
{
    global.ap_msg = "Archipelago: enter a Slot name first";
    global.ap_msg_timer = 300;
    exit;
}
if (global.ap_host == "")
{
    global.ap_host = "localhost:38281";
}

if (!global.ap_dll_bound)
{
    ap_debug("binding DLL...");
    ap_dll();
    global.ap_dll_bound = 1;

    // api_version 1: GM7/8 string syntax. We never use the execute_string
    // path (GM:Studio removed it), so the GMS2 "+200" variant buys nothing.
    if (!external_call(global.ext_ap_init, 1))
    {
        global.ap_msg = "Archipelago: apclient_init failed";
        global.ap_msg_timer = 600;
        ap_debug("apclient_init FAILED");
        exit;
    }
    external_call(global.ext_ap_set_version, 0, 6, 1);
    // items_handling 7 = own world + other worlds + starting inventory.
    external_call(global.ext_ap_set_items, 7);
}
else
{
    // Reconnecting, possibly to a different slot: drop the old socket first.
    external_call(global.ext_ap_disconnect);
}

// EVERY connect, first or not, starts from a blank slate.
//
// This used to sit in the else branch, so a first connect skipped it -- and
// save_game("load") on btnStartMenu Create had already restored the PREVIOUS
// run's dlevel/hlevel/plevel from the ini. Pressing Single Player then built
// the first hero of the run with stale upgrades before any item arrived.
// Zeroing here happens synchronously, before room_goto, so the hero is built
// from baseline and the server's items raise it from there.
global.ap_ready = 0;
global.ap_status_sent = 0;
global.ap_scout_sent = 0;
ap_reset_tallies();
ap_reset_sent();
ap_apply_state();

// Partial payments toward a shortcut crystal persist in the save, and under AP
// the crystal is a location check -- so funds banked against a crystal on one
// slot are meaningless on the next. Left alone they also drove the cost readout
// negative once they exceeded the price ("-,118 coins").
global.skipFunds = 0;

global.ap_enabled = 1;
global.ap_err_count = 0;
external_call(global.ext_ap_connect, "", "Vertical Drop Heroes HD", global.ap_host);
global.ap_msg = "Archipelago: connecting to " + global.ap_host + "...";
global.ap_msg_timer = 300;
ap_debug("connect() issued to " + global.ap_host + " as '" + global.ap_slot + "'");
