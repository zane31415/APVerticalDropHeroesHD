// Keeps global.unlocked equal to the number of merchant purchases we have
// actually made (locations checked), not the number of skills the server has
// given us. That counter drives both the unlock price (5 + 15 * unlocked) and
// the vanilla merchant spawn cap, so tying it to received items would let you
// re-buy the same tier cheaply and would break the depth gate.

if (!global.ap_enabled)
{
    exit;
}
var n = 0;
for (var i = 1; i <= global.ap_unlock_total; i += 1)
{
    n += (global.ap_sent_unlock[i] >= 1);
}
global.unlocked = n;
