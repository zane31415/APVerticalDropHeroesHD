// ap_merchant_next() -- the next unpurchased merchant unlock, 1..50, or 0.
//
// Purchase order is the location identity now: the Nth unlock you ever buy is
// "Level ceil(N/5) Merchant Unlock ((N-1) mod 5)+1". The vanilla spawn cap
// (global.unlocked < min(50, enemyLevel * 5)) already stops you buying the
// 6th before level 2, so depth gating comes free.

for (var i = 1; i <= global.ap_unlock_total; i += 1)
{
    if (global.ap_sent_unlock[i] < 1)
    {
        return i;
    }
}
return 0;
