// REPLACES gml_Script_set_merchant.
//
// Vanilla stocked the Merchant with a random skill whose unlock flag was still
// 0, and buying it granted that specific skill.
//
// Under Archipelago the skill is the ITEM, so what the Merchant sells is just
// "the next unlock purchase" -- location identity is purchase order, not which
// skill. That is what lets the vanilla depth cap
// (global.unlocked < min(50, enemyLevel * 5)) act as real logic: the 6th
// unlock is unreachable until level 2, the 11th until level 3, and so on.
//
// argument0 is the decor instance; longtext is the ware category and
// longtext2 the label shown to the player, as vanilla.

if (global.ap_enabled)
{
    var n = ap_merchant_next();
    if (n <= 0)
    {
        argument0.longtext = "sold";
        argument0.longtext2 = "";
        exit;
    }
    argument0.longtext = "unlock";
    // Prefer the scouted item name; fall back to the location's own name until
    // the scout reply lands.
    var nm = ap_scout_name(global.ap_unlock_loc[n]);
    if (nm == "")
    {
        nm = "Unlock " + string(n);
    }
    argument0.longtext2 = nm;
    exit;
}

// --- offline fallback: vanilla behaviour ----------------------------------
var wares = ds_list_create();
var choices = ds_list_create();

var cat_name;
cat_name[0] = "trait";
cat_name[1] = "power1";
cat_name[2] = "power2";

for (var g = 0; g < 3; g += 1)
{
    var avail = 0;
    for (var i = 0; i < global.ap_skill_count[g]; i += 1)
    {
        if (ap_skill_in_stock(g, i))
        {
            avail += 1;
        }
    }
    if (avail > 0)
    {
        ds_list_add(wares, cat_name[g]);
    }
}

if (ds_list_size(wares) == 0)
{
    argument0.longtext = "sold";
    argument0.longtext2 = "";
    ds_list_destroy(wares);
    ds_list_destroy(choices);
    exit;
}

argument0.longtext = ds_list_find_value(wares, rng_int(0, ds_list_size(wares) - 1));

var group = 0;
if (argument0.longtext == "power1")
{
    group = 1;
}
else if (argument0.longtext == "power2")
{
    group = 2;
}

for (var i = 0; i < global.ap_skill_count[group]; i += 1)
{
    if (ap_skill_in_stock(group, i))
    {
        ds_list_add(choices, ap_skill_name(group, i));
    }
}

if (ds_list_size(choices) > 0)
{
    argument0.longtext2 = ds_list_find_value(choices, rng_int(0, ds_list_size(choices) - 1));
}

ds_list_destroy(wares);
ds_list_destroy(choices);
