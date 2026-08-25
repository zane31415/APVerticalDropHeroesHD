// ap_shrine_next(level) -- lowest unchecked shrine slot on `level`, or 0.
//
// Bounded by ap_shrine_checks (this slot's setting), not ap_max_shrines (the
// id space), for the same reason ap_shop_next_tier is: the ids past the slot's
// count exist in the tables but have no location on the server.
//
// Returning 0 means "this level has no Archipelago slots left", which is a
// statement about checks and not about shrines: the shrine itself still spawns
// and still works.

if (argument0 < 1 || argument0 >= global.ap_final_level)
{
    return 0;
}
for (var n = 1; n <= global.ap_shrine_checks; n += 1)
{
    if (global.ap_sent_shrine[argument0, n] < 1)
    {
        return n;
    }
}
return 0;
