// Per-frame Archipelago pump. Called from obGameControl Step.
//
// GM:Studio removed execute_string, so the documented poll() -> execute_string
// path is unavailable. Instead we drain the DLL's event queue and dispatch on
// apclient_json_source(), reading arguments back through the json proxies.
// Each poll() pops exactly one queued event and returns "" when the queue is
// empty, so the loop below is the drain.

if (!global.ap_enabled)
{
    exit;
}

if (global.ap_msg_timer > 0)
{
    global.ap_msg_timer -= 1;
}

var guard = 0;
while (guard < 64)
{
    var script = external_call(global.ext_ap_poll);
    if (string_length(script) == 0)
    {
        break;
    }
    ap_dispatch();
    guard += 1;
}

global.ap_state = external_call(global.ext_ap_get_state);

// Scout every location once, as soon as names are resolvable, so the shop UI
// can say what each purchase will hand over.
if (global.ap_ready && !global.ap_scout_sent
    && external_call(global.ext_ap_dp_valid))
{
    ap_scout_request();
}

// Announce PLAYING once the slot is live.
if (global.ap_ready && !global.ap_status_sent)
{
    external_call(global.ext_ap_status_update, global.AP_STATUS_PLAYING);
    global.ap_status_sent = 1;
}
