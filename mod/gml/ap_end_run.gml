// ap_end_run() -- retire the hero and go back to the village, deliberately.
//
// The pause menu's fourth entry (see ap_pause_extra). Under Archipelago a run
// is often over long before the hero is: the level ahead is locked, every
// Merchant and shrine on this level is spent, or the item that would make the
// descent survivable has not arrived yet. Vanilla's only way out of a run is
// to die, and dying now sends a DeathLink to everyone else in the multiworld
// -- so the player is made to choose between finishing a run they are done
// with and killing somebody else's hero for it. This is the third option.
//
// The end state is exactly ap_to_village's, which is exactly what the game
// does when a hero dies (obGameControl's Step, the space-to-continue arm of
// the game-over screen): the village comes back with the hero-select screen
// up, and coins, unlocks and shop tiers survive as they always do. Note
// heroPicked -- carrying the hero through a village rebuild instead leaves a
// level-20 hero in a fresh run's world, which is not a state the game reaches
// any other way.
//
// No DeathLink, by construction rather than by suppression: ap_death is hooked
// to `global.deadCount == 40`, deadCount only climbs while gHero is missing
// AND selectScreen is 0, and obGameControl's Create -- which runs on the
// room_restart below -- zeroes the first and, because heroPicked is cleared
// here, sets the second. There is no frame on which the death test can be
// true. The hero is retired, not killed, and nobody else's run is touched.

if (!ap_pause_extra())
{
    exit;
}

ap_log("Run ended early on level " + string(global.enemyLevel) + ".");
ap_debug("end run: level " + string(global.enemyLevel) + ", " +
         string(global.coins) + " coins kept");

// Out of the pause before the room goes away: PAUSED and gBlocker are globals
// that a room_restart does not touch, and leaving them set would drop the
// player into the village behind a paused blocker.
pause_game(0);

// Coins earned this run are already in global.coins and the village keeps
// them. Writing the save here means a player who quits from the village a
// moment later keeps them too -- the same courtesy "Save and Exit" does.
save_game("save");

global.mapCode = 0;
global.mapBonus = 0;
global.enemyLevel = 0;
global.heroPicked = 0;
global.heroPicked2 = 0;
room_restart();
