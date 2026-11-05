#!/usr/bin/env python3
"""Assert R4's acceptance sentence, clause by clause (R4.5.2).

The sentence is `R4-examples-work-breakdown-r16.md` §"Acceptance sentence"
(agreed 2026-10-08): R4 = the tlaplus-Examples corpus at the pin, PlusCal
excluded. Every clause is computed from a file; none is asserted by hand.

  1 parse       every parse.json module's `%analyze` verdict = pinned SANY's
  2 small       each of the 127 small models reports the PIN's outcome:
                verdict, distinct and depth, and generated for a success
                (the generated count at a violation is the harness's
                recorded normalization, compatibility.md); every other row
                is in the recorded fallback or an approved refusal
                (desk/test-data/blackbox/r4-fallback.json, plan r16
                decision 2 A), or a violation whose counts follow an
                approved order difference (verdict and depth still the
                pin's)
  3 large       each of the 31 large models passes the smoke projection
                (`%limited %states` at the budget, or success, whose
                counts then meet clause 2's check)
  4 ledger      every ledger row terminal, none owed
  5 throughput  tier 3 REPORTED: report-only for R4 by the user's decision
                (2026-11-05), though the noise criterion now passes
  6 gates       release-gate.sh passes; the user-run full suite is ok=%.y
                and covers every test arm; the user-run Examples runner
                census covers every model -- both logs are required inputs
  7 black box   coverage.md's selection: every selected model through the
                wire reports its MANIFEST outcome (counts where the manifest
                records them and the run is exhaustive), exceptions as in
                clause 2; the 44 failure arms pass in the suite log and the
                7 exclusions carry reasons; one model through the documented
                dojo generator (a required log)
  8 unicode     every converted module: verdict = SANY's on the converted
                text, and the semantic graph = the ASCII original's

    tools/r4-acceptance.py --suite-log SUITE --examples-census C1 [C2 ...]
                           --dojo-log DOJO [--tier3-log T3] [--skip-gate]

Later census files override earlier ones row by row (a 900 s pass, then
the re-runs at 3,600 s). It does NOT touch r1-/r3-acceptance.py.

Exit 0 = ACCEPTED, 1 = not.
"""
import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
DESK = REPO / "desk"
BB = DESK / "test-data/blackbox"
EX = DESK / "test-data/tier2/examples"

clauses = []


def clause(name: str, held: bool, detail: str) -> None:
    clauses.append((name, held, detail))
    print(f"  {'HOLDS ' if held else 'FAILS '} {name}\n           {detail}")


def report(name: str, detail: str) -> None:
    """A measurement that is READ, not asserted. Never affects the verdict."""
    print(f"  REPORT {name}\n           {detail}")


def jsonl(path: Path) -> list:
    return [json.loads(l) for l in path.read_text().splitlines() if l.strip()]


def run(*cmd) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, capture_output=True, text=True)


# ------------------------------------------------------------------ inputs ---
def work() -> tuple:
    models = json.loads((BB / "models.json").read_text())["models"]
    parse = json.loads((BB / "parse.json").read_text())["parse"]
    return models, parse


def pin_table() -> dict:
    """model -> (pin result, (distinct, generated, depth) or None)"""
    out = {}
    for l in (EX / "pin-vs-manifest.txt").read_text().splitlines():
        if l.startswith("#") or not l.strip():
            continue
        f = [x.strip() for x in l.split("|")]
        nums = f[4].split("/")
        counts = None if "-" in nums else tuple(int(x) for x in nums)
        out[f[0]] = (f[2], counts)
    return out


def census(files: list) -> dict:
    rows = {}
    for f in files:
        for r in jsonl(f):
            rows[r["model"]] = r
    return rows


def sany_exits(sub: str) -> dict:
    return {str(p.relative_to(EX / sub))[:-4]: p.read_text().split("\n", 1)[0]
            for p in (EX / sub).rglob("*.txt")}


# ------------------------------------------------------------------ clauses ---
def c_parse(parse: list) -> None:
    exits = sany_exits("sany")
    rows = {r["module"]: r for r in jsonl(BB / "parse-census.txt")}
    bad = []
    for m in parse:
        mod = m["module"]
        pin_ok = exits.get(mod) == "SANY exit 0"
        r = rows.get(mod)
        if r is None:
            bad.append(f"{mod}: no census row")
        elif (r["class"] == "agree") != pin_ok:
            bad.append(f"{mod}: port {r['class']}, pin {exits.get(mod)}")
    clause(f"1 parse: {len(parse)} modules, `%analyze` verdict = pinned SANY",
           not bad, f"parse-census.txt: {len(parse) - len(bad)}/{len(parse)} agree"
           + ("" if not bad else "; " + "; ".join(bad[:5])))


def counts_of(r: dict) -> tuple:
    return (r.get("distinct"), r.get("generated"), r.get("depth"))


def meets_pin(r: dict, pin: tuple) -> tuple:
    """(held, why) for one completed row against the pin's projection"""
    res, pc = pin
    if r["status"] != res:
        return False, f"{r['status']} where the pin gives {res}"
    if pc is None:
        return True, ""
    d, g, dep = counts_of(r)
    if res == "success":
        ok = (d, g, dep) == pc
    else:
        ok = (d, dep) == (pc[0], pc[2])
    return ok, "" if ok else f"{d}/{g}/{dep} where the pin gives {pc[0]}/{pc[1]}/{pc[2]}"


def c_small(models: list, pin: dict, rows: dict, fb: dict) -> None:
    small = [m for m in models if m["size"] == "small"]
    timeb = {x["model"] for x in fb["time_bound"]}
    notrun = {x["model"] for x in fb["not_run"]}
    refusals = {x["model"]: x for x in fb["approved_refusals"]}
    ordered = {x["model"] for x in fb.get("order_dependent", [])}
    eq, recorded, bad = 0, 0, []
    for m in small:
        mod = m["model"]
        r = rows.get(mod)
        if mod in ordered and r is not None:
            #  counts at a violation follow the approved value-order
            #  difference; the verdict and the depth must still be the pin's
            res, pc = pin[mod]
            if r["status"] == res and (pc is None or r.get("depth") == pc[2]):
                recorded += 1
            else:
                bad.append(f"{mod}: {r['status']} depth {r.get('depth')} (order-dependent)")
            continue
        if mod in refusals:
            want = refusals[mod]["reason"]
            if r and r["status"] == "error" and r.get("reason", "").startswith(want):
                recorded += 1
            else:
                bad.append(f"{mod}: expected the approved refusal ({want})")
            continue
        if r is None:
            if mod in notrun:
                recorded += 1
            else:
                bad.append(f"{mod}: no census row")
            continue
        if r["status"].startswith("limited") or r["status"] in ("too slow", "runaway"):
            if mod in timeb:
                recorded += 1
            else:
                bad.append(f"{mod}: {r['status']}, not in the recorded fallback")
            continue
        held, why = meets_pin(r, pin[mod])
        if held:
            eq += 1
        else:
            bad.append(f"{mod}: {why}")
    clause(f"2 small: {len(small)} models report the pin's outcome, or a recorded "
           "exception", not bad,
           f"{eq} = pin, {recorded} recorded (fallback {len(timeb)} time-bound + "
           f"{len(notrun)} not run, {len(refusals)} approved refusals, "
           f"{len(ordered)} order-dependent counts)"
           + ("" if not bad else f"; {len(bad)} other: " + "; ".join(bad[:5])))
    if "specifications/ewd840/EWD840.cfg" in rows:
        report("2 small: upstream CI's own skip",
               "ewd840/EWD840.cfg run and reported: "
               + rows["specifications/ewd840/EWD840.cfg"]["status"])


def c_large(models: list, pin: dict, rows: dict) -> None:
    large = [m for m in models if m["size"] == "large"]
    ok, bad = 0, []
    for m in large:
        mod = m["model"]
        r = rows.get(mod)
        if r is None:
            bad.append(f"{mod}: no census row")
        elif r["status"] == "limited states":
            ok += 1
        elif r["status"] in ("success", "safety failure", "liveness failure",
                             "deadlock failure"):
            #  the pin smoke-ran most large models (no counts): a completed
            #  run then meets the MANIFEST's verdict and recorded counts
            pres, pc = pin.get(mod, ("", None))
            if pc is not None:
                held, why = meets_pin(r, (pres, pc))
            else:
                want = tuple(m.get(k) for k in ("distinctStates", "totalStates",
                                                "stateDepth"))
                got = counts_of(r)
                held = r["status"] == m["expected"] and all(
                    w is None or w == g for w, g in zip(want, got))
                why = "" if held else (f"{r['status']} {got[0]}/{got[1]}/{got[2]} "
                                       f"where the manifest says {m['expected']} "
                                       f"{want[0]}/{want[1]}/{want[2]}")
            ok += held
            if not held:
                bad.append(f"{mod}: {why}")
        else:
            bad.append(f"{mod}: {r['status']}")
    clause(f"3 large: {len(large)} models pass the smoke projection", not bad,
           f"{ok}/{len(large)}" + ("" if not bad else "; " + "; ".join(bad[:5])))
    report("3 large: upstream's skip",
           "KnuthYao/SimKnuthYao.cfg is not in the work list (mirrored)")


def c_ledger() -> None:
    r = run(sys.executable, str(REPO / "tools/check-parity.py"), "--check")
    owed = re.search(r"still owed \(partial/absent/oracle-only\): (\d+)", r.stdout)
    rows = re.search(r"terminal \(parity/approved-difference/replaced/excluded\): (\d+)",
                     r.stdout)
    held = r.returncode == 0 and owed is not None and owed.group(1) == "0"
    clause("4 ledger: every row terminal, none owed", held,
           f"{rows.group(1) if rows else '?'} terminal, "
           f"{owed.group(1) if owed else '?'} owed")


def r_tier3(log: Path | None) -> None:
    if log is None or not log.exists():
        report("5 throughput (tier 3)",
               "no --tier3-log. REPORT-ONLY for R4 by the user's decision "
               "(2026-11-05), although R2.8.1a's noise criterion now passes on "
               "all three legs (warm 4.5%, fresh boot 3.0%, rebuild 3.4%; "
               "`live` alone spread 20.7%). Read, never asserted")
        return
    lines = [l for l in log.read_text(errors="replace").splitlines() if l.strip()]
    report("5 throughput (tier 3)", f"{log.name}: " + (lines[-1][:160] if lines else "empty"))


def suite_arms(text: str) -> tuple:
    ok = set(re.findall(r"^OK\s+(\S+)", text, re.M))
    failed = set(re.findall(r"^(?:FAILED|CRASHED)\s+(\S+)", text, re.M))
    verdict = re.findall(r"^ok=%\.([yn])", text, re.M)
    return ok, failed, verdict


def declared_arms() -> set:
    """every `++  test-` arm under desk/tests, as the runner names it"""
    out = set()
    for f in (DESK / "tests").rglob("*.hoon"):
        rel = "/tests/" + str(f.relative_to(DESK / "tests"))[:-5]
        for a in re.findall(r"^\+\+  (test-[a-z0-9-]+)", f.read_text(), re.M):
            out.add(f"{rel}/{a}")
    return out


def c_gates(skip: bool, suite: Path | None, ex_files: list, models: list,
            rows: dict, fb: dict) -> None:
    if skip:
        clause("6a release gate passes", False, "--skip-gate: not run, so not asserted")
    else:
        r = run("bash", str(REPO / "tools/release-gate.sh"))
        tail = [l for l in r.stdout.splitlines() if l.startswith("RELEASE GATE")]
        clause("6a release gate passes", r.returncode == 0,
               tail[0] if tail else "release-gate.sh produced no verdict")
    if suite is None or not suite.exists():
        clause("6b the user's full suite: ok=%.y, every arm", False,
               "no --suite-log: a required input")
    else:
        ok, failed, verdict = suite_arms(suite.read_text(errors="replace"))
        missing = declared_arms() - ok
        held = bool(verdict) and verdict[-1] == "y" and not failed and not missing
        clause("6b the user's full suite: ok=%.y, every arm", held,
               f"{suite.name}: ok=%.{verdict[-1] if verdict else '?'}, {len(ok)} OK, "
               f"{len(failed)} FAILED, {len(missing)} declared arms not run"
               + ("" if not missing else " (" + ", ".join(sorted(missing)[:3]) + ")"))
    if not ex_files:
        clause("6c the user's Examples runner census covers every model", False,
               "no --examples-census: a required input")
    else:
        notrun = {x["model"] for x in fb["not_run"]}
        missing = [m["model"] for m in models
                   if m["model"] not in rows and m["model"] not in notrun]
        clause("6c the user's Examples runner census covers every model", not missing,
               f"{len(rows)} rows from {len(ex_files)} file(s); "
               f"{len(missing)} of {len(models)} models missing"
               + ("" if not missing else " (" + ", ".join(missing[:3]) + ")"))


def c_blackbox(models: list, rows: dict, fb: dict, suite: Path | None,
               dojo: Path | None) -> None:
    cov = (BB / "coverage.md").read_text()
    sel = re.search(r"\*\*Corpus .*?\*\* (\d+) selected models", cov)
    arms = re.search(r"(\d+) arms, (\d+) withheld on a measured divergence, (\d+) excluded", cov)
    excluded = re.findall(r"^\| \S+ \| \S+ \| EXCLUDED \| (.+?) \|", cov, re.M)
    exc = ({x["model"] for x in fb["time_bound"]} | {x["model"] for x in fb["not_run"]}
           | {x["model"] for x in fb["approved_refusals"]})
    bad, agree = [], 0
    for m in models:
        mod = m["model"]
        if mod in exc:
            continue
        r = rows.get(mod)
        if r is None:
            bad.append(f"{mod}: no row")
            continue
        if m["size"] == "large" and r["status"] == "limited states":
            agree += 1
            continue
        if r["status"] != m["expected"]:
            bad.append(f"{mod}: {r['status']} where the manifest says {m['expected']}")
            continue
        exhaustive = m["mode"] == "exhaustive search" and r["status"] == "success"
        if exhaustive and m.get("distinctStates") is not None and \
                (r.get("distinct"), r.get("generated")) != (m["distinctStates"], m.get("totalStates")):
            bad.append(f"{mod}: {r.get('distinct')}/{r.get('generated')} where the "
                       f"manifest says {m['distinctStates']}/{m.get('totalStates')}")
            continue
        agree += 1
    n_sel = int(sel.group(1)) if sel else -1
    clause("7a black box: every selected model reports its manifest outcome",
           not bad and n_sel == len(models),
           f"selected {n_sel} = work list {len(models)}; {agree} agree, {len(exc)} "
           "recorded exceptions (clause 2's)"
           + ("" if not bad else f"; {len(bad)} other: " + "; ".join(bad[:5])))
    if suite is None or not suite.exists():
        clause("7b black box: the failure arms pass, exclusions carry reasons", False,
               "no --suite-log: a required input")
    else:
        ok, failed, _ = suite_arms(suite.read_text(errors="replace"))
        bb_ok = {a for a in ok if a.startswith("/tests/lib/blackbox/")}
        bb_bad = {a for a in failed if a.startswith("/tests/lib/blackbox/")}
        want = int(arms.group(1)) if arms else -1
        held = (arms is not None and len(bb_ok) == want and not bb_bad
                and len(excluded) == int(arms.group(3)) and all(e.strip() for e in excluded))
        clause("7b black box: the failure arms pass, exclusions carry reasons", held,
               f"{len(bb_ok)}/{want} blackbox arms OK, {len(bb_bad)} failed; "
               f"{len(excluded)} excluded with reasons"
               + (f" (+{arms.group(2)} withheld)" if arms and arms.group(2) != "0" else ""))
    if dojo is None or not dojo.exists():
        clause("7c one model through the documented dojo generator", False,
               "no --dojo-log: a required input")
    else:
        text = dojo.read_text(errors="replace")
        held = bool(re.search(r"No error has been found|success", text))
        clause("7c one model through the documented dojo generator", held,
               f"{dojo.name}: " + ("a successful run" if held else "no success in the log"))


def c_unicode(parse: list) -> None:
    exits = sany_exits("sany-unicode")
    a = {r["module"]: r for r in jsonl(BB / "parse-census-unicode.txt")}
    b = {r["module"]: r for r in jsonl(BB / "unicode-identity-census.txt")}
    bad = []
    for m in parse:
        mod = m["module"]
        pin_ok = exits.get(mod) == "SANY exit 0"
        ra, rb = a.get(mod), b.get(mod)
        if ra is None or (ra["class"] == "agree") != pin_ok:
            bad.append(f"{mod}: verdict")
        if rb is None or not (rb.get("same") and rb.get("unicode") == "accept"
                              and rb.get("ascii") == "accept"):
            bad.append(f"{mod}: graph")
    clause(f"8 unicode: {len(parse)} converted modules, verdict = SANY and the "
           "graph = the ASCII original's", not bad,
           f"parse-census-unicode.txt {len(a)} rows, unicode-identity-census.txt "
           f"{len(b)} rows" + ("" if not bad else "; " + "; ".join(bad[:5])))


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--suite-log", type=Path, default=None,
                    help="captured output of `-test /=tla-lus=/tests ~` (user-run)")
    ap.add_argument("--examples-census", type=Path, nargs="*", default=[],
                    help="tools/examples.py --run census file(s), later overriding earlier")
    ap.add_argument("--dojo-log", type=Path, default=None,
                    help="captured dojo output of one model through the documented generator")
    ap.add_argument("--tier3-log", type=Path, default=None,
                    help="captured tools/tier3-report.py output (REPORTED)")
    ap.add_argument("--skip-gate", action="store_true",
                    help="do not run release-gate.sh (clause 6a then FAILS, by design)")
    a = ap.parse_args()

    models, parse = work()
    pin = pin_table()
    fb = json.loads((BB / "r4-fallback.json").read_text())
    rows = census(a.examples_census)

    print("R4 acceptance — each clause computed, none asserted by hand\n")
    c_parse(parse)
    if rows:
        c_small(models, pin, rows, fb)
        c_large(models, pin, rows)
    else:
        clause("2 small", False, "no --examples-census: a required input")
        clause("3 large", False, "no --examples-census: a required input")
    c_ledger()
    r_tier3(a.tier3_log)
    c_gates(a.skip_gate, a.suite_log, a.examples_census, models, rows, fb)
    c_blackbox(models, rows, fb, a.suite_log, a.dojo_log)
    c_unicode(parse)

    held = sum(1 for _, h, _ in clauses if h)
    print(f"\n{held}/{len(clauses)} clauses hold.")
    if held == len(clauses):
        print("\nR4 ACCEPTED.")
        print("  the 373 modules parse with the pin's verdict, in ASCII and in")
        print("  Unicode with identical graphs; the small models report the pin's")
        print("  outcome or a recorded exception; the large models pass the smoke")
        print("  projection; the ledger owes nothing; the gates, the user's suite")
        print("  and runner logs, and the black box hold. (Tier 3 is REPORTED.)")
        return 0
    print("\nR4 NOT ACCEPTED — the failing clauses above are the remaining work.")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
