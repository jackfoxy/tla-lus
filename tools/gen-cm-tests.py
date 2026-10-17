#!/usr/bin/env python3
"""The CommunityModules override differential (R4.2b).

The Examples reach CommunityModules operators that the pin answers through a
JAVA OVERRIDE from the CommunityModules jar (`tlc2.overrides.*`), while this
port evaluates their TLA+ bodies. An override can disagree with its own body
(ordering, laziness, error text), and the pin's answer is the override's, so
each reached override is measured against the port here.

  desk/test-data/cmops/<case>/A.tla, A.txt
      a root module EXTENDing the community modules under test, its arity-0
      definitions the probes; A.txt its config.
  desk/test-data/cmops/<case>/golden-ops.txt
      ModuleOpDump with the deps jar on the classpath (so the overrides are
      bound, as the BINDINGS block shows): the EVAL projection.
  desk/tests/lib/cmops.hoon
      one arm per case: `+project-defs-with:check` over the root plus the
      jar's own sources of every community module the root reaches, compared
      line by line with the golden. A definition the port answers differently
      on purpose is in SKIPS with its reason.

The community sources are read from the pinned deps jar at generation time,
never from the CommunityModules checkout (whose overrides are newer than the
jar's). Never edit generated files.
"""
import re
import subprocess
import tempfile
import zipfile
from pathlib import Path

REPO = Path("/mnt/mars/gitrepos/tla-lus")
JAR = Path("/mnt/mars/gitrepos/tlaplus/tlatools/org.lamport.tlatools/dist/tla2tools.jar")
DEPS = Path("/mnt/mars/gitrepos/r4-deps/CommunityModules-deps.jar")
CP = f"{JAR}:{REPO}/tools/oracle/build:{DEPS}"
CASES = REPO / "desk/test-data/cmops"
OUT = REPO / "desk/tests/lib/cmops.hoon"

# the port's vendored StandardModules (lib/stdmods): never sent as sources
STANDARD = {
    "Bags", "FiniteSets", "Integers", "Json", "Naturals", "Randomization",
    "RealTime", "Reals", "Sequences", "TLC", "TLCExt", "Toolbox",
    "_DotTrace", "_JsonTrace", "_Possible", "_TLAPlusCounterExample",
    "_TLCActionTrace", "_TLCTESpec", "_TLCTrace", "_TLCTracePlain",
}

# (case, definition) -> why the port answers differently on purpose
SKIPS: dict = {
    ("cm-dyadic", "AddH"): "record field order: the approved string order (tlc-value-order)",
    ("cm-dyadic", "AddZ"): "record field order: the approved string order (tlc-value-order)",
    ("cm-dyadic", "HalfOne"): "record field order: the approved string order (tlc-value-order)",
    ("cm-svg", "ElemStr"): "attribute order is the record's field order: the approved string order (tlc-value-order)",
    ("cm-svg", "GroupStr"): "attribute order is the record's field order: the approved string order (tlc-value-order)",
    ("cm-svg", "Ring0"): "refused by name: java.lang.Math.cos/sin doubles",
    ("cm-svg", "Ring1"): "refused by name: java.lang.Math.cos/sin doubles",
    ("cm-svg", "Ring3"): "refused by name: java.lang.Math.cos/sin doubles",
    ("cm-statistics", "CSPass"): "refused by name: Apache Commons Math chi-square over doubles",
    ("cm-statistics", "CSFail"): "refused by name: Apache Commons Math chi-square over doubles",
    ("cm-vectorclocks", "CO"): "refused by name: the override's order is java.util.HashMap's",
}


def jar_sources() -> dict:
    with zipfile.ZipFile(DEPS) as z:
        return {Path(n).stem: z.read(n).decode()
                for n in z.namelist()
                if n.endswith(".tla") and "/" not in n}


def strip(t: str) -> str:
    t = re.sub(r"\(\*.*?\*\)", "", t, flags=re.S)
    return re.sub(r"\\\*.*", "", t)


def refs(t: str) -> list:
    t = strip(t)
    out = []
    for m in re.finditer(r"EXTENDS([^\n]*(?:\n\s+[A-Za-z_, ]+)*)", t):
        out += re.findall(r"[A-Za-z_][A-Za-z0-9_]*", m.group(1))
    out += re.findall(r"INSTANCE\s+([A-Za-z_][A-Za-z0-9_]*)", t)
    return out


def closure(root: str, src: dict) -> list:
    """The community modules `root` reaches, dependency-first."""
    seen, order = set(), []

    def walk(text: str) -> None:
        for n in refs(text):
            if n in seen or n in STANDARD or n not in src:
                continue
            seen.add(n)
            walk(src[n])
            order.append(n)
    walk(root)
    return order


def hcord(s: str) -> str:
    return (s.replace("\\", "\\\\").replace("'", "\\'")
             .replace("\n", "\\0a").replace("\t", "\\09").replace("\r", "\\0d"))


def htape(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"').replace("{", "\\{") + '"'


def golden(case: Path) -> str:
    with tempfile.TemporaryDirectory() as td:
        (Path(td) / "A.tla").write_text((case / "A.tla").read_text())
        (Path(td) / "A.cfg").write_text((case / "A.txt").read_text())
        r = subprocess.run(["java", "-cp", CP, "ModuleOpDump", "A"],
                           cwd=td, capture_output=True, text=True)
    (case / "golden-ops.txt").write_text(r.stdout)
    return r.stdout


def main() -> int:
    src = jar_sources()
    arms, n = [], 0
    for case in sorted(CASES.iterdir()):
        if not (case / "A.tla").exists():
            continue
        gold = golden(case)
        if "EVAL\n" not in gold:
            raise SystemExit(f"{case.name}: the oracle failed to load the case")
        root = (case / "A.tla").read_text()
        mods = closure(root, src)
        skips, lines = [], []
        for line in gold.partition("EVAL\n")[2].splitlines():
            if not line.strip():
                continue
            name, _, rest = line.partition(" ")
            if (case.name, name) in SKIPS:
                skips.append((name, SKIPS[(case.name, name)]))
                continue
            rest = re.sub(r"^! (EC\d+ )?\w+(Exception|Error): ",
                          lambda m: "! " + (m.group(1) or ""), rest)
            lines.append(f"{name} {rest}")
            n += 1
        slug = case.name.replace("cm-", "")
        arms.append(f"++  test-{slug}")
        arms.append(f"  ::  sources: {', '.join(mods)} (the pinned deps jar's)")
        for nm, why in skips:
            arms.append(f"  ::  {nm}: {why}")
        arms.append("  %+  expect-eq")
        arms.append("    !>  ^-  (list tape)")
        if lines:
            arms.append("    :~  " + "\n        ".join(htape(l) for l in lines))
            arms.append("    ==")
        else:
            arms.append("    ~")
        arms.append("  !>")
        arms.append("  %:  project-defs-with:check")
        arms.append(f"    '{hcord(root)}'")
        arms.append(f"    '{hcord((case / 'A.txt').read_text())}'")
        arms.append("    :~  " + "\n        ".join(
            f"['{m}' {m.lower()}-src]" for m in mods) + "\n    ==")
        arms.append("    " + ("~[" + " ".join(f"'{nm}'" for nm, _ in skips) + "]"
                              if skips else "~"))
        arms.append("  ==")
        arms.append("::")
    used = sorted({m for case in sorted(CASES.iterdir()) if (case / "A.tla").exists()
                   for m in closure((case / "A.tla").read_text(), src)})
    for m in used:
        arms.append(f"++  {m.lower()}-src")
        arms.append(f"  '{hcord(src[m])}'")
        arms.append("::")
    head = [
        "::  GENERATED by tools/gen-cm-tests.py — do not edit.",
        "::",
        "::  The CommunityModules override differential (R4.2b): every arity-0",
        "::  definition of every cmops case, evaluated by this port (the operators'",
        "::  TLA+ bodies, or a native override) and compared against the pin with",
        "::  the CommunityModules deps jar's Java overrides bound",
        "::  (desk/test-data/cmops/*/golden-ops.txt, captured by ModuleOpDump).",
        "::  The community module sources below are the jar's own.",
        "/+  *test",
        "/=  check  /lib/check",
        "|%",
    ]
    OUT.write_text("\n".join(head + arms + ["--"]) + "\n")
    print(f"{n} cmops definitions")
    print(f"TOTAL {sum(1 for c in CASES.iterdir() if (c / 'A.tla').exists())}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
