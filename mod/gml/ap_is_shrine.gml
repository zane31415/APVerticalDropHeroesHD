// ap_is_shrine(sprite) -- is this one of the random shrines?
//
// A positive whitelist, not "anything that is not X". ap_desc_suffix runs for
// every info-bar target there is -- portals, statues, quest givers, crates --
// so an exclusion list would annotate half the game.
//
// The twelve here are the shrine sprites activate_block has branches for.
// Deliberately absent:
//   spShrine_Dead    -- already used up
//   spShrine_Skip    -- the shortcut crystal, its own AP location
//   spShrine_Tablet  -- a quest collectible, placed by the quest rather than
//                       by the random-tile roll in place_tiles

var spr = argument0;
return (spr == spShrine_EExp || spr == spShrine_EGem
     || spr == spShrine_GDmg || spr == spShrine_GHp
     || spr == spShrine_GKey || spr == spShrine_Power
     || spr == spShrine_Flying || spr == spShrine_Invisible
     || spr == spShrine_Fire || spr == spShrine_Ice
     || spr == spShrine_GOG || spr == spShrine_Lightning);
