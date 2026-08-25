// ap_desc_suffix(desc, target) -- what the info bar should say about a
// purchase.
//
// Hooked at obInfoBar's single draw_text_ext call rather than in the
// localisation branches above it, so every language is covered by one change.
// That hook sees EVERY info-bar target though -- shrines, statues, portals,
// quest givers -- so it must return the description untouched unless the
// target is one of the four Archipelago vendors.

var desc = argument0;
var tgt = argument1;

if (!global.ap_enabled || tgt == -4)
{
    return desc;
}

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
    var mn = ap_scout_name(global.ap_unlock_loc[n]);
    if (mn == "")
    {
        mn = "(not scouted yet)";
    }
    return "Buy an unlock for your future heroes.##AP: " + mn;
}

// --- shrines ---------------------------------------------------------------
// The next shrine you activate on this level checks the next slot, so that is
// the item to name. Which sprites count is ap_is_shrine's problem.
if (global.ap_shrine_checks > 0 && ap_is_shrine(tgt.sprite_index))
{
    var sn = ap_shrine_next(global.enemyLevel);
    if (sn > 0)
    {
        var sname = ap_scout_name(global.ap_shrine_loc[global.enemyLevel, sn]);
        if (sname == "")
        {
            sname = "(not scouted yet)";
        }
        return desc + "##AP: " + sname;
    }
}

// --- the three hub upgrade vendors ----------------------------------------
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
else
{
    return desc;   // not an Archipelago vendor: say nothing at all
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
