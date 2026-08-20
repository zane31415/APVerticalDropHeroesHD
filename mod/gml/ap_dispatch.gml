// Handles one event popped by apclient_poll().
//
// The event name comes from apclient_json_source(); its payload is readable
// through the json proxies until the next poll(). Proxy 0 is the root.

var src = external_call(global.ext_ap_json_source);

if (src == "ap_slot_connected")
{
    global.ap_ready = 1;
    global.ap_status_sent = 0;
    global.ap_err_count = 0;
    ap_log("Connected to Archipelago as " + global.ap_slot);
    // A fresh Connected means a full ReceivedItems resend is coming; drop the
    // tallies so ap_apply_state() rebuilds from the authoritative list.
    // Both mirrors are slot-specific and must be rebuilt from this server.
    // ap_slot_connected always precedes the ap_location_checked replay, so
    // clearing here is repopulated a moment later.
    ap_reset_tallies();
    ap_reset_sent();
    global.ap_scout_sent = 0;   // re-scout: the fill differs per seed
    exit;
}

if (src == "ap_items_received")
{
    var index = external_call(global.ext_ap_json_number_at, 0, "index");
    var len = external_call(global.ext_ap_json_number_at, 0, "len");
    if (index == 0)
    {
        ap_reset_tallies();
    }
    var ids = external_call(global.ext_ap_json_proxy, 0, "ids");
    if (ids >= 0)
    {
        for (var i = 0; i < len; i += 1)
        {
            ap_receive_item(external_call(global.ext_ap_json_number_at, ids, string(i)));
        }
    }
    ap_apply_state();
    exit;
}

if (src == "ap_location_info")
{
    // Reply to ap_scout_request: name what sits on each of our locations.
    var n = external_call(global.ext_ap_json_number_at, 0, "len");
    var locs = external_call(global.ext_ap_json_proxy, 0, "locations");
    var items = external_call(global.ext_ap_json_proxy, 0, "items");
    var plrs = external_call(global.ext_ap_json_proxy, 0, "players");
    if (locs >= 0 && items >= 0)
    {
        for (var i = 0; i < n; i += 1)
        {
            var lid = external_call(global.ext_ap_json_number_at, locs, string(i));
            var iid = external_call(global.ext_ap_json_number_at, items, string(i));
            var who = external_call(global.ext_ap_json_number_at, plrs, string(i));
            var game = external_call(global.ext_ap_get_player_game, who);
            var nm = external_call(global.ext_ap_get_item_name, iid, game);
            if (who != external_call(global.ext_ap_get_player_number))
            {
                nm += " (" + external_call(global.ext_ap_get_player_alias, who) + ")";
            }
            var off = lid - global.ap_base_id;
            if (off >= 0 && off < global.ap_loc_count)
            {
                global.ap_scout[off] = nm;
            }
        }
    }
    ap_debug("scout results stored: " + string(n));
    exit;
}

if (src == "ap_location_checked")
{
    // Fired on connect with the already-checked set, and again as we check
    // more. This is what drives which wares the Merchant still offers.
    var n = external_call(global.ext_ap_json_number_at, 0, "len");
    var locs = external_call(global.ext_ap_json_proxy, 0, "locations");
    if (locs >= 0)
    {
        for (var i = 0; i < n; i += 1)
        {
            ap_mark_sent(external_call(global.ext_ap_json_number_at, locs, string(i)));
        }
    }
    exit;
}

if (src == "ap_print_json")
{
    var raw = external_call(global.ext_ap_json_dump, 0);
    ap_log(external_call(global.ext_ap_render_json, raw, global.AP_RENDER_TEXT));
    exit;
}

if (src == "ap_room_info")
{
    ap_log("Room info received; connecting slot...");
    external_call(global.ext_ap_connect_slot, global.ap_slot, global.ap_password, "[]");
    exit;
}

if (src == "ap_slot_refused")
{
    global.ap_ready = 0;
    var reasons = external_call(global.ext_ap_json_proxy, 0, "reasons");
    var why = "unknown";
    if (reasons >= 0 && external_call(global.ext_ap_json_size, reasons) > 0)
    {
        why = external_call(global.ext_ap_json_string_at, reasons, "0");
    }
    ap_log("Slot refused: " + why);
    exit;
}

if (src == "ap_socket_connected")
{
    ap_log("Socket connected.");
    exit;
}

if (src == "ap_socket_disconnected")
{
    global.ap_ready = 0;
    global.ap_status_sent = 0;
    ap_log("Socket disconnected.");
    exit;
}

if (src == "ap_socket_error")
{
    global.ap_err_count += 1;
    // The client retries internally; only surface the first few so a dead
    // server does not spam the log every frame.
    if (global.ap_err_count <= 3)
    {
        ap_log("Socket error: " + external_call(global.ext_ap_json_string_at, 0, "message"));
    }
    exit;
}

if (src == "show_message")
{
    ap_log("AP error: " + external_call(global.ext_ap_json_string_at, 0, "message"));
    exit;
}
