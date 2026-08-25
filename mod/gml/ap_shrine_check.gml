// ap_shrine_check(block) -- a shrine was just used up.
//
// Prepended to destroy_shrine, which is the single point every successful
// shrine activation passes through: all thirteen branches in activate_block
// call it, so one hook covers every shrine type including any the game adds
// conditionally (spShrine_GOG on the GOG build).
//
// Called BEFORE destroy_shrine blanks the sprite, so argument0.decor still
// says which shrine this was.
//
// Not every destroy_shrine caller is a random shrine -- the shortcut crystal
// and the quest tablet go through it too -- so ap_is_shrine decides.
//
// The shrine still does whatever it always did. This is a level clear, not a
// merchant purchase: the check rides along with the vanilla effect rather than
// replacing it.
//
// Once a level has spent all `shrine_checks` of its slots this returns without
// doing anything, and that is the whole of "no more checks here". Shrines go
// on spawning and go on working; they are simply no longer worth anything to
// Archipelago. Nothing gates their placement.

if (!global.ap_enabled || global.ap_shrine_checks <= 0)
{
    exit;
}
if (!instance_exists(argument0.decor))
{
    exit;
}
if (!ap_is_shrine(argument0.decor.sprite_index))
{
    exit;
}

var l = global.enemyLevel;
var n = ap_shrine_next(l);
if (n <= 0)
{
    exit;
}
global.ap_sent_shrine[l, n] = 1;
ap_check(global.ap_shrine_loc[l, n]);
