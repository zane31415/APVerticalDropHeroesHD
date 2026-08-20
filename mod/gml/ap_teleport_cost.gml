// Cost to USE an already-enabled shortcut (the Teleportation Shrine in the
// hub). Free under Archipelago for the same reason: skipLevel is granted by
// Progressive Shortcut items, and charging to use what the server handed you
// is a tax on progression.

if (global.ap_enabled)
{
    return 0;
}
return (global.enemyLevel + 1) * (3 + (5 * global.gameDone));
