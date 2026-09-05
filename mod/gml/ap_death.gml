// ap_death() -- the hero is dead for good; tell the multiworld.
//
// Hooked to `global.deadCount == 40` in obGameControl's Step, the single frame
// on which the game decides the run is over and puts up obGameOver. That test
// is an equality rather than a threshold, so it fires exactly once per death
// and needs no latch of its own -- and it is *after* Phoenix has had its
// chance, so a revived hero never announces a death it walked away from.
//
// Not every death gets sent: see the amnesty block below, which is what keeps
// a roguelite's death rate from drowning the rest of the multiworld.
//
// The cause text is the same sentence the death screen shows, except for who
// it names: the hero's randomly generated name means nothing to the rest of
// the multiworld, which knows this world only by its slot name, so that is
// what the sentence other players read is built around.

if (!global.ap_enabled || !global.ap_ready || !global.ap_death_link)
{
    exit;
}

// Co-op is not connected to Archipelago at all; sending one player's death
// from a two-hero run would be reporting a run that is still going.
if (global.COOP)
{
    exit;
}

// A death that a DeathLink caused must not send one back. Two linked players
// would otherwise kill each other forever, one bounce per round trip.
if (global.ap_dl_cause != "" && global.death_cause == global.ap_dl_cause)
{
    ap_debug("death was itself a DeathLink; not re-sending");
    exit;
}

// --- amnesty ---------------------------------------------------------------
// Everything past the DeathLink test above is a death the player earned, so
// this is where the ration is spent. A roguelite kills the hero every few
// minutes; sending all of that is a firehose pointed at the rest of the
// multiworld, so the yaml can ask for one death in every N, after a one-off
// grace period of the first B.
//
// The count is persisted per seed+slot, not held in memory, or quitting to
// the menu would hand out the whole buffer again. Deaths caused by an
// incoming DeathLink never reach here, which is the point: those are not the
// player's own deaths and must not eat their allowance.
global.ap_death_count += 1;
ap_progress_save();

if (global.ap_death_count <= global.ap_death_buffer)
{
    ap_debug("amnesty: death " + string(global.ap_death_count) + " is within the "
             + string(global.ap_death_buffer) + "-death buffer; not sending");
    exit;
}

// 0 and 1 both mean "send every death". Counting from the end of the buffer
// rather than from zero makes the first death after it the start of a full
// interval instead of a partial one.
var every = max(1, global.ap_death_amnesty);
var since = global.ap_death_count - global.ap_death_buffer;
if ((since mod every) != 0)
{
    ap_debug("amnesty: death " + string(global.ap_death_count) + " is " +
             string(since mod every) + " of " + string(every) +
             " toward the next DeathLink; not sending");
    exit;
}

var who = global.ap_slot;
if (who == "")
{
    who = "The hero";
}

var cause = who + " is dead!";
if (global.death_cause != "")
{
    cause = who + " was killed by " + global.death_cause;
}
cause += (" on Level " + string(global.enemyLevel) + ".");

// The server bounces DeathLink back to every tagged client, sender included.
// The receiver drops anything whose `source` is us, which is why this can be
// fired and forgotten.
// Returns false if the DLL would not queue it -- no connection, or an API
// version without Bounce. Worth logging either way: a DeathLink that never
// leaves is indistinguishable from one nobody was listening for.
var sent = external_call(global.ext_ap_death_link, cause);
ap_debug("DeathLink send (queued=" + string(sent) + "): " + cause);
