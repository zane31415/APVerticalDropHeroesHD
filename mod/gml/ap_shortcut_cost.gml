// Cost to ENABLE a shortcut crystal.
//
// Deliberately still costs, at the vanilla price. Enabling a shortcut is a
// meaningful in-run decision -- coins spent here are coins not spent on
// merchants -- so it stays a real trade-off. Only *using* an already-enabled
// shortcut is free (see ap_teleport_cost).
//
// Kept as a script rather than inlined so the price has exactly one
// definition: the affordability test, the deduction and both readouts all
// call this, and cannot drift apart.

return global.enemyLevel * 50;
