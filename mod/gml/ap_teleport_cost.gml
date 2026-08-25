// Cost to USE an already-enabled shortcut (the Teleportation Shrine in the
// hub). Free under Archipelago for the same reason: skipLevel is granted by
// Progressive Shortcut items, and charging to use what the server handed you
// is a tax on progression.

// Free only when the shortcut really was granted by the server. With
// shortcuts left out of the multiworld they are earned in-game again, so the
// vanilla price comes back with them.
if (global.ap_enabled && global.ap_shortcuts_on)
{
    return 0;
}
return (global.enemyLevel + 1) * (3 + (5 * global.gameDone));
