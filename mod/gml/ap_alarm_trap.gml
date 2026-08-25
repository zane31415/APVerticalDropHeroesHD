// The Alarm Trap: as if the hero had just stepped on an alarm tile.
//
// Vanilla fires an alarm from two places -- the alarm tile in loop_char and an
// Alarm Goblin surviving a hit in injure_char -- and both do the same four
// things: noise, the "Alarm!" callout, `global.alarms += 1`, and a call to
// reinforcements(). The counter is the part that lasts: create_enemy adds
// `global.alarms` to every future enemy's max HP, so an alarm makes the whole
// rest of the run tougher rather than just spawning a few goblins.
//
// reinforcements(3, 100) matches the tile's own numbers. The second argument
// is a line depth used to pick how nasty the spawns are; 100 is past every
// `maxBlocks` threshold, so it draws from the full enemy mix the way the
// Alarm Goblin's own call does.

play_sound(31);
float_words(global.gHero, "Alarm!", 16777215);
global.alarms += 1;
reinforcements(3, 100);
smart_comment("alarm");

// The two map bonuses that make alarms worse are part of what an alarm *is*,
// so a trap that skipped them would be a weaker alarm on exactly the maps
// where alarms matter most.
if (global.mapBonus == 13)
{
    start_fire(global.gHero.x, global.gHero.y);
}
else if (global.mapBonus == 14)
{
    spawn_bomb(global.gHero.x, global.gHero.y - 64);
}

ap_log("Alarm Trap!");
ap_debug("alarm trap fired; global.alarms=" + string(global.alarms));
