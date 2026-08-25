// Binds gm-apclientpp.dll. Called once from ap_boot.
//
// global.ap_dll is set from archipelago.ini (DllPath) before this runs.
// The DLL is __cdecl (see include/gm-apclientpp.h: GM_DLL_CALL == __cdecl),
// so every define uses dll_cdecl. We only bind the calls this mod actually
// uses rather than all 52 exports.

global.ext_ap_init            = external_define(global.ap_dll, "apclient_init",            dll_cdecl, ty_real,   1, ty_real);
global.ext_ap_deinit          = external_define(global.ap_dll, "apclient_deinit",          dll_cdecl, ty_real,   0);
global.ext_ap_connect         = external_define(global.ap_dll, "apclient_connect",         dll_cdecl, ty_real,   3, ty_string, ty_string, ty_string);
global.ext_ap_disconnect      = external_define(global.ap_dll, "apclient_disconnect",      dll_cdecl, ty_real,   0);
global.ext_ap_poll            = external_define(global.ap_dll, "apclient_poll",            dll_cdecl, ty_string, 0);
global.ext_ap_get_state       = external_define(global.ap_dll, "apclient_get_state",       dll_cdecl, ty_real,   0);
global.ext_ap_connect_slot    = external_define(global.ap_dll, "apclient_connect_slot",    dll_cdecl, ty_real,   3, ty_string, ty_string, ty_string);
global.ext_ap_set_items       = external_define(global.ap_dll, "apclient_set_items_handling", dll_cdecl, ty_real, 1, ty_real);
global.ext_ap_set_version     = external_define(global.ap_dll, "apclient_set_version",     dll_cdecl, ty_real,   3, ty_real, ty_real, ty_real);
global.ext_ap_location_checks = external_define(global.ap_dll, "apclient_location_checks", dll_cdecl, ty_real,   1, ty_string);
global.ext_ap_location_scouts = external_define(global.ap_dll, "apclient_location_scouts", dll_cdecl, ty_real,   2, ty_string, ty_real);
global.ext_ap_get_player_game = external_define(global.ap_dll, "apclient_get_player_game", dll_cdecl, ty_string, 1, ty_real);
global.ext_ap_get_player_number = external_define(global.ap_dll, "apclient_get_player_number", dll_cdecl, ty_real, 0);
global.ext_ap_status_update   = external_define(global.ap_dll, "apclient_status_update",   dll_cdecl, ty_real,   1, ty_real);
global.ext_ap_say             = external_define(global.ap_dll, "apclient_say",             dll_cdecl, ty_real,   1, ty_string);
global.ext_ap_render_json     = external_define(global.ap_dll, "apclient_render_json",     dll_cdecl, ty_string, 2, ty_string, ty_real);
global.ext_ap_get_item_name   = external_define(global.ap_dll, "apclient_get_item_name",   dll_cdecl, ty_string, 2, ty_real, ty_string);
global.ext_ap_get_player_alias= external_define(global.ap_dll, "apclient_get_player_alias",dll_cdecl, ty_string, 1, ty_real);
global.ext_ap_get_seed        = external_define(global.ap_dll, "apclient_get_seed",        dll_cdecl, ty_string, 0);
global.ext_ap_dp_valid        = external_define(global.ap_dll, "apclient_is_data_package_valid", dll_cdecl, ty_real, 0);

// DeathLink. apclient_death_link() fills in the timestamp and the DeathLink
// tag itself; all we supply is the cause text. Receiving arrives as an
// ap_bounced event, which needs the DeathLink tag on our own connection --
// and slot_data (which is what tells us the option is on) only arrives after
// the slot handshake, so the tag goes on afterwards with connect_update.
global.ext_ap_death_link      = external_define(global.ap_dll, "apclient_death_link",      dll_cdecl, ty_real,   1, ty_string);
global.ext_ap_connect_update  = external_define(global.ap_dll, "apclient_connect_update",  dll_cdecl, ty_real,   1, ty_string);

// json accessors -- the GMS event path (no execute_string in GM:Studio)
global.ext_ap_json_source     = external_define(global.ap_dll, "apclient_json_source",     dll_cdecl, ty_string, 0);
global.ext_ap_json_proxy      = external_define(global.ap_dll, "apclient_json_proxy",      dll_cdecl, ty_real,   2, ty_real, ty_string);
global.ext_ap_json_exists     = external_define(global.ap_dll, "apclient_json_exists",     dll_cdecl, ty_real,   2, ty_real, ty_string);
global.ext_ap_json_size       = external_define(global.ap_dll, "apclient_json_size",       dll_cdecl, ty_real,   1, ty_real);
global.ext_ap_json_number_at  = external_define(global.ap_dll, "apclient_json_number_at",  dll_cdecl, ty_real,   2, ty_real, ty_string);
global.ext_ap_json_string_at  = external_define(global.ap_dll, "apclient_json_string_at",  dll_cdecl, ty_string, 2, ty_real, ty_string);
global.ext_ap_json_dump       = external_define(global.ap_dll, "apclient_json_dump",       dll_cdecl, ty_string, 1, ty_real);

// apclient constants
global.AP_STATE_DISCONNECTED      = 0;
global.AP_STATE_SOCKET_CONNECTING = 1;
global.AP_STATE_SOCKET_CONNECTED  = 2;
global.AP_STATE_ROOM_INFO         = 3;
global.AP_STATE_SLOT_CONNECTED    = 4;

global.AP_STATUS_PLAYING = 20;
global.AP_STATUS_GOAL    = 30;

global.AP_RENDER_TEXT = 0;
