// ap_merchant_check() -- the player bought an unlock from a Merchant.

if (!global.ap_enabled)
{
    exit;
}
var n = ap_merchant_next();
ap_debug("merchant bought on level " + string(global.enemyLevel) +
         ": slot " + string(n));
if (n > 0)
{
    global.ap_sent_unlock[n] = 1;
    ap_check(global.ap_unlock_loc[n]);
    ap_refresh_counters();
    ap_debug("merchant slot " + string(n) + " consumed; next is now " +
             string(ap_merchant_next()));
}
