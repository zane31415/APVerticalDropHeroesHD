// The next level is locked: send the hero back to the village instead.
//
// Called from the portal transition in obGameControl's Step, in place of the
// `global.enemyLevel += 1` descent. By this point the portal branch of
// activate_block has already checked the level-clear location and stashed the
// hero's level, HP, damage and XP in global.h_*.
//
// The run ENDS here: this is exactly the state the game puts itself in when a
// hero dies (obGameControl's Step, the space-to-continue arm of the game-over
// screen), heroPicked included, so the village comes back with the hero-select
// screen up. Coins, unlocks and shop tiers survive as they always do.
//
// Carrying the hero through instead -- which is what leaving heroPicked at 1
// did -- kept its level, HP and XP across a village rebuild that resets the
// run state around it (keys, phoenix, startLevel, levelSkipped, the whole else
// branch of obGameControl's Create). A level-20 hero then re-entered level 1
// with a fresh run's everything else, which is not a state the game has
// anywhere else and behaved accordingly.

var blocked = global.enemyLevel + 1;

ap_log("Level " + string(blocked) + " is locked - back to the village.");
global.ap_msg = "Level " + string(blocked) +
                " needs a Progressive Level Access";
global.ap_msg_timer = 420;
ap_debug("level lock: descent to " + string(blocked) + " refused (max " +
         string(global.ap_level_max) + ")");

// Not a death, and nothing here can be mistaken for one. ap_death() is hooked
// to `global.deadCount == 40` and deadCount only climbs while gHero is missing
// AND selectScreen is 0 -- but obGameControl's Create zeroes deadCount and,
// with heroPicked cleared below, sets selectScreen to 1. It also runs strictly
// before the portal branch this was called from, so it cannot tick on the way
// out either. No DeathLink is sent for a refused descent, and none should be:
// the hero is retired, not killed.
global.mapCode = 0;
global.mapBonus = 0;
global.enemyLevel = 0;
global.heroPicked = 0;
global.heroPicked2 = 0;
// obGameControl's Create re-derives the rest from mapCode == 0, and from
// heroPicked == 0 in particular: that is the branch that sets selectScreen and
// builds the three candidates.
room_restart();
