// ap_pause_extra() -- is the pause menu's "End This Run Early" entry live?
//
// 1 adds one row to the vanilla page-1 menu (Return to Game / Game Options /
// Save and Exit); 0 leaves the menu exactly as it shipped. Three callers have
// to agree about this -- the choice count, the draw, and the action -- so they
// all ask here rather than each carrying its own copy of the test.
//
// Offered only where ending a run is a thing that can happen and is worth
// doing:
//   - Archipelago is on. Vanilla has no reason for it; dying is the vanilla
//     way out and it costs nothing there.
//   - A level is actually loaded (mapCode != 0, no hero-select screen up).
//     In the village there is no run to end, and room_restart from the hub
//     would be a confusing no-op.
//   - Not co-op, server or client. Co-op is not connected to Archipelago at
//     all, and the multiplayer modes drive the run from elsewhere.

if (!variable_global_exists("ap_enabled"))
{
    return 0;
}
if (!global.ap_enabled)
{
    return 0;
}
if (global.COOP || global.SERVER || global.CLIENT)
{
    return 0;
}
if (global.mapCode == 0 || global.selectScreen)
{
    return 0;
}
return 1;
