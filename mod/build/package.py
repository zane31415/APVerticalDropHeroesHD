"""Builds out/ -- everything a player or host needs.

  python mod/build/package.py

Produces:
  out/vertical_drop_heroes.apworld   drop into Archipelago/custom_worlds/
  out/vdh-ap-patcher/                give this to players
  out/vdh-ap-patcher.zip             ...zipped

The patcher bundle is self-contained: UndertaleModTool and gm-apclientpp are
unpacked into it from mod/third-party/, so a player extracts one zip and runs
patch.bat with nothing else to fetch. Their licenses -- and the GPL source that
has to travel with the UndertaleModTool binary -- go in third-party/ beside it.

Deliberately does NOT produce a patched data.win. That file is a derivative of
the game's own content; players patch their own copy with the bundled patcher.
"""
import datetime
import json
import os
import shutil
import subprocess
import sys
import zipfile

import vendor

HERE = os.path.dirname(os.path.abspath(__file__))
MOD = os.path.abspath(os.path.join(HERE, ".."))
ROOT = os.path.abspath(os.path.join(MOD, ".."))
OUT = os.path.join(ROOT, "out")

APWORLD_SRC = os.path.join(MOD, "apworld", "vertical_drop_heroes")
MANIFEST = os.path.join(APWORLD_SRC, "archipelago.json")

# defs.py is the single source of truth, version included.
sys.path.insert(0, APWORLD_SRC)
import defs  # noqa: E402
PATCHER_DIR = os.path.join(OUT, "vdh-ap-patcher")
THIRD_PARTY = os.path.join(MOD, "third-party")

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


def check_manifest():
    """archipelago.json must agree with defs.WORLD_VERSION.

    Two files have to carry the version -- Archipelago reads the manifest, and
    everything on the game side derives from defs -- so the only safe
    arrangement is for one of them to be authoritative and the build to refuse
    when they drift. Same reasoning as ThrowOnNoOpFindReplace in patch.csx:
    a mismatch that ships is a release where the apworld and the patched game
    disagree about what they are, which is exactly the thing nobody can debug
    from the outside.
    """
    with open(MANIFEST, encoding="utf-8") as f:
        m = json.load(f)
    problems = []
    if m.get("world_version") != defs.WORLD_VERSION:
        problems.append(f'  world_version {m.get("world_version")!r} '
                        f'!= defs.WORLD_VERSION {defs.WORLD_VERSION!r}')
    if m.get("minimum_ap_version") != defs.MIN_AP_VERSION:
        problems.append(f'  minimum_ap_version {m.get("minimum_ap_version")!r} '
                        f'!= defs.MIN_AP_VERSION {defs.MIN_AP_VERSION!r}')
    if m.get("game") != defs.GAME_NAME:
        problems.append(f'  game {m.get("game")!r} != '
                        f'defs.GAME_NAME {defs.GAME_NAME!r}')
    if problems:
        sys.exit("archipelago.json disagrees with defs.py:\n"
                 + "\n".join(problems)
                 + f"\n\n  {MANIFEST}")
    return m


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


def bundle_third_party():
    """Unpack the vendored components into the bundle, with their licenses.

    The player gets UndertaleModTool already extracted under build/utmt/ and
    the DLL already sitting next to where data.win will be, which is exactly
    the layout the old instructions asked them to assemble by hand.

    third-party/ carries the licenses and -- the part that is not optional --
    the UndertaleModTool source archive. UndertaleModCli.exe is GPLv3, so the
    Corresponding Source has to reach whoever receives the binary. Shipping it
    inside the same zip keeps that true no matter where the zip is rehosted.
    """
    if vendor.unpack_utmt(os.path.join(PATCHER_DIR, "build", "utmt")) is None:
        sys.exit(f"no UndertaleModTool zip in {THIRD_PARTY}")
    if vendor.unpack_dll(PATCHER_DIR) is None:
        sys.exit(f"no gm-apclientpp zip in {THIRD_PARTY}")

    dst = os.path.join(PATCHER_DIR, "third-party")
    os.makedirs(dst, exist_ok=True)
    shutil.copy2(os.path.join(THIRD_PARTY, "README.md"),
                 os.path.join(dst, "README.md"))
    for sub, names in (
            ("UndertaleModTool", ("LICENSE.txt",)),
            ("gm-apclientpp", ("LICENSE",))):
        os.makedirs(os.path.join(dst, sub), exist_ok=True)
        for n in names:
            shutil.copy2(os.path.join(THIRD_PARTY, sub, n),
                         os.path.join(dst, sub, n))

    src_zip = vendor.one_archive(vendor.UTMT_SRC_ZIP)
    if src_zip is None:
        sys.exit(
            "The UndertaleModTool source archive is missing from\n"
            f"  {os.path.join(THIRD_PARTY, 'UndertaleModTool')}\n"
            "It is the Corresponding Source for the GPL binary this\n"
            "bundle ships and cannot be left out. See\n"
            "third-party/README.md.")
    shutil.copy2(src_zip, os.path.join(dst, "UndertaleModTool",
                                       os.path.basename(src_zip)))


def write_build_stamp():
    """Stamp the bundle with when it was built and from what.

    Every file in here is copied with copy2, which preserves the SOURCE file's
    mtime -- so a file whose content has not changed in weeks still carries a
    weeks-old date inside a bundle built a minute ago. That is correct and also
    thoroughly misleading: it makes an up-to-date bundle look stale, and gives
    no way at all to spot a genuinely stale one. This is the one file whose
    date means what it looks like it means.
    """
    when = datetime.datetime.now().astimezone().strftime("%Y-%m-%d %H:%M %Z")
    rev = "unknown revision"
    try:
        r = subprocess.run(["git", "-C", ROOT, "describe", "--always", "--dirty"],
                           capture_output=True, text=True, timeout=10)
        if r.returncode == 0 and r.stdout.strip():
            rev = r.stdout.strip()
    except (OSError, subprocess.SubprocessError):
        pass
    body = (
        "Built by mod/build/package.py. build.py prints the first line on\n"
        "every run, so if you are unsure whether a copy of this bundle is\n"
        "current, that is where to look.\n"
        "\n"
        "Every other file here keeps its original modification date, which is\n"
        "the date its CONTENT last changed -- patch.bat being older than this\n"
        "file just means patch.bat has not needed changing. Only this date\n"
        "tracks the bundle.\n")
    with open(os.path.join(PATCHER_DIR, "BUILD.txt"), "w",
              encoding="utf-8", newline="\n") as f:
        f.write(f"v{defs.WORLD_VERSION} - {when} ({rev})\n\n")
        f.write(body)


def build_patcher():
    if os.path.isdir(PATCHER_DIR):
        shutil.rmtree(PATCHER_DIR)
    os.makedirs(PATCHER_DIR)

    copy_tree(os.path.join(MOD, "gml"), os.path.join(PATCHER_DIR, "gml"))
    dst_build = os.path.join(PATCHER_DIR, "build")
    os.makedirs(dst_build, exist_ok=True)
    for f in ("gen_gml.py", "patch.csx", "build.py", "vendor.py"):
        shutil.copy2(os.path.join(HERE, f), os.path.join(dst_build, f))
    # defs.py lives in the apworld package (single source of truth); the bundle
    # has no apworld dir, so drop a copy where gen_gml.py will find it.
    shutil.copy2(os.path.join(APWORLD_SRC, "defs.py"),
                 os.path.join(dst_build, "defs.py"))

    shutil.copy2(os.path.join(HERE, "patch.bat"),
                 os.path.join(PATCHER_DIR, "patch.bat"))

    bundle_third_party()

    write_build_stamp()

    tmpl = os.path.join(ROOT, "archipelago.ini.template")
    if os.path.isfile(tmpl):
        shutil.copy2(tmpl, PATCHER_DIR)

    # The player-facing README lives in its own .txt rather than a Python
    # string literal: it is full of Windows paths, and backslash escapes inside
    # a source literal silently mangle them.
    shutil.copy2(os.path.join(HERE, "player_README.txt"),
                 os.path.join(PATCHER_DIR, "README.txt"))

    # Flat archive, deliberately: the install step is "extract this into your
    # game folder", which only works if build/ and gml/ land at the top level
    # rather than inside a wrapper directory.
    zip_path = os.path.join(OUT, "vdh-ap-patcher.zip")
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
        for base, _dirs, files in os.walk(PATCHER_DIR):
            for fn in files:
                full = os.path.join(base, fn)
                arc = os.path.relpath(full, PATCHER_DIR)
                z.write(full, arc.replace(os.sep, "/"))
    return zip_path


def main():
    os.makedirs(OUT, exist_ok=True)
    check_manifest()
    print(f"version: {defs.WORLD_VERSION} (needs Archipelago "
          f"{defs.MIN_AP_VERSION}+)")
    aw = build_apworld()
    pz = build_patcher()
    print(f"  {os.path.relpath(aw, ROOT)}")
    print(f"  {os.path.relpath(PATCHER_DIR, ROOT)}/")
    print(f"  {os.path.relpath(pz, ROOT)}")
    print("\nout/ built. No patched game files included by design -- players "
          "patch their own copy.")


if __name__ == "__main__":
    main()
