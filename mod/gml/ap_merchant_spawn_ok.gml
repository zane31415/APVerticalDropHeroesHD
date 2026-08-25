// ap_merchant_spawn_ok() -- may spawn_shop put another Merchant on this tile?
//
// Vanilla asked `(global.unlocked + global.merchantSpawned) < min(50,
// global.enemyLevel * 5)`, where global.unlocked is how many unlocks you have
// bought IN TOTAL. That works in vanilla because a Merchant sells any skill
// you do not own yet, so the cap is only ever about depth.
//
// Under Archipelago a Merchant on level L fills one of L's OWN five slots and
// nothing else (see ap_merchant_next), so a global counter is the wrong
// question and produces a permanent lockout:
//
//   fill level 3's five slots -> global.unlocked == 5
//   go back to level 1        -> 5 + 0 < min(50, 1 * 5) is false
//   -> level 1 never spawns another Merchant, and its own five locations
//      can never be checked by anyone
//
// The right question is the one the player would ask: does THIS level still
// have an unlock to sell? global.merchantSpawned is per-level, so comparing it
// against this level's remaining slots also stops a single descent spawning
// more Merchants than there is stock for.
//
// global.unlocked still drives the unlock price (5 + 15 * unlocked) and the
// Steam stat, which are both genuinely about the total, so ap_refresh_counters
// keeps maintaining it.

if (!global.ap_enabled)
{
    return ((global.unlocked + global.merchantSpawned) < min(50, global.enemyLevel * 5));
}

var lvl = global.enemyLevel;
if (lvl < 1)
{
    lvl = 1;
}
if (lvl > global.ap_unlock_levels)
{
    lvl = global.ap_unlock_levels;
}

var free = 0;
for (var slot = 1; slot <= global.ap_unlocks_per_level; slot += 1)
{
    var order = ((lvl - 1) * global.ap_unlocks_per_level) + slot;
    free += (global.ap_sent_unlock[order] < 1);
}
return (global.merchantSpawned < free);
