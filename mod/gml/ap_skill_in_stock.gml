// ap_skill_in_stock(group, index) -- is this skill still purchasable?
//
// Under AP: yes while its location is unchecked. Offline: fall back to the
// vanilla predicate so the build still works without a server.

var g = argument0;
var i = argument1;

if (global.ap_enabled)
{
    return (global.ap_sent_skill[g, i] < 1);
}

if (g == 0)
{
    return (global.tr_unlock[i] < 1);
}
if (g == 1)
{
    return (global.p1_unlock[i] < 1);
}
return (global.p2_unlock[i] < 1);
