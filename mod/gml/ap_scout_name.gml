// ap_scout_name(location_id) -- what item sits on that location, if we have
// scouted it. Empty string when unknown.

var off = argument0 - global.ap_base_id;
if (off < 0 || off >= global.ap_loc_count)
{
    return "";
}
return global.ap_scout[off];
