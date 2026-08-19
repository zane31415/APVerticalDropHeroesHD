"""Builds the Archipelago-patched Vertical Drop Heroes HD.

  python build.py

Runs from two different layouts -- the dev repo (mod/build/) and the shipped
patcher bundle (vdh-ap-patcher/build/) -- so every input is located by search
rather than by a fixed relative path. Override any of them with:

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
SEARCH = [os.path.abspath(os.path.join(HERE, "..")),
          os.path.abspath(os.path.join(HERE, "..", ".."))]

GAME_DIR_NAME = "Vertical Drop Heroes HD"


def find_game_dir():
    env = os.environ.get("VDH_GAME_DIR")
    if env:
        if not os.path.isfile(os.path.join(env, "data.win")):
            sys.exit(f"VDH_GAME_DIR has no data.win: {env}")
        return env
    for root in SEARCH:
        cand = os.path.join(root, GAME_DIR_NAME)
        if os.path.isfile(os.path.join(cand, "data.win")):
            return cand
    sys.exit("Could not find the game folder.\n"
             "Set VDH_GAME_DIR to the folder containing data.win.")


def find_dll():
    env = os.environ.get("VDH_DLL")
    if env:
        return env if os.path.isfile(env) else None
    for root in SEARCH:
        cand = os.path.join(root, "gm-apclientpp.dll")
        if os.path.isfile(cand):
            return cand
    return None


def find_utmt():
    env = os.environ.get("UTMT_CLI")
    if env:
        return env if os.path.isfile(env) else None
    cand = os.path.join(HERE, "utmt", "UndertaleModCli.exe")
    return cand if os.path.isfile(cand) else None


def main():
    utmt = find_utmt()
    if not utmt:
        sys.exit("UndertaleModCli.exe not found.\n"
                 "Download the UTMT CLI build from\n"
                 "  https://github.com/UnderminersTeam/UndertaleModTool/releases\n"
                 f"and unzip it to {os.path.join(HERE, 'utmt')}\\\n"
                 "or set UTMT_CLI to its path.")

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
        if "AP patch applied" in line:
            print("  " + line.strip())

    os.replace(out, target)
    print(f"wrote {target}")

    dll = find_dll()
    if dll:
        shutil.copy2(dll, os.path.join(game, "gm-apclientpp.dll"))
        print("copied gm-apclientpp.dll into the game folder")
    else:
        print("WARNING: gm-apclientpp.dll not found.\n"
              "         Get the 32-BIT build from\n"
              "           https://github.com/black-sliver/gm-apclientpp/releases\n"
              "         and copy it next to the game exe yourself.")

    print("\nDone. Launch once; the game writes archipelago.ini and shows you "
          "its path on screen. Fill in Host and Slot, then restart.")


if __name__ == "__main__":
    main()
