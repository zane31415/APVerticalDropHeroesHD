// ap_tutorial_off() -- should the Monk of Knowledge keep quiet?
//
// The tutorial pages explain the vanilla game, pause it while they are up, and
// are keyed to global.tutorpage, which the save carries. Under Archipelago the
// player has already read the setup guide and is usually several runs into a
// multiworld, so the pages are pure interruption -- and one of them fires on
// the first step of every fresh save.
//
// Only the numbered pages are suppressed. showtutorial(-1) is the "you have
// unlocked X" popup, which under Archipelago is the one place the game names
// what a Merchant purchase actually handed over, so it stays; see the
// argument0 test at the call site in showtutorial.

if (!variable_global_exists("ap_enabled"))
{
    return 0;
}
return global.ap_enabled;
