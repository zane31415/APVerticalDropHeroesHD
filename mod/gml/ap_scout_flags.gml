// ap_scout_flags(location_id) -- Archipelago's classification of the item on
// that location, as the bitmask the server sends with a scout reply:
//
//     1  progression      2  useful      4  trap      0  filler
//
// 0 for anything not scouted yet or not in our table, which is the same answer
// as "filler" on purpose: it is the neutral colour, so an unknown location
// looks ordinary rather than alarming.

var off = argument0 - global.ap_base_id;
if (off < 0 || off >= global.ap_loc_count)
{
    return 0;
}
return global.ap_scout_flag[off];
