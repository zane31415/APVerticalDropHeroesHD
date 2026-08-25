// ap_trace(text) -- ap_debug, but only when Debug=1 is set in archipelago.ini.
//
// The split exists because the interesting lines and the frequent lines are
// not the same lines. A merchant purchase or a location check happens a few
// times a minute and is always worth recording. Naming every event the DLL
// queues, and dumping every PrintJSON packet whole, happens as often as any
// player in the multiworld does anything -- and each one is a file open, write
// and close.
//
// Logging all of it unconditionally is what made the game unplayable: the cost
// is per line, and the line rate is set by other people's games, not by this
// one. So the noisy half is opt-in, for when there is something specific to
// catch.

if (!global.ap_verbose)
{
    exit;
}
ap_debug(argument0);
