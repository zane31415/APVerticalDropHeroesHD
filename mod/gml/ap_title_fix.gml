// ap_title_fix(title, target) -- corrects the info-bar title for the Merchant.
//
// The vanilla merchant branch only sets txt_title for longtext in
// {trait, power1, power2, sold}. Our category is "unlock", so none matched and
// the title kept its placeholder default -- which is where "TitleProgressive
// Shortcut" came from. The description had the same problem, which is why it
// sometimes rendered in French: an unmatched category fell through the
// language chain into whichever branch happened to be last.

if (!global.ap_enabled || argument1 == -4)
{
    return argument0;
}
if (argument1.sprite_index != sprNPC_Merchant)
{
    return argument0;
}
if (argument1.longtext == "sold")
{
    return "Sold Out!";
}
return "New Unlock: ";
