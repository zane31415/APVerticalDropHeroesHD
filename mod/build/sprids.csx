using System;
for (int i = 0; i < Data.Sprites.Count; i++) {
    var n = Data.Sprites[i].Name.Content;
    if (n=="sprNPC_Blacksmith"||n=="sprNPC_Healer"||n=="sprNPC_MonkC"||n=="spShrine_Skip"||n=="sprNPC_Merchant")
        Console.WriteLine($"SPR {i} = {n}");
}
