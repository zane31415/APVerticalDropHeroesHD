# Third-party components

Everything in this directory belongs to somebody else. The files are **exactly
as downloaded from their upstream release pages, byte for byte** -- nothing
here has been edited, recompiled or repackaged by this project. They are
vendored so that a player needs one download and one double-click, and so that
the source that goes with the GPL binary travels with it.

This project's own code (the GML, the patcher, the Archipelago world) is MIT;
see [LICENSE](../../LICENSE). That license does not cover anything in here.

The patcher invokes `UndertaleModCli.exe` as a separate process. Nothing is
linked against it, and the GPL therefore applies to that component alone -- it
is mere aggregation under GPLv3 section 5.

---

## UndertaleModTool 0.9.1.2 -- GPL-3.0-only

| | |
|---|---|
| Upstream | <https://github.com/UnderminersTeam/UndertaleModTool> |
| Release | <https://github.com/UnderminersTeam/UndertaleModTool/releases/tag/0.9.1.2> |
| Copyright | the Underminers team and contributors |
| License | GPL-3.0, verbatim in `UndertaleModTool/LICENSE.txt` |

| file | sha256 |
|---|---|
| `UndertaleModTool/UTMT_CLI_v0.9.1.2-Windows.zip` | `e17637750c9c5bd074e799de99e69e1aa58c19cbbd9cbaa8868bbc387da04345` |
| `UndertaleModTool/UndertaleModTool-0.9.1.2-source.zip` | `c594e51e77199332af1815fc9c83142b08fec2830310bf9f1458bf9b231ea4ba` |

`UTMT_CLI_v0.9.1.2-Windows.zip` is the official CLI build; the patcher unpacks
it into `mod/build/utmt/` and runs `UndertaleModCli.exe` from there.

`UndertaleModTool-0.9.1.2-source.zip` is the **Corresponding Source** for that
binary, being the source archive of the same `0.9.1.2` tag it was built from.
It sits here so that anyone who receives the binary from us -- from this
repository or from a release zip -- receives the source in the same place, as
GPLv3 section 6 requires. It is not a build input; nothing reads it. Do not
delete it, and if the pinned version ever changes, replace **both** files
together so binary and source keep matching.

The CLI build is a self-contained .NET publish, so the zip also carries the
.NET runtime and a handful of MIT/Apache-2.0 libraries alongside Underminers'
own code. Those are separately licensed and fall under GPLv3's System Library
exception; upstream ships them in this same archive.

## gm-apclientpp v0.4.9-3 (win32) -- MIT

| | |
|---|---|
| Upstream | <https://github.com/black-sliver/gm-apclientpp> |
| Release | <https://github.com/black-sliver/gm-apclientpp/releases/tag/v0.4.9-3> |
| Copyright | (c) 2024 black-sliver, ThatOneGuy27, LeonarthCG |
| License | MIT, verbatim in `gm-apclientpp/LICENSE` |

| file | sha256 |
|---|---|
| `gm-apclientpp/gm-apclientpp-v0.4.9-3-win32.zip` | `9ab841592bfce4cb86bb3dd05d3bab73c4f4f7b04f3ce828235646972b47ba52` |

The 32-bit build, because the GameMaker 1.4 runner is 32-bit; the 64-bit build
will not load. The patcher unpacks `gm-apclientpp.dll` next to `data.win`, and
the patched game loads it at runtime.

As its license notes, the binary contains parts of OpenSSL (Apache-2.0) and
other software. See <https://www.openssl.org/source/apache-license-2.0.txt> and
the subprojects listed at <https://github.com/black-sliver/lua-apclientpp/>.
