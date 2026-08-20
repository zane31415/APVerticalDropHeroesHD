// UndertaleModTool patch: adds the Archipelago client to Vertical Drop Heroes HD.
//
// Run via:
//   UndertaleModCli load <in.win> -s patch.csx -o <out.win>
//
// GML sources live in ../gml/. Everything is queued on one CodeImportGroup so
// a failure anywhere aborts the whole patch rather than leaving a half-modded
// data.win behind.

using System;
using System.IO;
using UndertaleModLib.Compiler;
using UndertaleModLib.Models;

string here = Path.GetDirectoryName(ScriptPath);
string gmlDir = Path.GetFullPath(Path.Combine(here, "..", "gml"));

string Gml(string name) => File.ReadAllText(Path.Combine(gmlDir, name + ".gml"));

// ---------------------------------------------------------------------------
// 0. Self-contained save location
// ---------------------------------------------------------------------------
// Vanilla ships with UseAppDataSaveLocation set, so saves and ini files go to
// %APPDATA%\Vertical_Drop_Heroes_HD\ -- shared with the untouched Steam
// install. Clearing the flag points working_directory at the game folder
// instead, so the modded build keeps vdh_save_11.ini, archipelago.ini and
// ap_debug.log entirely to itself and cannot disturb a Steam playthrough.
//
// Side effect worth knowing: the modded build starts from a blank save rather
// than inheriting your Steam unlocks. For Archipelago that is what you want.
var infoFlags = Data.GeneralInfo.Info;
if (infoFlags.HasFlag(UndertaleGeneralInfo.InfoFlags.UseAppDataSaveLocation))
{
    Data.GeneralInfo.Info = infoFlags & ~UndertaleGeneralInfo.InfoFlags.UseAppDataSaveLocation;
    Console.WriteLine("cleared UseAppDataSaveLocation -> saves live beside the exe");
}
else
{
    Console.WriteLine("UseAppDataSaveLocation already clear");
}

var g = new CodeImportGroup(Data);
g.AutoCreateAssets = true;
// Every find/replace below is anchored on verified-unique vanilla text; if one
// stops matching (e.g. a different game build) we want to hear about it.
g.ThrowOnNoOpFindReplace = true;

// ---------------------------------------------------------------------------
// 1. New scripts
// ---------------------------------------------------------------------------
string[] newScripts = {
    "ap_tables", "ap_dll", "ap_boot", "ap_step", "ap_dispatch",
    "ap_receive_item", "ap_apply_state", "ap_check", "ap_mark_sent",
    "ap_skill_in_stock", "ap_skill_name", "ap_log", "ap_draw", "ap_debug",
    "ap_shop_check", "ap_shop_open", "ap_level_cleared",
    "ap_shortcut_check", "ap_goal",
    "ap_merchant_next", "ap_merchant_check", "ap_refresh_counters",
    "ap_shop_next_tier", "ap_shop_price", "ap_shop_loc_next",
    "ap_shortcut_open", "ap_scout_name", "ap_scout_request", "ap_desc_suffix",
};
foreach (string s in newScripts)
    g.QueueReplace("gml_Script_" + s, Gml(s));

// ap_reset_tallies lives in ap_items.gml
g.QueueReplace("gml_Script_ap_reset_tallies", Gml("ap_items"));

// ---------------------------------------------------------------------------
// 2. Rewritten vanilla scripts
// ---------------------------------------------------------------------------
g.QueueReplace("gml_Script_new_unlock", Gml("new_unlock"));
g.QueueReplace("gml_Script_set_merchant", Gml("set_merchant"));

// ---------------------------------------------------------------------------
// 3. Lifecycle hooks
// ---------------------------------------------------------------------------
// obGameControl lives ONLY in rmGameplay/rmGameplay_Coop -- verified by
// walking Data.Rooms. Booting solely from there meant the mod was completely
// inert at the splash screens and main menu: no connection, no status, no
// log, and archipelago.ini never read. Since the player sits at the menu
// first, that looked exactly like "the patch did nothing".
//
// So boot and pump from btnStartMenu (rmMenu) as well, which runs immediately
// after the splashes. ap_boot is idempotent via global.ap_booted, so whichever
// object gets there first wins and the other is a no-op.
g.QueuePrepend("gml_Object_btnStartMenu_Create_0",
    "if (!variable_global_exists(\"ap_enabled\")) { global.ap_enabled = 0; }");
g.QueueAppend("gml_Object_btnStartMenu_Create_0", "ap_boot();");
g.QueueAppend("gml_Object_btnStartMenu_Step_0", "ap_step();");
g.QueueAppend("gml_Object_btnStartMenu_Draw_0", "ap_draw();");

g.QueueAppend("gml_Object_obGameControl_Create_0", "ap_boot();");
g.QueueAppend("gml_Object_obGameControl_Step_0", "ap_step();");
g.QueueAppend("gml_Object_obGameControl_Draw_64", "ap_draw();");

// ---------------------------------------------------------------------------
// 4. Location checks
// ---------------------------------------------------------------------------

// -- between-run shops ------------------------------------------------------
// Stop the sale once all tiers are checked, and let received items (not the
// purchase) drive the actual stat.
// Price every hub-merchant interaction off ap_shop_price(), which counts
// purchases MADE rather than items RECEIVED. Vanilla used global.<x>level,
// which AP drives from received items -- so a player who had checked five
// tiers but received none would have gone on paying tier-1 prices.
// Sites: the affordability test and the deduction in activate_block, the
// cost readout in obInfoBar, and the "can afford" pip in loop_tile.
string[] shopVar = { "dlevel", "hlevel", "plevel" };
string[] shopPrice = { "dprice", "hprice", "pprice" };
for (int i = 0; i < 3; i++)
{
    string vanilla = $"(global.{shopVar[i]} * global.{shopPrice[i]})";
    string priced = $"ap_shop_price({i})";
    g.QueueFindReplace("gml_Script_activate_block",
        $"global.coins >= {vanilla}", $"global.coins >= {priced} && ap_shop_open({i})");
    g.QueueFindReplace("gml_Script_activate_block",
        $"global.coins -= {vanilla}", $"global.coins -= {priced}");
    g.QueueFindReplace("gml_Object_obInfoBar_Draw_0",
        $"comma_coder{vanilla}", $"comma_coder({priced})");
    g.QueueFindReplace("gml_Script_loop_tile",
        $"global.coins >= {vanilla}", $"global.coins >= {priced}");
}

g.QueueTrimmedLinesFindReplace("gml_Script_activate_block",
@"global.dlevel += 1;
argument1.dmgmax += 1;
argument1.herobar.me_maxdmg += 1;",
@"ap_shop_check(0);
if (!global.ap_enabled)
{
global.dlevel += 1;
argument1.dmgmax += 1;
argument1.herobar.me_maxdmg += 1;
}");

g.QueueTrimmedLinesFindReplace("gml_Script_activate_block",
@"global.hlevel += 1;",
@"ap_shop_check(1);
if (!global.ap_enabled) global.hlevel += 1;");

g.QueueTrimmedLinesFindReplace("gml_Script_activate_block",
@"global.plevel += 1;",
@"ap_shop_check(2);
if (!global.ap_enabled) global.plevel += 1;");

// -- shortcut crystal -------------------------------------------------------
g.QueueTrimmedLinesFindReplace("gml_Script_activate_block",
@"global.skipLevel = global.enemyLevel;
global.levelSkipped = 1;
global.startLevel = global.enemyLevel + 1;",
@"ap_shortcut_check(global.enemyLevel);
global.levelSkipped = 1;
if (!global.ap_enabled)
{
global.skipLevel = global.enemyLevel;
global.startLevel = global.enemyLevel + 1;
}");

// Stop the crystal being re-sold once its location is checked. Vanilla gated
// this on global.skipLevel, which under AP only rises when the server sends a
// Progressive Shortcut -- so the crystal stayed on offer and the player could
// pay again and again to re-check the same location.
g.QueueFindReplace("gml_Script_activate_block",
    "if ((global.coins + global.skipFunds) >= (global.enemyLevel * 50))",
    "if ((global.coins + global.skipFunds) >= (global.enemyLevel * 50) && ap_shortcut_open(global.enemyLevel))");
g.QueueFindReplace("gml_Script_loop_tile",
    "else if (decor.sprite_index == spShrine_Skip && global.coins >= ((global.enemyLevel + 1) * (3 + (5 * global.gameDone))) && global.enemyLevel < (global.skipLevel - 1))",
    "else if (decor.sprite_index == spShrine_Skip && global.coins >= ((global.enemyLevel + 1) * (3 + (5 * global.gameDone))) && ap_shortcut_open(global.enemyLevel))");

// -- merchant ---------------------------------------------------------------
// set_merchant now advertises category "unlock" rather than a specific skill
// group, because the location is the purchase, not the skill.
g.QueueFindReplace("gml_Script_activate_block",
    "if (sellitem == \"trait\" || sellitem == \"power1\" || sellitem == \"power2\")",
    "if (sellitem == \"trait\" || sellitem == \"power1\" || sellitem == \"power2\" || sellitem == \"unlock\")");

// -- "what am I buying?" ----------------------------------------------------
// Hooked at the single draw call rather than in the localisation branches
// above it, so every language picks it up for free.
g.QueueFindReplace("gml_Object_obInfoBar_Draw_0",
    "draw_text_ext(x, y - 10, txt_desc, 20, 450);",
    "draw_text_ext(x, y - 10, ap_desc_suffix(txt_desc, target), 20, 450);");

// -- level clear ------------------------------------------------------------
// `global.portalDelay = 15;` appears twice (real portal + NG+ statue warp),
// so anchor on the following pacifist-bonus check to hit the portal only.
g.QueueTrimmedLinesFindReplace("gml_Script_activate_block",
@"global.portalDelay = 15;
play_sound(22);
if (global.mapBonus == 8 && global.isPacifist)",
@"global.portalDelay = 15;
ap_level_cleared(global.enemyLevel);
play_sound(22);
if (global.mapBonus == 8 && global.isPacifist)");

// -- goal -------------------------------------------------------------------
g.QueueTrimmedLinesFindReplace("gml_Object_obGameControl_Step_0",
    "global.gameDone += 1;",
    "global.gameDone += 1;\nap_goal();");

// ---------------------------------------------------------------------------
var result = g.Import(true);
Console.WriteLine($"AP patch applied. scripts={Data.Scripts.Count} code={Data.Code.Count}");
