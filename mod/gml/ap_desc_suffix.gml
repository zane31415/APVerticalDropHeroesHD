// ap_desc_suffix(desc, target) -- what the info bar should say about a
// purchase, split into two halves:
//
//   returned            the description text, drawn in the info bar's own
//                       colour
//   global.ap_desc_line the "AP: <item>" line that goes underneath it, or ""
//   global.ap_desc_flags that item's classification bitmask, which decides the
//                       colour, or -1 when the line names no item at all
//                       ("sold out", "(not scouted yet)")
//
// It is split because one draw_text_ext cannot carry two colours. ap_desc_draw
// is the only caller and does both draws; nothing else should read the two
// globals, which are live only for the frame that set them.
//
// Hooked (through ap_desc_draw) at obInfoBar's single draw call rather than in
// the localisation branches above it, so every language is covered by one
// change. That hook sees EVERY info-bar target though -- shrines, statues,
// portals, quest givers -- so it must return the description untouched unless
// the target is one of the four Archipelago vendors.

var desc = argument0;
var tgt = argument1;

global.ap_desc_line = "";
global.ap_desc_flags = -1;

if (!global.ap_enabled || tgt == -4)
{
    return desc;
}

// The location whose item this info bar is about, once we know which of the
// vendors we are looking at. -1 means "no Archipelago line here at all".
var lid = -1;
var body = desc;

// --- the Merchant ----------------------------------------------------------
// Replaced outright rather than appended to: with category "unlock" the
// vanilla text is a placeholder that can come out in the wrong language.
if (tgt.sprite_index == sprNPC_Merchant)
{
    if (tgt.longtext == "sold")
    {
        // Already bought from this one. Saying what the NEXT merchant holds
        // here just reads as though this one still has something.
        return "Already purchased.";
    }
    var n = ap_merchant_next();
    if (n <= 0)
    {
        return "No unlocks remaining.";
    }
    body = "Buy an unlock for your future heroes.";
    lid = global.ap_unlock_loc[n];
}
// --- shrines ---------------------------------------------------------------
// The next shrine you activate on this level checks the next slot, so that is
// the item to name. Which sprites count is ap_is_shrine's problem.
else if (global.ap_shrine_checks > 0 && ap_is_shrine(tgt.sprite_index))
{
    var sn = ap_shrine_next(global.enemyLevel);
    if (sn <= 0)
    {
        // Out of slots on this level: an ordinary shrine, described as one.
        return desc;
    }
    lid = global.ap_shrine_loc[global.enemyLevel, sn];
}
// --- the three hub upgrade vendors ----------------------------------------
else if (tgt.sprite_index == sprNPC_Blacksmith)
{
    lid = ap_shop_loc_next(0);
}
else if (tgt.sprite_index == sprNPC_Healer)
{
    lid = ap_shop_loc_next(1);
}
else if (tgt.sprite_index == sprNPC_MonkC)
{
    lid = ap_shop_loc_next(2);
}
else
{
    return desc;   // not an Archipelago vendor: say nothing at all
}

// ap_shop_loc_next returns a negative id for a shop with every tier checked;
// it is the only branch above that can leave lid unset.
if (lid < 0)
{
    global.ap_desc_line = "AP: sold out";
    return body;
}

var nm = ap_scout_name(lid);
if (nm == "")
{
    global.ap_desc_line = "AP: (not scouted yet)";
    return body;
}

global.ap_desc_line = "AP: " + nm;
global.ap_desc_flags = ap_scout_flags(lid);
return body;
