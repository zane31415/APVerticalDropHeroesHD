// Shrine Boost filler: one random shrine effect, free and on the spot.
//
// The seven picked here are the ones activate_block applies purely to the hero
// and the globals, so they can be reproduced faithfully without a shrine tile
// to stand on. Deliberately left out:
//   Flying      -- juggles a wing instance and a flytime counter
//   Ability     -- that is the Mana Refill filler already
//   Keys/Gems   -- Skeleton Key and Coin Cache already cover those
//   Tablet/Skip -- quest and shortcut, not boosts at all
//
// Nothing here charges global.ugCost. The coins are the shrine's price for
// standing in a dangerous room; an item the server sent you has already been
// paid for by whoever checked the location it sat on.

var hero = global.gHero;
var hb = hero.herobar;
var pick = irandom_range(1, 7);

if (pick == 1)
{
    hero.dmgmax += 1;
    if (instance_exists(hb))
    {
        hb.me_maxdmg += 1;
    }
    float_words(hero, "Damage Increased!", 16777215);
    play_sound(30);
}
else if (pick == 2)
{
    hero.hpmax += 3;
    if (instance_exists(hb))
    {
        hb.hpmax += 3;
    }
    hero.hp = hero.hpmax;
    float_words(hero, "HP Increased!", 16777215);
    play_sound(30);
}
else if (pick == 3)
{
    if (instance_exists(hb))
    {
        hb.xp += 25 * max(1, global.enemyLevel);
    }
    float_words(hero, "Experience Gained!", 16777215);
    play_sound(31);
}
else if (pick == 4)
{
    hero.invisible = 300;
    float_words(hero, "Invisibility!", 16777215);
    play_sound(81);
}
else if (pick == 5)
{
    global.shrineFire = 1;
    if (!global.CLIENT_SCAR)
    {
        for (var sn = 0; sn < 8; sn += 1)
        {
            fire_missile(hero, sn * 45, 263);
        }
    }
    float_words(hero, "Fire Shrine!", 16777215);
    play_sound(30);
}
else if (pick == 6)
{
    global.shrineIce = 1;
    if (!global.CLIENT_SCAR)
    {
        for (var sn = 0; sn < 8; sn += 1)
        {
            fire_missile(hero, sn * 45, 272);
        }
    }
    float_words(hero, "Ice Shrine!", 16777215);
    play_sound(30);
}
else
{
    global.shrineLightning = 1;
    if (!global.CLIENT_SCAR)
    {
        fire_missile(hero, irandom_range(20, 160), 241);
        fire_missile(hero, irandom_range(200, 340), 241);
    }
    float_words(hero, "Lightning Shrine!", 16777215);
    play_sound(30);
}

attach_effect(hero, 425, 0);
