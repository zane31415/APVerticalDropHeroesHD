// ap_goal() -- the Chosen One is down; the run is complete.

if (!global.ap_enabled || global.ap_goaled)
{
    exit;
}
global.ap_goaled = 1;
ap_check(global.ap_goal_loc);
external_call(global.ext_ap_status_update, global.AP_STATUS_GOAL);
ap_log("Goal complete!");
