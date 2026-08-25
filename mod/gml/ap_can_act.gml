// ap_can_act() -- is it safe to touch the hero or the world this frame?
//
// Anything the mod applies out of band -- a queued filler, a trap, a DeathLink
// -- has to ask this first, because ap_step() is appended to obGameControl's
// Step and therefore runs AFTER every vanilla branch in that event, including
// the one that queues a room change.
//
// That last point is what made an Alarm Trap crash the game. The portal
// descent at the end of obGameControl_Step does:
//
//     global.enemyLevel += 1;
//     global.mapCode = global.mapArray[global.enemyLevel];   // 0 -> 1
//     ...
//     room_restart();
//
// and room_restart() only takes effect once the event finishes -- so the
// appended ap_step() still ran, and a trap that had been waiting for
// `global.mapCode != 0` saw the *new* level's map code and fired into a room
// that was already being torn down. reinforcements() spawned enemies whose
// Create never completed, and Room End's `with (obHero) instance_destroy()`
// then read has_light off them:
//
//     Variable obHero.has_light not set before reading it
//     at gml_Object_obHero_Destroy_0
//     called from gml_Object_obGameControl_Other_5
//
// The tell was that it only ever happened on the frame a portal was taken.
//
// The checks, and what each one is for:
//
//   gHero / deadCount exist   we are at the main menu; none of this applies
//   selectScreen              hero select, and apply_hero's own room_restart
//   deadCount                 dead or dying; the game-over screen is up
//   gHero exists              nothing to apply it to
//   gHero.visible             false only at the two transition sites in
//                             activate_block: the exit portal and the NG+
//                             statue. This is the one that catches the crash
//                             above, because it stays false from the moment
//                             the portal is touched until the room restarts.
//   portalDelay               the 15-frame countdown to those transitions
//   heroPicked                cleared just before the Monk's save-reset
//                             room_restart, the one other way to queue a room
//                             change with a live visible hero

if (!variable_global_exists("gHero") || !variable_global_exists("deadCount"))
{
    return 0;
}
if (global.selectScreen || global.deadCount > 0 || !global.heroPicked)
{
    return 0;
}
if (!instance_exists(global.gHero))
{
    return 0;
}
if (!global.gHero.visible || global.portalDelay > 0)
{
    return 0;
}
return 1;
