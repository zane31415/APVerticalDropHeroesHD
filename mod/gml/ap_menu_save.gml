// Persist the connection fields so they survive a restart. Same file the mod
// has always read; the menu is just a friendlier front end for it.

ini_open("archipelago.ini");
ini_write_string("Archipelago", "Host", global.ap_host);
ini_write_string("Archipelago", "Slot", global.ap_slot);
ini_write_string("Archipelago", "Password", global.ap_password);
ini_write_string("Archipelago", "DllPath", global.ap_dll);
ini_close();
