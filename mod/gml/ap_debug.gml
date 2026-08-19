// ap_debug(text) -- append a line to ap_debug.log.
//
// With UseAppDataSaveLocation cleared (see patch.csx) this lands next to the
// exe, which makes it the one diagnostic that survives the mod failing before
// it can draw anything on screen.

var f = file_text_open_append("ap_debug.log");
file_text_write_string(f, string(current_time) + "ms | " + string(argument0));
file_text_writeln(f);
file_text_close(f);
