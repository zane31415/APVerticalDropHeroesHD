"""Builds out/ -- everything a player or host needs.

  python mod/build/package.py

Produces:
  out/vertical_drop_heroes.apworld   drop into Archipelago/custom_worlds/
  out/vdh-ap-patcher/                give this to players
  out/vdh-ap-patcher.zip             ...zipped

Deliberately does NOT produce a patched data.win. That file is a derivative of
the game's own content; players patch their own copy with the bundled patcher.
"""
import os
import shutil
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
MOD = os.path.abspath(os.path.join(HERE, ".."))
ROOT = os.path.abspath(os.path.join(MOD, ".."))
OUT = os.path.join(ROOT, "out")

APWORLD_SRC = os.path.join(MOD, "apworld", "vertical_drop_heroes")
PATCHER_DIR = os.path.join(OUT, "vdh-ap-patcher")

SKIP_DIRS = {"__pycache__", "utmt", "verify"}
SKIP_EXT = {".pyc", ".pyo", ".log"}


def _keep(name):
    return os.path.splitext(name)[1] not in SKIP_EXT


def copy_tree(src, dst):
    for base, dirs, files in os.walk(src):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        rel = os.path.relpath(base, src)
        target = dst if rel == "." else os.path.join(dst, rel)
        os.makedirs(target, exist_ok=True)
        for f in files:
            if _keep(f):
                shutil.copy2(os.path.join(base, f), os.path.join(target, f))


def build_apworld():
    """Zip the world package. Archipelago expects the module directory itself
    to be the single top-level entry inside the archive."""
    path = os.path.join(OUT, "vertical_drop_heroes.apworld")
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        for base, dirs, files in os.walk(APWORLD_SRC):
            dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
            for f in files:
                if not _keep(f):
                    continue
                full = os.path.join(base, f)
                arc = os.path.join("vertical_drop_heroes",
                                   os.path.relpath(full, APWORLD_SRC))
                z.write(full, arc.replace(os.sep, "/"))
    return path


def build_patcher():
    if os.path.isdir(PATCHER_DIR):
        shutil.rmtree(PATCHER_DIR)
    os.makedirs(PATCHER_DIR)

    copy_tree(os.path.join(MOD, "gml"), os.path.join(PATCHER_DIR, "gml"))
    dst_build = os.path.join(PATCHER_DIR, "build")
    os.makedirs(dst_build, exist_ok=True)
    for f in ("gen_gml.py", "patch.csx", "build.py"):
        shutil.copy2(os.path.join(HERE, f), os.path.join(dst_build, f))
    # defs.py lives in the apworld package (single source of truth); the bundle
    # has no apworld dir, so drop a copy where gen_gml.py will find it.
    shutil.copy2(os.path.join(APWORLD_SRC, "defs.py"),
                 os.path.join(dst_build, "defs.py"))

    tmpl = os.path.join(ROOT, "archipelago.ini.template")
    if os.path.isfile(tmpl):
        shutil.copy2(tmpl, PATCHER_DIR)

    with open(os.path.join(PATCHER_DIR, "README.txt"), "w", encoding="utf-8") as f:
        f.write(PLAYER_README)

    zip_path = os.path.join(OUT, "vdh-ap-patcher.zip")
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
        for base, _dirs, files in os.walk(PATCHER_DIR):
            for fn in files:
                full = os.path.join(base, fn)
                arc = os.path.join("vdh-ap-patcher",
                                   os.path.relpath(full, PATCHER_DIR))
                z.write(full, arc.replace(os.sep, "/"))
    return zip_path


# Raw string: this text is full of Windows paths, and a stray \a or \V in a
# normal literal silently mangles them.
PLAYER_README = r"""Vertical Drop Heroes HD - Archipelago patcher
=============================================

You need TWO things this archive does not contain, because neither is ours to
redistribute:

  1. UndertaleModTool (CLI build)
     https://github.com/UnderminersTeam/UndertaleModTool/releases
     Download "UTMT_CLI_<version>-Windows.zip" and unzip it into build/utmt/
     so that build/utmt/UndertaleModCli.exe exists.
     (Or set the UTMT_CLI environment variable to UndertaleModCli.exe.)

  2. gm-apclientpp.dll -- the 32-BIT build
     https://github.com/black-sliver/gm-apclientpp/releases
     Put it next to this README.
     The 64-bit build will NOT work. Vertical Drop Heroes HD runs on the
     32-bit GameMaker 1.4 runner.

Then:

  3. COPY your game folder somewhere outside Steam. The patcher rewrites
     data.win in place. It keeps a data.win.vanilla snapshot so repeat builds
     start clean, but Steam will happily verify or update your live install
     out from under you.

  4. Point build.py at your copy and run it.

     PowerShell:
       $env:VDH_GAME_DIR = "C:\path\to\your\Vertical Drop Heroes HD"
       python build\build.py

     cmd.exe:
       set VDH_GAME_DIR=C:\path\to\your\Vertical Drop Heroes HD
       python build\build.py

     NOTE: in PowerShell, `set VDH_GAME_DIR=...` does NOT work -- `set` is an
     alias for Set-Variable there and never touches the environment. Use the
     $env: form above.

     It patches data.win and copies the DLL in beside the exe.

  5. Launch the game and go to Game Options > Archipelago. Fill in Server
     (e.g. archipelago.gg:38281) and Slot, then choose Connect.
     Ctrl+V pastes, which helps with long server strings.

     The details are saved to archipelago.ini in the game folder, so you can
     also edit that by hand.

If Slot is left blank the mod stays completely dormant and the game plays as
vanilla -- it does not even load the DLL.

A status line appears top-left: AP: connecting -> handshaking -> connected.

You do NOT need a separate Archipelago client running. The game talks to the
server directly. (A text client is still handy for chat and hints.)
"""


def main():
    os.makedirs(OUT, exist_ok=True)
    aw = build_apworld()
    pz = build_patcher()
    print(f"  {os.path.relpath(aw, ROOT)}")
    print(f"  {os.path.relpath(PATCHER_DIR, ROOT)}/")
    print(f"  {os.path.relpath(pz, ROOT)}")
    print("\nout/ built. No patched game files included by design -- players "
          "patch their own copy.")


if __name__ == "__main__":
    main()
