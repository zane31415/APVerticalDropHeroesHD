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
// Roaming: %APPDATA%\Vertical_Drop_Heroes_HD\ -- shared with the untouched
// Steam install. Clearing the flag moves the game's save area to Local,
// %LOCALAPPDATA%\Vertical_Drop_Heroes_HD\, so the modded build keeps
// vdh_save_11.ini, archipelago.ini and ap_debug.log to itself and cannot
// disturb a Steam playthrough.
//
// It does NOT put those files next to the exe, and working_directory says
// otherwise -- it reports the game folder either way, because GM:Studio's file
// sandbox redirects the writes underneath it. Believing working_directory cost
// a long evening of looking for a log in a folder the game had never written
// to. game_save_id is the value that matches reality; ap_boot reports that one.
//
// Side effect worth knowing: the modded build starts from a blank save rather
// than inheriting your Steam unlocks. For Archipelago that is what you want.
var infoFlags = Data.GeneralInfo.Info;
if (infoFlags.HasFlag(UndertaleGeneralInfo.InfoFlags.UseAppDataSaveLocation))
{
    Data.GeneralInfo.Info = infoFlags & ~UndertaleGeneralInfo.InfoFlags.UseAppDataSaveLocation;
    Console.WriteLine("cleared UseAppDataSaveLocation -> save area moves to %LOCALAPPDATA%");
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
    "ap_trace",
    "ap_shop_check", "ap_shop_open", "ap_level_cleared", "ap_reach",
    "ap_shortcut_check", "ap_goal",
    "ap_merchant_next", "ap_merchant_check", "ap_refresh_counters",
    "ap_merchant_restock", "ap_merchant_label",
    "ap_reroll_select", "ap_tutorial_off",
    "ap_reset_sent",
    "ap_shop_next_tier", "ap_shop_price", "ap_shop_loc_next",
    "ap_shortcut_open", "ap_shortcut_cost", "ap_teleport_cost",
    "ap_scout_name", "ap_scout_flags", "ap_scout_request",
    "ap_desc_suffix", "ap_desc_draw", "ap_item_colour", "ap_title_fix",
    "ap_connect_now", "ap_connect_on_start",
    "ap_menu_step", "ap_menu_typing", "ap_menu_draw",
    "ap_menu_style", "ap_menu_field", "ap_menu_set", "ap_menu_save",
    "ap_sd_num", "ap_slot_data",
    "ap_level_open", "ap_to_village",
    "ap_pause_extra", "ap_pause_draw", "ap_end_run",
    "ap_death", "ap_death_recv", "ap_dl_apply", "ap_death_line",
    "ap_is_shrine", "ap_shrine_next", "ap_shrine_check",
    "ap_effect", "ap_consume", "ap_can_act", "ap_shrine_boost", "ap_alarm_trap",
    "ap_progress_load", "ap_progress_save", "ap_purse_check",
    "ap_merchant_spawn_ok", "ap_crystal_spawn_ok",
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
// Room for the extra "Archipelago" entry on the Options page.
g.QueueAppend("gml_Object_btnStartMenu_Create_0",
@"ap_boot();
global.max_choices[2] = global.ap_menu_slot;");

// The Archipelago menu has to see input BEFORE the stock menu does, otherwise
// one keypress both types a character and moves the stock cursor. A prepended
// `exit` leaves the whole event, which a script-level exit could not do.
g.QueuePrepend("gml_Object_btnStartMenu_Step_0",
@"if (variable_global_exists(""ap_menu_edit""))
{
    if (global.ap_menu_edit > 0) { ap_menu_typing(); ap_step(); exit; }
    if (ap_menu_step()) { ap_step(); exit; }
}");
g.QueueAppend("gml_Object_btnStartMenu_Step_0", "ap_step();");
g.QueueAppend("gml_Object_btnStartMenu_Draw_0", "ap_draw(); ap_menu_draw();");

g.QueueAppend("gml_Object_obGameControl_Create_0", "ap_boot();");
g.QueueAppend("gml_Object_obGameControl_Step_0", "ap_step();");
g.QueueAppend("gml_Object_obGameControl_Draw_64", "ap_draw(); ap_pause_draw();");

// Connect only when a run actually starts. Doing it at boot meant the server's
// checked-location set arrived while the player was mid-session and
// ap_apply_state overwrote their in-progress unlocks and shop levels.
// Split Screen is left alone: co-op is untested with Archipelago.
g.QueueFindReplace("gml_Object_btnStartMenu_Step_0",
@"global.COOP = 0;
                room_goto(rmScroll);",
@"global.COOP = 0;
                ap_connect_on_start();
                room_goto(rmScroll);");

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
// Gate the ENTIRE crystal branch. Guarding only the affordability test left
// the else-if partial-payment arm reachable, which took the player's coins
// and gave nothing back.
g.QueueFindReplace("gml_Script_activate_block",
    "else if (global.mapCode != 0)",
    "else if (global.mapCode != 0 && ap_shortcut_open(global.enemyLevel))");
g.QueueFindReplace("gml_Script_loop_tile",
    "else if (decor.sprite_index == spShrine_Skip && global.coins >= ((global.enemyLevel + 1) * (3 + (5 * global.gameDone))) && global.enemyLevel < (global.skipLevel - 1))",
    "else if (decor.sprite_index == spShrine_Skip && global.coins >= ((global.enemyLevel + 1) * (3 + (5 * global.gameDone))) && ap_shortcut_open(global.enemyLevel))");

// -- merchant spawning ------------------------------------------------------
// Vanilla capped Merchants on the TOTAL number of unlocks bought. Under AP a
// Merchant fills one of its own level's five slots, so that counter locks a
// level out for good once five unlocks have been bought anywhere: fill level
// 3's slots and level 1 stops spawning Merchants forever, stranding its own
// five locations. Ask about this level's remaining stock instead.
g.QueueFindReplace("gml_Script_spawn_shop",
    "if ((global.unlocked + global.merchantSpawned) < min(50, global.enemyLevel * 5))",
    "if (ap_merchant_spawn_ok())");

// -- shortcut crystal spawning ----------------------------------------------
// Same shape of bug, worse consequence. Vanilla spawns the crystal exactly one
// level below the deepest shortcut you own, which under AP means the crystal
// LOCATION for level L needs L-2 Progressive Shortcut ITEMS to even appear --
// a requirement the logic knows nothing about, so generation could bury the
// item that spawns a crystal behind that same crystal. Spawn on any level
// whose shortcut location is still unchecked.
g.QueueFindReplace("gml_Object_obGameControl_Create_0",
    "if (!global.levelSkipped && global.enemyLevel == (global.skipLevel + 1))",
    "if (!global.levelSkipped && ap_crystal_spawn_ok())");

// -- merchant ---------------------------------------------------------------
// set_merchant now advertises category "unlock" rather than a specific skill
// group, because the location is the purchase, not the skill.
g.QueueFindReplace("gml_Script_activate_block",
    "if (sellitem == \"trait\" || sellitem == \"power1\" || sellitem == \"power2\")",
    "if (sellitem == \"trait\" || sellitem == \"power1\" || sellitem == \"power2\" || sellitem == \"unlock\")");

// The unlock popup and the float-up text both name argument0.decor.longtext2,
// which set_merchant wrote when this Merchant was PLACED -- a snapshot of what
// ap_merchant_next() said then. Re-derive it from the location the sale is
// about to check, before new_unlock consumes that slot, so what the player is
// told they bought is what the multiworld actually recorded.
g.QueueTrimmedLinesFindReplace("gml_Script_activate_block",
@"new_unlock(argument0.decor.longtext2);
global.last_skill = argument0.decor.longtext2;",
@"argument0.decor.longtext2 = ap_merchant_label(argument0.decor.longtext2);
new_unlock(argument0.decor.longtext2);
global.last_skill = argument0.decor.longtext2;");

// The sign on any OTHER Merchant still alive on this level is now a name for a
// location that has just been taken, so re-stock them too. Anchored AFTER the
// "sold" marker so the Merchant just bought from is left alone. This cannot
// stand in for the fix above: it only reaches Merchants that exist as
// instances, and the rest of a level is not built until the player descends
// into it.
g.QueueTrimmedLinesFindReplace("gml_Script_activate_block",
@"argument0.decor.longtext = ""sold"";
argument0.decor.longtext2 = """";
save_game(""save"");",
@"argument0.decor.longtext = ""sold"";
argument0.decor.longtext2 = """";
save_game(""save"");
ap_merchant_restock();");

// -- "End This Run Early" ---------------------------------------------------
// A fourth entry on the pause menu's first page, because vanilla's only exit
// from a run is to die and dying now costs everyone else in the multiworld a
// DeathLink. ap_pause_extra decides whether it exists at all, and all three
// hooks below ask it rather than repeating the test.
//
// The count first: pause_control wraps global.menu_choice on
// max_choices[menu_page], so without this the row could be drawn but never
// selected. It is assigned on the frame ESC is pressed, which is exactly when
// "is there a run to end?" wants answering.
g.QueueFindReplace("gml_Object_obGameControl_Step_0",
    "global.max_choices[1] = 3;",
    "global.max_choices[1] = 3 + ap_pause_extra();");

// Then the action. Anchored on the tail of choice 3 (Save and Exit), the only
// place in pause_control where a save is followed by room_goto.
g.QueueTrimmedLinesFindReplace("gml_Script_pause_control",
@"save_game(""save"");
room_goto(rmMenu);
}",
@"save_game(""save"");
room_goto(rmMenu);
}
else if (global.menu_choice == 4)
{
    ap_end_run();
}");

// -- tutorial ---------------------------------------------------------------
// The numbered pages pause the game to explain vanilla mechanics to a player
// who has just read an Archipelago setup guide, and tutorpage lives in the
// save, so a fresh modded save replays all of them. argument0 == -1 is not a
// page: it is the "you have unlocked X" popup, which is how a Merchant
// purchase reports what it handed over, so it is deliberately still allowed
// through.
g.QueuePrepend("gml_Script_showtutorial",
    "if (argument0 >= 0 && ap_tutorial_off()) { exit; }");

// -- "what am I buying?" ----------------------------------------------------
// Hooked at the single draw call rather than in the localisation branches
// above it, so every language picks it up for free.
//
// The draw is handed over wholesale rather than wrapped, because the item name
// is coloured by what Archipelago says it is -- red trap, yellow progression,
// blue useful, white filler -- and one draw_text_ext can only be one colour.
// ap_desc_draw draws the description, then the "AP:" line under it.
g.QueueFindReplace("gml_Object_obInfoBar_Draw_0",
    "draw_text_ext(x, y - 10, txt_desc, 20, 450);",
    "ap_desc_draw(x, y - 10, txt_desc, target);");
// The vanilla merchant branch only sets txt_title for trait/power1/power2/sold,
// so our "unlock" category left it at the placeholder "Title".
g.QueueFindReplace("gml_Object_obInfoBar_Draw_0",
    "draw_text(x, y - 30, txt_title);",
    "draw_text(x, y - 30, ap_title_fix(txt_title, target));");

// Shortcuts are free under Archipelago: enabling a crystal is a location
// check and using the Teleportation Shrine spends a Progressive Shortcut the
// server already granted, so charging for either taxes core traversal.
// Replaced everywhere (both activate_block arms, the loop_tile affordability
// pip, and the two cost readouts) so no site can disagree about the price.
// The max(0, ...) guards the readouts: global.skipFunds persists in the save
// and could exceed the cost, which is what produced the negative "-,118".
g.QueueFindReplace("gml_Script_activate_block",
    "((global.enemyLevel + 1) * (3 + (5 * global.gameDone)))", "ap_teleport_cost()");
g.QueueFindReplace("gml_Script_loop_tile",
    "((global.enemyLevel + 1) * (3 + (5 * global.gameDone)))", "ap_teleport_cost()");
g.QueueFindReplace("gml_Object_obInfoBar_Draw_0",
    "comma_coder((global.enemyLevel + 1) * (3 + (5 * global.gameDone)))",
    "comma_coder(ap_teleport_cost())");

g.QueueFindReplace("gml_Script_activate_block",
    "(global.enemyLevel * 50)", "ap_shortcut_cost()");
g.QueueFindReplace("gml_Object_obInfoBar_Draw_0",
    "comma_coder((global.enemyLevel * 50) - global.skipFunds)",
    "comma_coder(max(0, ap_shortcut_cost() - global.skipFunds))");
g.QueueFindReplace("gml_Object_obTile_Draw_0",
    "string((global.enemyLevel * 50) - global.skipFunds)",
    "string(max(0, ap_shortcut_cost() - global.skipFunds))");

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

// -- shrines ----------------------------------------------------------------
// One hook. Shrine *spawning* is left completely alone: a level that has used
// up its Archipelago slots still grows shrines, they just stop checking
// anything. ap_shrine_check returning early is the whole of "no more checks
// here", so there is nothing to gate at the place_tiles end.
//
// Every one of activate_block's thirteen shrine branches ends by
// calling destroy_shrine, so prepending there catches all of them -- including
// spShrine_GOG, which only exists on the GOG build. Prepended rather than
// appended because destroy_shrine is what blanks the sprite to spShrine_Dead,
// and ap_shrine_check needs to see which shrine it was.
g.QueuePrepend("gml_Script_destroy_shrine", "ap_shrine_check(argument0);");

// -- level locks ------------------------------------------------------------
// The descent happens in exactly one place: the portal countdown reaching zero
// in obGameControl's Step. Diverting it there means the level-clear check has
// already been sent (activate_block runs when the hero enters the portal, 15
// frames earlier) and global.h_* already holds the hero, so the village can be
// rebuilt around the same character.
//
// The village Teleportation Shrine is a second way down and is NOT hooked
// here; it is capped through global.skipLevel in ap_apply_state instead.
g.QueueTrimmedLinesFindReplace("gml_Object_obGameControl_Step_0",
@"else
{
global.enemyLevel += 1;
current_level = global.mapCode;",
@"else if (!ap_level_open(global.enemyLevel + 1))
{
ap_to_village();
}
else
{
global.enemyLevel += 1;
current_level = global.mapCode;");

// -- DeathLink --------------------------------------------------------------
// `global.deadCount == 40` is an equality, so it is true on exactly one frame
// per run -- the frame the game gives up and puts obGameOver on screen. That
// makes it a latch-free send point, and it sits after Phoenix has had its
// chance to revive, so a death the hero walked away from is never announced.
g.QueueTrimmedLinesFindReplace("gml_Object_obGameControl_Step_0",
@"var uiGameOver = instance_create(480, 360 + view_yview[0], obGameOver);
uiGameOver.depth = -2500;",
@"var uiGameOver = instance_create(480, 360 + view_yview[0], obGameOver);
uiGameOver.depth = -2500;
ap_death();");

// A DeathLink cause is a whole sentence from another game ("Bob was killed by
// a Goomba"), so pasting it after "Killed by " reads as nonsense. ap_death_line
// swaps the whole line out when the death on screen is a DeathLink and returns
// its argument untouched otherwise -- which is why every language branch can be
// wrapped mechanically. Only the five single-player ones matter; the co-op
// twins below them read global.death_cause2 and co-op never connects.
string[] killedBy = {
    "\"Mortos por: \" + translate(global.death_cause)",
    "\"Get\u00f6tet von: \" + translate(global.death_cause)",
    "\"Muerto por: \" + translate(global.death_cause)",
    "\"Tu\u00e9 par : \" + translate(global.death_cause)",
    "\"Killed by \" + global.death_cause",
};
foreach (string expr in killedBy)
    g.QueueFindReplace("gml_Object_obGameOver_Draw_0",
        "draw_text(x, y - 55, " + expr + ");",
        "draw_text(x, y - 55, ap_death_line(" + expr + "));");

// -- goal -------------------------------------------------------------------
g.QueueTrimmedLinesFindReplace("gml_Object_obGameControl_Step_0",
    "global.gameDone += 1;",
    "global.gameDone += 1;\nap_goal();");

// ---------------------------------------------------------------------------
var result = g.Import(true);
Console.WriteLine($"AP patch applied. scripts={Data.Scripts.Count} code={Data.Code.Count}");
