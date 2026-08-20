Vertical Drop Heroes HD - Archipelago
======================================

WHAT YOU NEED
-------------

1. Your own copy of Vertical Drop Heroes HD.

2. Python. If you do not have it: https://www.python.org/downloads/
   During setup, TICK THE BOX that says "Add python.exe to PATH".

3. UndertaleModTool, CLI build:
   https://github.com/UnderminersTeam/UndertaleModTool/releases
   Download the file named  UTMT_CLI_<version>-Windows.zip

4. gm-apclientpp.dll, the 32-BIT build:
   https://github.com/black-sliver/gm-apclientpp/releases
   The 64-bit one will NOT work.

Items 3 and 4 are separate downloads because they belong to other projects and
are not ours to hand out.


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
           build\               <-- from this zip
           gml\                 <-- from this zip

3. Put gm-apclientpp.dll into that same game folder, next to data.win.

4. Unzip UndertaleModTool into the build\utmt folder, so that this exists:

       Vertical Drop Heroes HD\build\utmt\UndertaleModCli.exe

5. Double-click patch.bat.

That is it. No paths to type and no settings to change.


PLAYING
-------

Launch the game. Go to Game Options > Archipelago. Fill in Server (something
like archipelago.gg:38281) and Slot, then choose Connect. Ctrl+V pastes.

After that you can just pick Single Player and it connects for you.

A status line shows in the top-left: connecting -> handshaking -> connected.

Leave Slot blank and the mod does nothing at all - the game plays as vanilla.


IF SOMETHING GOES WRONG
-----------------------

Look for ap_debug.log in the game folder. If that file does not exist, then the
game you launched is not the one that got patched - check that steam_appid.txt
is sitting next to the exe, and that you are launching the copy you patched
rather than your Steam one.

You do NOT need a separate Archipelago client running. The game talks to the
server itself. (A text client is still handy for chat and hints.)
