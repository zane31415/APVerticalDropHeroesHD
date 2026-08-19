using System;
using UndertaleModLib.Models;
var gi = Data.GeneralInfo;
Console.WriteLine("InfoFlags = " + gi.Info);
Console.WriteLine("UseAppDataSaveLocation = " +
    gi.Info.HasFlag(UndertaleGeneralInfo.InfoFlags.UseAppDataSaveLocation));
Console.WriteLine("SteamEnabled = " +
    gi.Info.HasFlag(UndertaleGeneralInfo.InfoFlags.SteamEnabled));
Console.WriteLine("filename = " + gi.FileName?.Content);
