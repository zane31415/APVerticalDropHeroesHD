// ap_check(location_id) -- send one location check.
//
// The DLL takes arrays as a JSON string (see "API Limitations" in the
// gm-apclientpp README), so a single check is just "[id]". Re-sending an
// already-checked location is harmless; the server ignores it.

if (!global.ap_enabled || !global.ap_ready)
{
    exit;
}
external_call(global.ext_ap_location_checks, "[" + string(argument0) + "]");
ap_mark_sent(argument0);
