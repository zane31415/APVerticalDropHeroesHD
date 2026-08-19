// REPLACES gml_Script_set_merchant.
//
// Vanilla stocked the Merchant with skills whose unlock flag was still 0.
// Under Archipelago that is the wrong predicate in both directions: a skill
// granted by the server would vanish from the shop while its location was
// still unchecked, and a checked location would keep being offered forever.
// So under AP we filter on "location not yet checked" instead.
//
// argument0 is the decor instance; longtext is the ware category and
// longtext2 the specific skill, exactly as vanilla.

var wares = ds_list_create();
var choices = ds_list_create();

// group 0=trait 1=power1 2=power2
// (declared then indexed separately: GMS1.4 has no array literals)
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
    // Nothing left to sell anywhere.
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
