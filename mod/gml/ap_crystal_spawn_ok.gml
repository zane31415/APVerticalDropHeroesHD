// ap_crystal_spawn_ok() -- should this level grow a shortcut crystal?
//
// Vanilla: `global.enemyLevel == (global.skipLevel + 1)`. The crystal appears
// exactly one level below the deepest shortcut you own, so lighting them is a
// ladder -- each crystal is what unlocks the next one's spawn.
//
// Under Archipelago that ladder breaks, because global.skipLevel is derived
// from Progressive Shortcut ITEMS while `Shortcut to Level L` is a LOCATION.
// Checking level 7's crystal would have required already holding five
// Progressive Shortcuts, none of which the logic knows to require -- so
// generation was free to put Progressive Shortcut #5 behind the very crystal
// that needed it, and that is a softlock rather than a slow start.
//
// So: a crystal spawns on any level whose shortcut location is still
// unchecked, which makes the ten locations reachable in any order.
//
// This is deliberately more generous than vanilla, and the two things that
// keep it from being free are untouched: global.levelSkipped still allows only
// one crystal per run (the caller's own `!global.levelSkipped`), and
// ap_shortcut_cost still charges the vanilla enemyLevel * 50 to light it.

if (!global.ap_enabled || !global.ap_shortcuts_on)
{
    return (global.enemyLevel == (global.skipLevel + 1));
}
return ap_shortcut_open(global.enemyLevel);
