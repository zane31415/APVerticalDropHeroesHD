// Cost to ENABLE a shortcut crystal.
//
// Free under Archipelago: the crystal is a location check and the shortcut
// itself only arrives as a Progressive Shortcut item, so charging for it taxes
// core traversal rather than gating anything.
//
// Incidentally kills a vanilla display bug: global.skipFunds persists in the
// save and accumulates across partial payments, so once it exceeded
// enemyLevel * 50 the shown cost went negative ("-,118").

if (global.ap_enabled)
{
    return 0;
}
return global.enemyLevel * 50;
