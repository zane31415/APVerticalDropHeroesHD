// Persist the consumed-items mark. Called only when it actually moves, so a
// steady stream of progression items does not rewrite the ini every batch.

if (global.ap_progress_key == "")
{
    exit;
}
ini_open("archipelago.ini");
ini_write_real("Progress", global.ap_progress_key, global.ap_item_hwm);
ini_close();
