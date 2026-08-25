"""Unpacking the vendored third-party archives.

The zips in third-party/ are byte-for-byte what upstream published, so they are
what the repository stores and what a release ships; the unpacked forms are
build outputs and are gitignored. Both build.py and package.py go through here
so there is exactly one place that knows the layout.

third-party/ sits one level up from this file in both layouts that matter:
mod/build/vendor.py in the dev repo, <game>/build/build.py in the bundle.
"""
import glob
import os
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
THIRD_PARTY = os.path.abspath(os.path.join(HERE, "..", "third-party"))

UTMT_ZIP = os.path.join(THIRD_PARTY, "UndertaleModTool", "UTMT_CLI_*-Windows.zip")
# Not a build input -- the GPL Corresponding Source for UTMT_ZIP, which
# package.py copies into the bundle. See third-party/README.md.
UTMT_SRC_ZIP = os.path.join(THIRD_PARTY, "UndertaleModTool",
                            "UndertaleModTool-*-source.zip")
DLL_ZIP = os.path.join(THIRD_PARTY, "gm-apclientpp", "gm-apclientpp-*-win32.zip")

UTMT_EXE = "UndertaleModCli.exe"
DLL_NAME = "gm-apclientpp.dll"


def one_archive(pattern):
    """The single archive matching pattern, or None.

    Deliberately strict about finding more than one: two UTMT zips in the tree
    means a version bump left the old one behind, and silently picking either
    would make builds depend on glob order.
    """
    hits = sorted(glob.glob(pattern))
    if len(hits) > 1:
        raise SystemExit(
            "third-party/ has more than one archive matching\n"
            f"  {os.path.relpath(pattern, THIRD_PARTY)}\n"
            "Leave exactly one version in place:\n  "
            + "\n  ".join(os.path.basename(h) for h in hits))
    return hits[0] if hits else None


def unpack_utmt(dest_dir):
    """Ensure UndertaleModCli.exe exists in dest_dir; return its path or None.

    Extraction is skipped when the exe is already there, so this is cheap to
    call on every build -- the archive unpacks to ~130 MB.
    """
    exe = os.path.join(dest_dir, UTMT_EXE)
    if os.path.isfile(exe):
        return exe
    src = one_archive(UTMT_ZIP)
    if not src:
        return None
    print(f"unpacking {os.path.basename(src)} ...")
    os.makedirs(dest_dir, exist_ok=True)
    with zipfile.ZipFile(src) as z:
        z.extractall(dest_dir)
    return exe if os.path.isfile(exe) else None


def unpack_dll(dest_dir):
    """Ensure gm-apclientpp.dll exists in dest_dir; return its path or None."""
    dll = os.path.join(dest_dir, DLL_NAME)
    if os.path.isfile(dll):
        return dll
    src = one_archive(DLL_ZIP)
    if not src:
        return None
    print(f"unpacking {os.path.basename(src)} ...")
    os.makedirs(dest_dir, exist_ok=True)
    with zipfile.ZipFile(src) as z:
        z.extract(DLL_NAME, dest_dir)
    return dll if os.path.isfile(dll) else None
