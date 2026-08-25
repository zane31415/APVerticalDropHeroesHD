Vertical Drop Heroes HD - Archipelago
======================================

WHAT YOU NEED
-------------

1. Your own copy of Vertical Drop Heroes HD.

2. Python. If you do not have it: https://www.python.org/downloads/
   During setup, TICK THE BOX that says "Add python.exe to PATH".

That is the whole list. UndertaleModTool and gm-apclientpp.dll are already in
this zip - see THIRD-PARTY below.


INSTALLING
----------

1. COPY your whole game folder somewhere outside Steam, and work on the copy.
   Steam can overwrite or "verify" your real install and quietly undo all of
   this.

2. Copy EVERYTHING from this zip into that game folder. It should end up
   looking like this:

       Vertical Drop Heroes HD\
           data.win
           Vertical Drop Heroes HD.exe
           patch.bat            <-- from this zip
           gm-apclientpp.dll    <-- from this zip
           build\               <-- from this zip
           gml\                 <-- from this zip
           third-party\         <-- from this zip

3. Double-click patch.bat.

That is it. Two steps, nothing to download, no paths to type and no settings
to change.


PLAYING
-------

Launch the game. Go to Game Options > Archipelago. Fill in Server (something
like archipelago.gg:38281) and Slot, then choose Connect. Ctrl+V pastes.

After that you can just pick Single Player and it connects for you.

A status line shows in the top-left: connecting -> handshaking -> connected.

Leave Slot blank and the mod does nothing at all - the game plays as vanilla.


IF SOMETHING GOES WRONG
-----------------------

Open Game Options > Archipelago. The bottom of that page shows the build stamp
and the folder the game reads and writes. Check the stamp matches the patch you
just ran - if it does not, the game you launched is not the one that got
patched. Check steam_appid.txt is next to the exe, and that you are launching
the copy you patched rather than your Steam one.

That folder is where ap_debug.log lives, and it is NOT the game folder:
GameMaker redirects the game's file writes into its own save area, which is

    %LOCALAPPDATA%\Vertical_Drop_Heroes_HD\

archipelago.ini is in there too, and that is the copy the game actually reads -
editing the one sitting next to the exe has no effect. Set Debug=1 in it to
have the log record every event, which is worth doing before reproducing a bug
and worth turning off afterwards.

You do NOT need a separate Archipelago client running. The game talks to the
server itself. (A text client is still handy for chat and hints.)


THIRD-PARTY
-----------

This zip includes two components that belong to other projects, exactly as
their authors published them:

  UndertaleModTool 0.9.1.2 (GPL-3.0), which does the patching. It lives in
  build\utmt\, and its source is in third-party\UndertaleModTool\ because the
  GPL requires the source to travel with the program.

  gm-apclientpp v0.4.9-3 (MIT) by black-sliver, ThatOneGuy27 and LeonarthCG,
  which is the Archipelago client the patched game loads.

Licenses and details are in third-party\README.md. The mod itself - the GML,
the patcher scripts and the Archipelago world - is MIT.
