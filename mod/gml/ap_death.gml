// ap_death() -- the hero is dead for good; tell the multiworld.
//
// Hooked to `global.deadCount == 40` in obGameControl's Step, the single frame
// on which the game decides the run is over and puts up obGameOver. That test
// is an equality rather than a threshold, so it fires exactly once per death
// and needs no latch of its own -- and it is *after* Phoenix has had its
// chance, so a revived hero never announces a death it walked away from.
//
// The cause text is the same sentence the death screen shows, because that is
// the line other players will read in their own client.

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

var who = "The hero";
if (instance_exists(global.gHeroBar))
{
    who = global.gHeroBar.name;
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
