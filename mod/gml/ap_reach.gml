// ap_reach(level) -- record that `level` has been cleared, if it is deeper
// than anything cleared before.
//
// global.ap_depth is a high-water mark for the whole slot, not the run. It has
// to be, because the one thing it sizes -- a Coin Cache -- is worth 25 coins
// per level and a roguelite starts every run back at level 1. Scaling on
// global.enemyLevel meant the same item paid out 25 coins in the village and
// 275 on the way down, so the only difference between a good Coin Cache and a
// bad one was whether the server happened to send it mid-run.
//
// Fed from two places, because neither alone covers every slot:
//
//   ap_level_cleared  every portal taken, INCLUDING when the level-clear
//                     locations are switched off and nothing is sent
//   ap_mark_sent      the clear locations the server replays on connect, which
//                     is what restores the mark on a machine that has never
//                     played this slot before
//
// Persisted for the same reason the death count is: held in memory it would
// reset to zero every time the player quit to the menu, and every Coin Cache
// after that would pay a level-1 rate. The connect replay can call this up to
// ten times in one frame, each with its own ini write; that is a once-per-
// connect cost on a file the menu rewrites anyway.

var l = min(argument0, global.ap_final_level);
if (l <= global.ap_depth)
{
    exit;
}
global.ap_depth = l;
ap_progress_save();
ap_debug("depth high-water mark is now level " + string(global.ap_depth));
