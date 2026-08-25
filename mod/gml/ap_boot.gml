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
// Where the mod actually reads and writes -- which is NOT working_directory.
//
// GM:Studio's file sandbox redirects every write into the game's save area,
// and working_directory reports the game folder regardless. Clearing
// UseAppDataSaveLocation (patch.csx) moves that save area from Roaming to
// %LOCALAPPDATA%\Vertical_Drop_Heroes_HD\; it does NOT put files next to the
// exe, whatever working_directory claims. Printing working_directory therefore
// sent people to look in a folder the game had never written to -- ap_debug.log
// and archipelago.ini were both somewhere else the whole time.
//
// game_save_id is the sandbox's own answer to the same question, so it is the
// one that matches where the files land.
global.ap_diag_dir = game_save_id;

// Fresh log each launch, so what you send me is only this run.
//
// open_write, not file_delete: it truncates an existing log AND creates a
// missing one, which is the half that was missing. file_text_open_append
// cannot create a file, so deleting the log here used to guarantee that every
// append for the rest of the session failed silently -- see ap_debug.
//
// Before ap_verbose is read from the ini, so the first lines of the file are
// never gated on a setting that does not exist yet.
global.ap_verbose = 0;
var lf = file_text_open_write("ap_debug.log");
if (lf >= 0)
{
    file_text_close(lf);
}
ap_debug("ap_boot reached");
ap_debug("save area (game_save_id) = " + string(game_save_id));
ap_debug("working_directory = " + working_directory + "  <- NOT where files go");
ap_debug("program_directory = " + program_directory);

ap_tables();
// After ap_tables, not before: global.ap_build is one of the things it
// declares. First line that matters in any bug report -- which build produced
// this log.
ap_debug("mod build: " + global.ap_build);
ap_debug("ap_tables done, loc_count=" + string(global.ap_loc_count));

// --- received-item tallies (recomputed from scratch on every full resend) ---
global.ap_recv_shop[0] = 0;
global.ap_recv_shop[1] = 0;
global.ap_recv_shop[2] = 0;
global.ap_recv_short = 0;
global.ap_recv_level = 0;
global.ap_level_max = global.ap_final_level;
// Both default on, matching the options. slot_data corrects them on connect.
global.ap_shortcuts_on = 1;
global.ap_clears_on = 1;
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
    for (var n = 0; n <= global.ap_max_shrines; n += 1)
    {
        global.ap_sent_shrine[l, n] = 0;
    }
}
global.ap_sent_goal = 0;
for (var i = 1; i <= global.ap_unlock_total; i += 1)
{
    global.ap_sent_unlock[i] = 0;
}
global.ap_scout_sent = 0;
global.ap_dll_bound = 0;
// Whether the bound DLL gave us API version 2, which is the version Bounce --
// and so all of DeathLink -- lives in. Set for real in ap_connect_now when the
// DLL is bound; assumed off until then so nothing reads it undefined.
global.ap_bounce_ok = 0;
// Signature of the unlock set last applied. -1 rather than 0 so the very first
// ap_apply_state() counts as a change; at that point there is no select screen
// to reroll, so the only cost is the flag being honest from the start.
global.ap_skill_sig = -1;
// DeathLink. ap_dl_cause doubles as the "was this death a DeathLink?" marker
// (see ap_death_line), so it must start empty rather than undefined.
global.ap_dl_pending = 0;
global.ap_dl_cause = "";
// Filler and traps that arrived with no hero to give them to.
global.ap_pend_shrine = 0;
global.ap_pend_mana = 0;
global.ap_pend_key = 0;
global.ap_pend_alarm = 0;
// How many items this seed+slot has already consumed. Replaced from the ini
// on connect (ap_progress_load); until then, consume nothing.
global.ap_item_hwm = 999999;
global.ap_progress_key = "";
global.ap_menu_edit = 0;
global.ap_menu_slot = 8;   // extra entry appended to the Options page
for (var i = 0; i < global.ap_loc_count; i += 1)
{
    global.ap_scout[i] = "";
}

// --- config ---------------------------------------------------------------
ini_open("archipelago.ini");
global.ap_host = ini_read_string("Archipelago", "Host", "");
global.ap_slot = ini_read_string("Archipelago", "Slot", "");
global.ap_password = ini_read_string("Archipelago", "Password", "");
// Escape hatch: if the runner will not resolve the bare DLL name against the
// game folder, an absolute path can be given here.
global.ap_dll = ini_read_string("Archipelago", "DllPath", "gm-apclientpp.dll");
// Debug=1 turns on the per-event trace: every DLL event by name and every
// PrintJSON packet in full. Off by default because the line rate is set by how
// busy the multiworld is, and every line is a file open/write/close.
global.ap_verbose = (ini_read_real("Archipelago", "Debug", 0) > 0);
if (global.ap_host == "" && global.ap_slot == "")
{
    ini_write_string("Archipelago", "Host", "localhost:38281");
    ini_write_string("Archipelago", "Slot", "");
    ini_write_string("Archipelago", "Password", "");
    ini_write_real("Archipelago", "Debug", 0);
}
ini_close();
ap_debug("ini read: host='" + global.ap_host + "' slot='" + global.ap_slot +
         "' dll='" + global.ap_dll + "' verbose=" + string(global.ap_verbose));

if (global.ap_slot == "")
{
    global.ap_msg = "Archipelago: set up under Options > Archipelago";
    global.ap_msg_timer = 900;
    ap_debug("no Slot configured -> dormant; waiting for Options > Archipelago");
    exit;
}
if (global.ap_host == "")
{
    global.ap_host = "localhost:38281";
}

// --- deliberately NOT connecting here --------------------------------------
// Connecting at boot dropped the server's checked-location set on top of
// whatever the player was already doing, and ap_apply_state overwrote
// in-progress unlocks and shop levels. The connection is now made when a run
// actually starts (ap_connect_on_start, hooked to Single Player) or when the
// player hits Connect under Options > Archipelago. Both routes call
// ap_connect_now(), so the logic still lives in one place.
global.ap_msg = "Archipelago: ready (" + global.ap_slot + ")";
global.ap_msg_timer = 240;
ap_debug("configured for slot '" + global.ap_slot + "'; connecting on run start");
