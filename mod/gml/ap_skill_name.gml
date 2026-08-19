// ap_skill_name(group, index) -- display name from the generated tables.

for (var n = 0; n < global.ap_sk_total; n += 1)
{
    if (global.ap_sk_group[n] == argument0 && global.ap_sk_index[n] == argument1)
    {
        return global.ap_sk_name[n];
    }
}
return "";
