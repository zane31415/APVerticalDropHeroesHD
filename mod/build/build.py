"""Builds the Archipelago-patched Vertical Drop Heroes HD.

  python build.py

The normal case is that this lives INSIDE the game folder, as
<game>/build/build.py, so everything it needs is one directory up and no
configuration is required at all -- players unzip into the game folder and run
it. It also still works from the dev repo, where the game sits in a
subdirectory.

Environment overrides, only needed for unusual layouts:

  VDH_GAME_DIR   the game folder containing data.win
  VDH_DLL        path to the 32-bit gm-apclientpp.dll
  UTMT_CLI       path to UndertaleModCli.exe
"""
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
# Candidate roots: the patcher bundle puts inputs one level up, the dev repo
# two levels up.
# Where to look for the game and the DLL, nearest first:
#   HERE/..      <game>/build/build.py  -- the shipped layout
#   HERE/../..   mod/build/build.py     -- the dev repo
#   cwd          whatever the player was standing in
SEARCH = [os.path.abspath(os.path.join(HERE, "..")),
          os.path.abspath(os.path.join(HERE, "..", "..")),
          os.path.abspath(os.getcwd())]

GAME_DIR_NAME = "Vertical Drop Heroes HD"

# Steam AppID for Vertical Drop Heroes HD (from appmanifest_311480.acf).
#
# The shipped exe is Steam-DRM-wrapped: on launch it calls
# SteamAPI_RestartAppIfNecessary, Steam takes over, and Steam starts *its own*
# registered copy from steamapps\common -- so double-clicking a patched exe
# silently runs the UNPATCHED Steam install instead. Dropping steam_appid.txt
# next to the exe makes that check return false, and the local copy runs.
STEAM_APPID = "311480"


def find_game_dir():
    env = os.environ.get("VDH_GAME_DIR")
    if env:
        if not os.path.isfile(os.path.join(env, "data.win")):
            sys.exit(f"VDH_GAME_DIR has no data.win: {env}")
        return env
    for root in SEARCH:
        # the folder itself is the game folder (shipped layout)
        if os.path.isfile(os.path.join(root, "data.win")):
            return root
        # or the game is a subdirectory of it (dev repo)
        cand = os.path.join(root, GAME_DIR_NAME)
        if os.path.isfile(os.path.join(cand, "data.win")):
            return cand
    sys.exit(
        "Could not find data.win.\n\n"
        "This patcher expects to sit inside your game folder, like this:\n"
        "\n"
        "    Vertical Drop Heroes HD\\\n"
        "        data.win\n"
        "        Vertical Drop Heroes HD.exe\n"
        "        gm-apclientpp.dll\n"
        "        build\\build.py        <-- this file\n"
        "        gml\\\n"
        "\n"
        "Copy everything from the patcher zip into your game folder, then run\n"
        "it again. (Advanced: set VDH_GAME_DIR to the folder holding data.win.)")


def find_dll():
    env = os.environ.get("VDH_DLL")
    if env:
        return env if os.path.isfile(env) else None
    for root in SEARCH:
        cand = os.path.join(root, "gm-apclientpp.dll")
        if os.path.isfile(cand):
            return cand
        cand = os.path.join(root, GAME_DIR_NAME, "gm-apclientpp.dll")
        if os.path.isfile(cand):
            return cand
    return None


def _same_file(a, b):
    if os.path.getsize(a) != os.path.getsize(b):
        return False
    with open(a, "rb") as fa, open(b, "rb") as fb:
        return fa.read() == fb.read()


def find_utmt():
    env = os.environ.get("UTMT_CLI")
    if env:
        return env if os.path.isfile(env) else None
    cand = os.path.join(HERE, "utmt", "UndertaleModCli.exe")
    return cand if os.path.isfile(cand) else None


def main():
    utmt = find_utmt()
    if not utmt:
        sys.exit(
            "UndertaleModTool not found.\n\n"
            "Download the CLI build from:\n"
            "  https://github.com/UnderminersTeam/UndertaleModTool/releases\n\n"
            "Take the file named  UTMT_CLI_<version>-Windows.zip  and unzip it\n"
            "so that this file exists:\n"
            f"  {os.path.join(HERE, 'utmt', 'UndertaleModCli.exe')}")

    game = find_game_dir()
    target = os.path.join(game, "data.win")
    vanilla = os.path.join(game, "data.win.vanilla")
    print(f"game: {game}")

    # Always patch from a pristine snapshot: the patch appends to existing code
    # entries, so applying it twice would duplicate the hooks.
    if not os.path.isfile(vanilla):
        print("first run: snapshotting vanilla data.win")
        shutil.copy2(target, vanilla)

    print("generating GML tables...")
    subprocess.run([sys.executable, os.path.join(HERE, "gen_gml.py")], check=True)

    print("patching data.win...")
    out = target + ".new"
    r = subprocess.run(
        [utmt, "load", vanilla, "-s", os.path.join(HERE, "patch.csx"), "-o", out],
        stdin=subprocess.DEVNULL, capture_output=True, text=True)
    tail = (r.stdout or "") + (r.stderr or "")
    if r.returncode != 0 or not os.path.isfile(out):
        print(tail[-4000:])
        sys.exit(f"patch failed (exit {r.returncode})")
    for line in tail.splitlines():
        if 'AP patch applied' in line or 'UseAppDataSaveLocation' in line:
            print("  " + line.strip())

    os.replace(out, target)
    print(f"wrote {target}")

    # Without this the Steam DRM wrapper hands off to Steam and the unpatched
    # Steam copy runs instead of this one.
    appid_path = os.path.join(game, "steam_appid.txt")
    with open(appid_path, "w", encoding="ascii", newline="") as f:
        f.write(STEAM_APPID)
    print(f"wrote steam_appid.txt ({STEAM_APPID}) so the DRM wrapper runs THIS copy")

    dll = find_dll()
    if dll:
        dst = os.path.join(game, "gm-apclientpp.dll")
        if os.path.isfile(dst) and _same_file(dll, dst):
            print("gm-apclientpp.dll already up to date")
        else:
            try:
                shutil.copy2(dll, dst)
                print("copied gm-apclientpp.dll into the game folder")
            except PermissionError:
                # Almost always "the game is still running and has the DLL
                # loaded". data.win is already written, so this is a warning
                # rather than a failure.
                print("NOTE: could not replace gm-apclientpp.dll (in use). "
                      "Close the game and re-run if the DLL itself changed; "
                      "data.win is already patched either way.")
    else:
        print("WARNING: gm-apclientpp.dll not found.\n"
              "         Get the 32-BIT build from\n"
              "           https://github.com/black-sliver/gm-apclientpp/releases\n"
              "         and copy it next to the game exe yourself.")

    print("\nDone! Now launch the game and go to:")
    print("    Game Options  >  Archipelago")
    print("Fill in Server and Slot, then choose Connect. After that, picking")
    print("Single Player connects for you automatically.")


if __name__ == "__main__":
    main()
