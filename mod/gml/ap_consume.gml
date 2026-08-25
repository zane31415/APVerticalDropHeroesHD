// Drain the queued filler and trap effects, if there is a hero to apply them
// to. Called every frame from ap_step.
//
// Filler arrives whenever the server feels like sending it, which is often the
// main menu or the hero-select screen. Unlike a DeathLink (which is dropped if
// it cannot land, because killing the *next* hero seconds later would be
// nonsense) these are held: a Mana Refill that waits until the run starts is
// still a Mana Refill, and a trap that waits is still a trap.

// ap_can_act() is not just "is there a hero": it is also "is the room going to
// survive this frame". ap_step runs after the portal descent in the same Step
// event, so without it a queued trap fires into a room that room_restart() has
// already been called on -- see the comment in ap_can_act.gml.
if (!ap_can_act())
{
    exit;
}

while (global.ap_pend_key > 0)
{
    global.ap_pend_key -= 1;
    global.keys += 1;
    play_sound(30);
    float_words(global.gHero, "+1 Key!", 16777215);
}

while (global.ap_pend_mana > 0)
{
    global.ap_pend_mana -= 1;
    var hb = global.gHero.herobar;
    if (instance_exists(hb))
    {
        if (instance_exists(hb.orb1))
        {
            hb.orb1.charges = hb.orb1.maxcharges;
        }
        if (instance_exists(hb.orb2))
        {
            hb.orb2.charges = hb.orb2.maxcharges;
        }
    }
    play_sound(31);
    float_words(global.gHero, "Ability Recharged!", 16777215);
}

while (global.ap_pend_shrine > 0)
{
    global.ap_pend_shrine -= 1;
    ap_shrine_boost();
}

// The alarm trap needs somewhere to spawn reinforcements from, and the village
// has neither enemies nor spawn tiles. Held until a real level, rather than
// fired into nothing.
if (global.ap_pend_alarm > 0 && global.mapCode != 0)
{
    global.ap_pend_alarm -= 1;
    ap_alarm_trap();
}
