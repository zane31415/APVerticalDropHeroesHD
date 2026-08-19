// ap_log(text) -- push a line onto the on-screen AP feed.
// Ring buffer of 6; ap_log_count is the running total so the newest line is
// always at (count-1) mod 6.

var line = argument0;
global.ap_log_line[global.ap_log_count mod 6] = line;
global.ap_log_count += 1;
global.ap_log_timer = 420;
