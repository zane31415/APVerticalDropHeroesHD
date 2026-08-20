using System;
using System.Linq;
foreach (var r in Data.Rooms) {
    var objs = r.GameObjects.Select(g => g.ObjectDefinition?.Name?.Content).Where(n => n != null).Distinct().ToList();
    bool menu = objs.Contains("btnStartMenu");
    bool gc   = objs.Contains("obGameControl");
    Console.WriteLine($"ROOM {r.Name.Content,-22} instances={r.GameObjects.Count,-4} btnStartMenu={menu,-5} obGameControl={gc,-5} cc={(r.CreationCodeId!=null)}");
}
