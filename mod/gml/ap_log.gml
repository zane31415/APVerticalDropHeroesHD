// ap_log(text) -- push a line onto the on-screen AP feed.
// Ring buffer of 6; ap_log_count is the running total so the newest line is
// always at (count-1) mod 6.
//
// Mirrored into ap_debug.log. The feed and the file used to be disjoint, which
// put every server-side and DLL-side error -- the show_message branch of
// ap_dispatch included -- ON SCREEN ONLY, for six lines and 420 frames. So the
// one message a player could actually see was precisely the one they could not
// send anyone, and the log they were asked for had no trace of it.
//
// Through ap_trace, because ap_print_json calls this for every message the
// server broadcasts about anybody's game, which is the busiest source there
// is. Errors that matter -- the show_message branch, slot refusals -- log
// themselves through ap_debug at their own call sites.

var line = argument0;
ap_trace(line);
global.ap_log_line[global.ap_log_count mod 6] = line;
global.ap_log_count += 1;
global.ap_log_timer = 420;
