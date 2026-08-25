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

UndertaleModTool and gm-apclientpp are not fetched from the internet: both are
vendored in third-party/ and unpacked from there. See third-party/README.md.
"""
import os
import shutil
import subprocess
import sys

import vendor

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

# Any byte sequence that exists in a patched data.win and cannot exist in a
# clean one. Script names are interned as plain strings in the GEN8 string
# table, so this is a substring search on the raw file -- no UndertaleModTool
# needed, and it works on any game build rather than pinning one checksum.
PATCHED_MARKER = b"ap_boot"


def looks_patched(path):
    with open(path, "rb") as f:
        return PATCHED_MARKER in f.read()


def has_game(d):
    """Is this the game folder?

    Either file will do. data.win.vanilla is the pristine snapshot and is the
    thing we actually patch from, so a folder that has only that -- someone who
    carried the clean copy across and let the patched one go -- is still a
    perfectly good place to build.
    """
    return (os.path.isfile(os.path.join(d, "data.win"))
            or os.path.isfile(os.path.join(d, "data.win.vanilla")))


def find_game_dir():
    env = os.environ.get("VDH_GAME_DIR")
    if env:
        if not has_game(env):
            sys.exit(f"VDH_GAME_DIR has no data.win: {env}")
        return env
    for root in SEARCH:
        # the folder itself is the game folder (shipped layout)
        if has_game(root):
            return root
        # or the game is a subdirectory of it (dev repo)
        cand = os.path.join(root, GAME_DIR_NAME)
        if has_game(cand):
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
    # Nowhere to be seen: unpack the vendored copy beside this script. The
    # bundle already ships the DLL in the game folder, so this is the dev-repo
    # path, and the copy into the game folder happens as usual below.
    return vendor.unpack_dll(HERE)


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
    if os.path.isfile(cand):
        return cand
    # Not unpacked yet: the release bundle ships utmt/ ready to go, but in the
    # dev repo it is a build output, extracted from the vendored zip on demand.
    return vendor.unpack_utmt(os.path.join(HERE, "utmt"))


def report_build_stamp():
    """Say which build of the patcher this is, if the bundle was stamped.

    package.py writes BUILD.txt; the dev repo has none. Printed first thing so
    that a report of "I patched and nothing changed" carries the one fact that
    settles it -- copying a stale out/ over is otherwise indistinguishable from
    the patch not working.
    """
    for root in SEARCH:
        stamp = os.path.join(root, "BUILD.txt")
        if os.path.isfile(stamp):
            with open(stamp, encoding="utf-8") as f:
                print("patcher build: " + f.readline().strip())
            return


def main():
    report_build_stamp()
    utmt = find_utmt()
    if not utmt:
        sys.exit(
            "UndertaleModTool not found, and there is no vendored copy to\n"
            "unpack it from. Expected one of:\n"
            f"  {os.path.join(HERE, 'utmt', 'UndertaleModCli.exe')}\n"
            f"  {vendor.UTMT_ZIP}\n\n"
            "If the patcher zip was extracted only partly, extract it again.\n"
            "(Advanced: set UTMT_CLI to your own UndertaleModCli.exe.)")

    game = find_game_dir()
    target = os.path.join(game, "data.win")
    vanilla = os.path.join(game, "data.win.vanilla")
    print(f"game: {game}")

    # ALWAYS patch from data.win.vanilla when it exists. That file is the
    # pristine snapshot and the only correct input: the patch appends to
    # existing code entries, so running it over an already-patched file stacks
    # a second copy of every hook. Whatever state data.win is in is irrelevant
    # once the snapshot exists -- it is simply overwritten.
    if os.path.isfile(vanilla):
        if looks_patched(vanilla):
            # The one unrecoverable case. The snapshot is taken once and
            # trusted forever after, so if it was taken FROM a patched file
            # every build since has been doubling up, and no amount of
            # re-running fixes it.
            sys.exit(
                "data.win.vanilla is not vanilla -- it already contains the\n"
                "mod.\n\n"
                "It is the baseline every build patches from, so leaving it in\n"
                "place would stack a second copy of the mod on top of the\n"
                "first.\n\n"
                "Delete it, restore a clean data.win (Steam > Properties >\n"
                "Installed Files > Verify integrity of game files), and run\n"
                "this again.\n\n"
                f"  {vanilla}")
        print("patching from data.win.vanilla")
    else:
        # No snapshot yet, so data.win itself has to be the clean copy -- and
        # this is the one moment that can be got wrong permanently. Copy a
        # patched game folder to another machine without its data.win.vanilla,
        # run the patcher there, and a patched file becomes the baseline.
        if not os.path.isfile(target):
            sys.exit(
                f"No data.win and no data.win.vanilla in:\n  {game}\n\n"
                "There is nothing to patch. Copy the patcher into your game\n"
                "folder and run it again.")
        if looks_patched(target):
            sys.exit(
                "data.win is ALREADY PATCHED, and there is no\n"
                "data.win.vanilla to patch from.\n\n"
                "Snapshotting it now would make a patched file the permanent\n"
                "baseline, and every later build would stack another copy of\n"
                "the mod on top of the last.\n\n"
                "Restore a clean data.win first:\n"
                "  Steam > right-click Vertical Drop Heroes HD > Properties\n"
                "        > Installed Files > Verify integrity of game files\n"
                "or copy data.win from a fresh install, then run this again.\n\n"
                f"  {target}\n\n"
                "(If you moved this folder from another machine, bring its\n"
                "data.win.vanilla with it -- that IS the clean copy, and the\n"
                "patcher will use it on its own.)")
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
        print("WARNING: gm-apclientpp.dll not found, and no vendored copy to\n"
              "         unpack it from. The game will patch, but the mod will\n"
              "         not be able to connect. Expected:\n"
              f"           {vendor.DLL_ZIP}\n"
              "         If the patcher zip was extracted only partly, extract\n"
              "         it again.")

    print("\nDone! Now launch the game and go to:")
    print("    Game Options  >  Archipelago")
    print("Fill in Server and Slot, then choose Connect. After that, picking")
    print("Single Player connects for you automatically.")


if __name__ == "__main__":
    main()
