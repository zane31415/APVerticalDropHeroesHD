// ap_debug(text) -- append a line to ap_debug.log.
//
// With UseAppDataSaveLocation cleared (see patch.csx) this lands next to the
// exe, which makes it the one diagnostic that survives the mod failing before
// it can draw anything on screen.
//
// It also, until now, never wrote a single line. file_text_open_append does
// NOT create a missing file in GM:Studio -- it returns -1 -- and ap_boot's
// first act was to delete the log so each launch started clean. So the very
// first append of every session failed, and so did every one after it, and
// the file the whole debugging story rests on simply never appeared. Nothing
// reported an error because nothing checked the handle: file_text_write_string
// was being handed -1 thousands of times a session.
//
// Hence both halves below: create on failure, and never touch a bad handle.

var f = file_text_open_append("ap_debug.log");
if (f < 0)
{
    f = file_text_open_write("ap_debug.log");
}
if (f < 0)
{
    exit;   // read-only folder; nothing useful left to do about it
}
file_text_write_string(f, string(current_time) + "ms | " + string(argument0));
file_text_writeln(f);
file_text_close(f);
