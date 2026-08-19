// One-time Archipelago startup. Called from obGameControl Create.
//
// Connection details come from archipelago.ini. GM:Studio's ini_open resolves
// against the save area first, so on a fresh install we write a template there
// and tell the player exactly where it landed.
//
// Ordering matters: config is read *before* the DLL is bound, so an install
// with no slot configured never calls external_define at all. A missing or
// unloadable DLL then cannot break an otherwise-vanilla playthrough.

if (variable_global_exists("ap_booted") && global.ap_booted)
{
    exit;
}
global.ap_booted = 1;

global.ap_enabled = 0;
global.ap_ready = 0;          // slot connected
global.ap_state = 0;
global.ap_status_sent = 0;
global.ap_goaled = 0;
global.ap_msg = "";
global.ap_msg_timer = 0;
global.ap_log_count = 0;
global.ap_log_timer = 0;
global.ap_err_count = 0;
global.ap_pending_trap = 0;

// Fresh log each launch, so what you send me is only this run.
if (file_exists("ap_debug.log"))
{
    file_delete("ap_debug.log");
}
ap_debug("ap_boot reached");
ap_debug("working_directory = " + working_directory);
ap_debug("program_directory = " + program_directory);

ap_tables();
ap_debug("ap_tables done, loc_count=" + string(global.ap_loc_count));

// --- received-item tallies (recomputed from scratch on every full resend) ---
global.ap_recv_shop[0] = 0;
global.ap_recv_shop[1] = 0;
global.ap_recv_shop[2] = 0;
global.ap_recv_short = 0;
for (var g = 0; g < 3; g += 1)
{
    for (var i = 0; i < global.ap_skill_count[g]; i += 1)
    {
        global.ap_recv_skill[g, i] = 0;
        global.ap_sent_skill[g, i] = 0;
    }
}
for (var s = 0; s < 3; s += 1)
{
    for (var t = 0; t <= global.ap_max_shop_tier; t += 1)
    {
        global.ap_sent_shop[s, t] = 0;
    }
}
for (var l = 0; l <= global.ap_final_level; l += 1)
{
    global.ap_sent_short[l] = 0;
    global.ap_sent_clear[l] = 0;
}
global.ap_sent_goal = 0;

// --- config ---------------------------------------------------------------
ini_open("archipelago.ini");
global.ap_host = ini_read_string("Archipelago", "Host", "");
global.ap_slot = ini_read_string("Archipelago", "Slot", "");
global.ap_password = ini_read_string("Archipelago", "Password", "");
// Escape hatch: if the runner will not resolve the bare DLL name against the
// game folder, an absolute path can be given here.
global.ap_dll = ini_read_string("Archipelago", "DllPath", "gm-apclientpp.dll");
if (global.ap_host == "" && global.ap_slot == "")
{
    ini_write_string("Archipelago", "Host", "localhost:38281");
    ini_write_string("Archipelago", "Slot", "");
    ini_write_string("Archipelago", "Password", "");
}
ini_close();
ap_debug("ini read: host='" + global.ap_host + "' slot='" + global.ap_slot +
         "' dll='" + global.ap_dll + "'");

if (global.ap_slot == "")
{
    global.ap_msg = "Archipelago: set Slot in archipelago.ini#" + working_directory;
    global.ap_msg_timer = 900;
    ap_debug("no Slot configured -> staying dormant (vanilla behaviour)");
    exit;
}
if (global.ap_host == "")
{
    global.ap_host = "localhost:38281";
}

// --- bind the client ------------------------------------------------------
ap_debug("binding DLL...");
ap_dll();
ap_debug("DLL bound OK");

// api_version 1: GM7/8 string syntax. We never use the execute_string path
// (GM:Studio removed it), so the GMS2 "+200" variant buys nothing here.
if (!external_call(global.ext_ap_init, 1))
{
    global.ap_msg = "Archipelago: apclient_init failed";
    global.ap_msg_timer = 600;
    ap_debug("apclient_init FAILED");
    exit;
}

external_call(global.ext_ap_set_version, 0, 6, 1);
// items_handling 7 = own world + other worlds + starting inventory.
// The full item list is resent on every connect, which is what lets
// ap_apply_state() stay a pure function of the tallies.
external_call(global.ext_ap_set_items, 7);

global.ap_enabled = 1;
external_call(global.ext_ap_connect, "", "Vertical Drop Heroes HD", global.ap_host);
global.ap_msg = "Archipelago: connecting to " + global.ap_host + "...";
global.ap_msg_timer = 300;
ap_debug("connect() issued to " + global.ap_host);
