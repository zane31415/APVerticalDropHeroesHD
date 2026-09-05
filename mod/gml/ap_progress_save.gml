// Persist this seed+slot's marks: the consumed-items high-water mark, the
// DeathLink amnesty's death count, and the deepest level cleared. Called only
// when one of them actually moves, so a steady stream of progression items does not rewrite the ini
// every batch. Both are written together because the ini is read whole and
// rewritten whole anyway, so splitting them would only cost a second pass.

if (global.ap_progress_key == "")
{
    exit;
}
ini_open("archipelago.ini");
ini_write_real("Progress", global.ap_progress_key, global.ap_item_hwm);
ini_write_real("Progress", global.ap_progress_key + "|deaths",
               global.ap_death_count);
ini_write_real("Progress", global.ap_progress_key + "|depth", global.ap_depth);
ini_close();
