// ap_death_line(text) -- what the game-over screen should print on its
// "Killed by ..." line.
//
// Wrapped around the five single-player draw calls in obGameOver's Draw, one
// per language, so a DeathLink shows the sentence the other player's world
// sent rather than "Killed by <that whole sentence>" tacked onto a prefix that
// no longer fits it.
//
// The test is deliberately stateless: rather than a "this death was a
// DeathLink" flag that something would eventually have to remember to clear,
// it asks whether the current death cause is still the exact string the last
// DeathLink installed. Any ordinary death overwrites global.death_cause with
// its own killer, and obGameControl's Create blanks it on every level, so the
// flag cannot get stuck on.

if (!global.ap_enabled || global.ap_dl_cause == "")
{
    return argument0;
}
if (global.death_cause != global.ap_dl_cause)
{
    return argument0;
}
// The panel is only so wide and this text came from another game, which is
// free to be as verbose as it likes.
if (string_length(global.ap_dl_cause) > 52)
{
    return string_copy(global.ap_dl_cause, 1, 49) + "...";
}
return global.ap_dl_cause;
