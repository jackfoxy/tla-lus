#!/usr/bin/env python3
"""R4.0b: one fixture per classifier defect, each of which must FAIL under the
old rule and PASS under the repaired one in `gen-tier2-tests.py`.

The old rule is kept here verbatim (`old_*`) for exactly that purpose: a fix
is not proved until something it fixes is shown to have been broken (L3). Run
by `tools/tier2.py --check`.

  tools/test-tier2-classify.py      exit 0 iff every fixture bites
"""
import importlib.util
import re
import sys
import tempfile
from pathlib import Path

GEN = Path(__file__).resolve().parent / "gen-tier2-tests.py"


def load():
    sys.dont_write_bytecode = True        # tools/__pycache__ is tracked
    s = importlib.util.spec_from_file_location("gen_tier2", GEN)
    m = importlib.util.module_from_spec(s)
    s.loader.exec_module(m)
    return m


# ------------------------------------------------- the rule before R4.0b ---
def old_module_refs(text: str) -> set:
    refs = set()
    for m in re.findall(r"^\s*EXTENDS\s+(.+)$", text, re.M):
        refs |= {s.strip() for s in m.split(",") if s.strip()}
    refs |= set(re.findall(r"\bINSTANCE\s+([A-Za-z_][A-Za-z0-9_]*)", text))
    return refs


def old_classify(g, text: str, local: set, has_cfg: bool):
    if g.is_pluscal(text):
        return "excluded", "pluscal"
    refs = old_module_refs(text)
    unresolved = {r for r in refs if r not in g.VENDORED and r not in local}
    if unresolved:
        return "excluded", "module:" + ",".join(sorted(unresolved))
    if has_cfg and refs <= g.CHECK_MODS:
        return "check", ""
    if has_cfg:
        return "sany", "check-excluded:" + ",".join(
            sorted(refs - g.CHECK_MODS - {""}))
    return "sany", ""


def old_has_model(models) -> bool:
    return any(mo.get("mode") == "exhaustive search" for mo in models)


# ------------------------------------------------------------- fixtures ---
# (name, {file: text}, root module, manifest models, expected new class)
FIXTURES = [
    ("1-comments-and-multiline-extends", {
        "Spec": "---- MODULE Spec ----\n"
                "EXTENDS Naturals, \\* the INSTANCE of nothing\n"
                "        FiniteSets\n"
                "(* EXTENDS Functions *)\n"
                "VARIABLE x\nInit == x = 0\nNext == x' = x\n====\n",
    }, "Spec", [{"mode": "exhaustive search"}], "check"),
    ("1b-multiline-extends-alone", {
        "Spec": "---- MODULE Spec ----\n"
                "EXTENDS Naturals,\n"
                "        Functions\n"
                "VARIABLE x\nInit == x = 0\nNext == x' = x\n====\n",
    }, "Spec", [{"mode": "exhaustive search"}], "excluded"),
    ("2-nested-module", {
        "Spec": "---- MODULE Spec ----\nEXTENDS Naturals\n"
                "---- MODULE Inner ----\nC == 1\n====\n"
                "I == INSTANCE Inner\n"
                "VARIABLE x\nInit == x = I!C\nNext == x' = x\n====\n",
    }, "Spec", [{"mode": "exhaustive search"}], "check"),
    ("3-local-closure", {
        "MCSpec": "---- MODULE MCSpec ----\nEXTENDS Spec\n====\n",
        "Spec": "---- MODULE Spec ----\nEXTENDS Naturals, Functions\n"
                "VARIABLE x\nInit == x = 0\nNext == x' = x\n====\n",
    }, "MCSpec", [{"mode": "exhaustive search"}], "excluded"),
    ("4-simulate-is-a-model", {
        "Spec": "---- MODULE Spec ----\nEXTENDS Naturals\n"
                "VARIABLE x\nInit == x = 0\nNext == x' = x\n====\n",
    }, "Spec", [{"mode": {"simulate": {"traceCount": 100}}}], "check"),
]


def main() -> int:
    g = load()
    fails = 0
    for name, files, root, models, want in FIXTURES:
        with tempfile.TemporaryDirectory() as d:
            byname = {}
            for stem, text in files.items():
                p = Path(d) / f"{stem}.tla"
                p.write_text(text)
                byname[stem] = p
            text = files[root]
            modes = {g.manifest_mode(mo) for mo in models}
            new = g.classify(text, g.ext_closure(root, byname),
                             bool(modes - {"symbolic"}))[0]
            old = old_classify(g, text, set(files), old_has_model(models))[0]
        good, bites = new == want, old != want
        fails += not (good and bites)
        print(f"  {'ok  ' if good and bites else 'FAIL'}  {name}: new={new} "
              f"old={old} want={want}"
              + ("" if bites else "  <- the old rule passes: fixture does not bite"))
    print("classifier fixtures: " + ("all bite" if not fails else f"{fails} FAILED"))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
