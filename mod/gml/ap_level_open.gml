// ap_level_open(level) -- may the hero descend into `level`?
//
// Level 1 is always open: with level locks on and nothing received yet there
// still has to be somewhere to play, and the five level-1 merchant unlocks
// plus the first tier of each shop are the seed's sphere 0.
//
// Everything deeper wants Progressive Level Access items, counted in
// ap_apply_state into global.ap_level_max.

if (!global.ap_enabled || !global.ap_level_locks)
{
    return 1;
}
if (argument0 <= 1)
{
    return 1;
}
return (argument0 <= global.ap_level_max);
