// Carry out a pending DeathLink, if there is a hero to kill right now.
//
// Called every frame from ap_step. The wait matters: bounces land whenever the
// socket delivers them, and "kill the hero" is only meaningful while a run is
// actually in progress. On the menu, on the hero-select screen, or during the
// frames after a death, the request is simply dropped -- holding it would kill
// the *next* hero, seconds after the death that caused it, which reads as the
// mod randomly executing you at the start of a run.
//
// The kill goes through injure_char rather than assigning hp directly so the
// hit registers the way any other lethal blow does: damage number, hit sound,
// and Phoenix still gets its revive. A DeathLink that a trait survives is the
// same deal every other death in this game offers.

if (!global.ap_dl_pending)
{
    exit;
}

// Same gate the filler queue uses: a living hero, and a room that is not
// already on its way out. gHero and friends do not exist as variables at all
// at the main menu, which is why this cannot be an unguarded read.
if (!ap_can_act())
{
    global.ap_dl_pending = 0;
    ap_debug("DeathLink dropped: no hero in a killable state");
    exit;
}

global.ap_dl_pending = 0;
// This doubles as the marker ap_death_line and ap_death test against: while
// death_cause still holds exactly this string, the death on screen is this
// DeathLink and no other.
global.death_cause = global.ap_dl_cause;
// Overkill on purpose: enough to beat any shield halving or damage reduction
// the hero happens to be carrying. Passing the obHero instance is vanilla's
// own idiom for environmental kills -- see the lava and electricity branches
// in obGameControl's Step, which are `injure_char(my_inst, ...)`.
injure_char(global.gHero, (global.gHero.hpmax * 4) + 9999);
ap_debug("DeathLink applied: " + global.ap_dl_cause);
