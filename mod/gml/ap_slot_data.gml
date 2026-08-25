// Reconfigure the game from this slot's yaml, delivered as slot_data.
//
// Called from ap_dispatch while the ap_slot_connected event is live, because
// proxy 0 is only that event's argument until the next poll().
//
// Everything here has a baked-in default in ap_tables.gml, so a slot from an
// apworld older than this build still runs -- it just runs on the defaults.
// Values are clamped rather than trusted: slot_data is server data, and a
// nonsense shop-tier count would index off the end of the id tables.

var tiers = ap_sd_num("shop_upgrade_tiers", global.ap_shop_tiers);
global.ap_shop_tiers = max(1, min(global.ap_max_shop_tier, tiers));

global.ap_shop_price_step = max(0, ap_sd_num("shop_price_step",
                                             global.ap_shop_price_step));
global.ap_shop_price_cliff = max(0, ap_sd_num("shop_price_cliff",
                                              global.ap_shop_price_cliff));
// Guarded against zero specifically: this one is a divisor.
var every = ap_sd_num("shop_price_cliff_every", global.ap_shop_cliff_every);
global.ap_shop_cliff_every = max(1, every);

global.ap_level_locks = (ap_sd_num("level_locks", global.ap_level_locks) > 0);

// Which optional categories exist at all. The game needs these for more than
// bookkeeping: sending a check for a location the slot does not have is fatal
// to the server's command handler, not merely ignored.
global.ap_shortcuts_on = (ap_sd_num("include_shortcuts", 1) > 0);
global.ap_clears_on = (ap_sd_num("include_level_clears", 1) > 0);

var shrines = ap_sd_num("shrine_checks", global.ap_shrine_checks);
global.ap_shrine_checks = max(0, min(global.ap_max_shrines, shrines));
// Both halves have to agree: the yaml asked for it AND the DLL is at an API
// version that has Bounce at all. An old DLL that silently drops death_link
// would otherwise look exactly like a yaml that never turned it on.
global.ap_death_link = (ap_sd_num("death_link", 0) > 0) && global.ap_bounce_ok;
if (ap_sd_num("death_link", 0) > 0 && !global.ap_bounce_ok)
{
    ap_log("DeathLink is in the yaml but this gm-apclientpp is too old for it.");
}

ap_debug("slot_data: tiers=" + string(global.ap_shop_tiers) +
         " step=" + string(global.ap_shop_price_step) +
         " cliff=" + string(global.ap_shop_price_cliff) +
         "/" + string(global.ap_shop_cliff_every) +
         " level_locks=" + string(global.ap_level_locks) +
         " shrines=" + string(global.ap_shrine_checks) +
         " shortcuts=" + string(global.ap_shortcuts_on) +
         " clears=" + string(global.ap_clears_on) +
         " death_link=" + string(global.ap_death_link));

// Shop tiers and level locks both feed derived state, and the tallies were
// just cleared, so re-derive now rather than waiting for the first item.
ap_apply_state();

// The DeathLink tag has to be on our connection before the server will route
// other players' deaths to us. We connect before slot_data exists, so this is
// the earliest it can be asked for.
if (global.ap_death_link)
{
    // GML has no backslash escapes in double-quoted strings; single quotes are
    // the only way to put a quote character inside one.
    var tagged = external_call(global.ext_ap_connect_update, '["DeathLink"]');
    ap_log("DeathLink is on.");
    ap_debug("DeathLink tag sent (queued=" + string(tagged) + ")");
}
// No else. connect_slot already sent an empty tag list, and pushing another
// one would be a second chance to clobber a tag apclientpp set for itself.
