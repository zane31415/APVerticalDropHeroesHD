// ap_desc_suffix(desc, target) -- appends "what you are buying" to an NPC's
// description in the info bar.
//
// Hooked into obInfoBar's draw_text_ext call rather than the localisation
// branches above it, so it applies to every language without touching any of
// them. That single hook sees EVERY info-bar target, though -- shrines,
// statues, portals, quest givers -- so it must say nothing at all unless the
// target is actually one of the four Archipelago vendors.

var desc = argument0;
var tgt = argument1;

if (!global.ap_enabled || tgt == -4)
{
    return desc;
}

var is_vendor = 1;
var lid = -1;
if (tgt.sprite_index == sprNPC_Blacksmith)
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
else if (tgt.sprite_index == sprNPC_Merchant)
{
    var n = ap_merchant_next();
    if (n > 0)
    {
        lid = global.ap_unlock_loc[n];
    }
}
else
{
    is_vendor = 0;
}

if (!is_vendor)
{
    return desc;
}
if (lid < 0)
{
    return desc + "##AP: sold out";
}

var nm = ap_scout_name(lid);
if (nm == "")
{
    nm = "(not scouted yet)";
}
return desc + "##AP: " + nm;
