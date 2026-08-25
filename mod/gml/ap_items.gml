// ---- ap_reset_tallies -----------------------------------------------------
// Zeroes everything ap_apply_state() derives its output from. Called whenever
// the server is about to resend the full item list.

global.ap_recv_shop[0] = 0;
global.ap_recv_shop[1] = 0;
global.ap_recv_shop[2] = 0;
global.ap_recv_short = 0;
global.ap_recv_level = 0;
for (var g = 0; g < 3; g += 1)
{
    for (var i = 0; i < global.ap_skill_count[g]; i += 1)
    {
        global.ap_recv_skill[g, i] = 0;
    }
}
