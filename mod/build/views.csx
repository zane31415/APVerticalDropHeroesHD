using System;
using UndertaleModLib.Models;
foreach (var r in Data.Rooms) {
    if (r.Name.Content != "rmMenu" && r.Name.Content != "rmGameplay") continue;
    Console.WriteLine($"ROOM {r.Name.Content} {r.Width}x{r.Height} views={r.Flags.HasFlag(UndertaleRoom.RoomEntryFlags.EnableViews)}");
    int i=0;
    foreach (var v in r.Views) {
        if (v.Enabled) Console.WriteLine($"   view{i} view={v.ViewX},{v.ViewY} {v.ViewWidth}x{v.ViewHeight} port={v.PortX},{v.PortY} {v.PortWidth}x{v.PortHeight}");
        i++;
    }
}
