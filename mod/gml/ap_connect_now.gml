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

    // api_version 2, NOT 1. Bounce -- and therefore apclient_death_link, the
    // ap_bounced event and the whole of DeathLink in both directions -- was
    // introduced in API version 2 and does not exist in version 1. Asking for
    // 1 did not error: the DLL simply never sent our deaths and never
    // delivered anyone else's, which is precisely as quiet as DeathLink being
    // switched off in the yaml, and is what it looked like.
    //
    // Still the bare number: the GMS2 "+200" variant only changes string
    // syntax, and this is GM:Studio 1.4. So 2, never 202.
    //
    // Falling back to 1 rather than giving up, because a player on an older
    // gm-apclientpp.dll should still get a working game -- just one without
    // DeathLink, which global.ap_bounce_ok is what records.
    // Logged call by call. Anything that goes wrong inside the DLL surfaces
    // as a show_message event ("Unknown exception" for its catch-all), which
    // says nothing about WHICH call threw -- so the log line immediately
    // before it has to.
    global.ap_bounce_ok = 1;
    ap_debug("calling apclient_init(2)");
    var init_ok = external_call(global.ext_ap_init, 2);
    ap_debug("apclient_init(2) returned " + string(init_ok));
    if (!init_ok)
    {
        global.ap_bounce_ok = 0;
        ap_debug("calling apclient_init(1) -- no Bounce, so no DeathLink");
        init_ok = external_call(global.ext_ap_init, 1);
        ap_debug("apclient_init(1) returned " + string(init_ok));
        if (!init_ok)
        {
            global.ap_msg = "Archipelago: apclient_init failed";
            global.ap_msg_timer = 600;
            ap_debug("apclient_init FAILED at both API versions");
            exit;
        }
        global.ap_msg = "Archipelago: old DLL, DeathLink unavailable";
        global.ap_msg_timer = 600;
    }
    ap_debug("apclient_init ok, bounce_ok=" + string(global.ap_bounce_ok));
    ap_debug("calling apclient_set_version(0,6,1)");
    external_call(global.ext_ap_set_version, 0, 6, 1);
    // items_handling 7 = own world + other worlds + starting inventory.
    ap_debug("calling apclient_set_items_handling(7)");
    external_call(global.ext_ap_set_items, 7);
    ap_debug("DLL bind sequence complete");
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
ap_debug("calling apclient_connect(host=" + global.ap_host + ")");
external_call(global.ext_ap_connect, "", "Vertical Drop Heroes HD", global.ap_host);
global.ap_msg = "Archipelago: connecting to " + global.ap_host + "...";
global.ap_msg_timer = 300;
ap_debug("connect() issued to " + global.ap_host + " as '" + global.ap_slot + "'");
