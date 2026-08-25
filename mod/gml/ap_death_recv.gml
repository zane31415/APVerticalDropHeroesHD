// Handle one ap_bounced event. Only DeathLink is acted on.
//
// The kill itself cannot happen here: bounces arrive on whatever frame the
// socket delivers them, including at the main menu and mid-room-transition.
// So this only records the intent and ap_step() carries it out once there is
// a hero standing up to receive it.

if (!global.ap_enabled || !global.ap_death_link)
{
    exit;
}

// --- is this a DeathLink? --------------------------------------------------
var tags = external_call(global.ext_ap_json_proxy, 0, "tags");
if (tags < 0)
{
    exit;
}
var is_dl = 0;
var n = external_call(global.ext_ap_json_size, tags);
for (var i = 0; i < n; i += 1)
{
    if (external_call(global.ext_ap_json_string_at, tags, string(i)) == "DeathLink")
    {
        is_dl = 1;
    }
}
if (!is_dl)
{
    exit;
}

var data = external_call(global.ext_ap_json_proxy, 0, "data");
if (data < 0)
{
    exit;
}

// --- whose death was it? ---------------------------------------------------
// The server routes DeathLink to every tagged client including the one that
// sent it. Without this the hero would be killed by the death of the hero who
// just died, and the next run would start by dying.
var source = "";
if (external_call(global.ext_ap_json_exists, data, "source"))
{
    source = external_call(global.ext_ap_json_string_at, data, "source");
}
if (source == global.ap_slot)
{
    exit;
}

var cause = "";
if (external_call(global.ext_ap_json_exists, data, "cause"))
{
    cause = external_call(global.ext_ap_json_string_at, data, "cause");
}
if (cause == "")
{
    if (source == "")
    {
        cause = "DeathLink";
    }
    else
    {
        cause = source + " (DeathLink)";
    }
}

global.ap_dl_pending = 1;
global.ap_dl_cause = cause;
ap_log(cause);
ap_debug("DeathLink received from '" + source + "': " + cause);
