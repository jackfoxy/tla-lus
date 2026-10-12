#!/usr/bin/env python3
"""R4.0d: run the tlaplus-Examples corpus through the %tla-lus agent's PUBLIC
wire on a live ship, and write a census.

The agent is driven exactly as a caller would drive it, over the pier's
`.urb/conn.sock` (tools/urbit_conn.py):
  * submit: an `%ovum` that hands Gall `[%deal sack %tla-lus %raw-poke
    %tla-lus-action <action>]`, so the action is clammed by the agent's own
    mark, as any poke would be;
  * observe: a conn `%peek` (no event, no compiled thread) scries
    `/x/job/<id>`, the documented path, every `--poll` seconds (default 10).
Sources come from Clay: `--stage` builds a desk, `%tla-ex`, holding the R4
corpus plus the three pinned library trees, with every path LOWERCASED (the
agent maps a module to `<lowercase name>.tla`, as util.FilenameToStream does).

The work list is R4.0f's ledger, `desk/test-data/blackbox/models.json` (with
the parse-only modules in `parse.json`); the
oracle there is the MANIFEST (clause 7). Clause 2's comparison against the
pin's projection reads the same census.

  tools/examples.py --stage DIR       write the %tla-ex desk tree to DIR
  tools/examples.py --run [--only S] [--census FILE] [--budget N]
  tools/examples.py --resume --census FILE

Long run: ask before starting it (R4 rule). The census file is append-only
JSON lines, so a run is resumable across ship restarts.
"""
import argparse
import json
import os
import re
import shutil
import signal
import sys
import threading
import time
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import urbit_conn as u  # noqa: E402

REPO = Path(__file__).resolve().parent.parent
EXAMPLES = Path("/mnt/mars/gitrepos/tlaplus-Examples")
DEPS = Path(os.environ.get("R4_DEPS", "/mnt/mars/gitrepos/r4-deps"))
TLAPM = Path("/mnt/mars/gitrepos/tlapm/library")
JAR = Path("/mnt/mars/gitrepos/tlaplus/tlatools/org.lamport.tlatools/dist/"
           "tla2tools.jar")
PIER = os.environ.get("PIER", "/mnt/mars/piers/tla-zod")
WORK = REPO / "desk/test-data/blackbox/models.json"
PARSE = REPO / "desk/test-data/blackbox/parse.json"
#  R4.0e: models that hit the wall cap, skipped until their bottleneck is
#  named (R4.P0b) and fixed; `--include-timed-out` runs them anyway
TIMED_OUT = REPO / "desk/test-data/blackbox/timed-out.json"


def timed_out_ids() -> set:
    if not TIMED_OUT.exists():
        return set()
    return {m["id"] for m in json.loads(TIMED_OUT.read_text())["models"]}
DESK = "tla-ex"

# the library roots, in CI's classpath order after the spec directory; a
# name tla2tools.jar's StandardModules already provide is NOT staged, since
# SANY's StandardModules pass finds the jar's copy first (R4.0a findings)
ROOTS = ("apalache", "community", "tlapm")


def std_names() -> set:
    with zipfile.ZipFile(JAR) as z:
        return {Path(n).stem for n in z.namelist()
                if n.startswith("tla2sany/StandardModules/") and n.endswith(".tla")}


def low(p: str) -> str:
    return p.lower()


# ------------------------------------------------------------------ stage ---
def stage(out: Path):
    """The %tla-ex desk: corpus dirs, three library roots, marks."""
    work = json.loads(WORK.read_text())
    work["parse"] = json.loads(PARSE.read_text())["parse"]
    std = std_names()
    dirs = sorted({os.path.dirname(m["module"])
                   for m in work["models"] + work["parse"]})
    n = 0
    for d in dirs:
        for f in sorted((EXAMPLES / d).iterdir()):
            if f.suffix in (".tla", ".cfg") and f.is_file():
                dst = out / low(d) / low(f.name)
                dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(f, dst)
                n += 1
    with zipfile.ZipFile(DEPS / "apalache/lib/apalache.jar") as z:
        for nm in z.namelist():
            if (nm.startswith("tla2sany/StandardModules/") and nm.endswith(".tla")
                    and Path(nm).stem not in std):
                (out / "apalache").mkdir(parents=True, exist_ok=True)
                (out / "apalache" / low(Path(nm).name)).write_bytes(z.read(nm))
                n += 1
    with zipfile.ZipFile(DEPS / "CommunityModules-deps.jar") as z:
        for nm in z.namelist():
            if nm.endswith(".tla") and "/" not in nm and Path(nm).stem not in std:
                (out / "community").mkdir(parents=True, exist_ok=True)
                (out / "community" / low(nm)).write_bytes(z.read(nm))
                n += 1
    for f in sorted(TLAPM.glob("*.tla")):
        if f.stem not in std:
            (out / "tlapm").mkdir(parents=True, exist_ok=True)
            shutil.copy2(f, out / "tlapm" / low(f.name))
            n += 1
    mar = out / "mar"
    mar.mkdir(parents=True, exist_ok=True)
    for m in ("tla", "cfg", "txt", "txt-diff", "mime", "kelvin", "bill"):
        src = REPO / f"desk/mar/{m}.hoon"
        if src.exists():
            shutil.copy2(src, mar / f"{m}.hoon")
    shutil.copy2(REPO / "desk/sys.kelvin", out / "sys.kelvin")
    (out / "desk.bill").write_text("~\n")
    print(f"staged {n} files under {out}")


# ------------------------------------------------------------ the request ---
YES, NO = 0, 1          # loobeans


def request(m: dict, case_ud: int, budget: int, wall: float):
    sdir = low(os.path.dirname(m["module"]))
    root = Path(m["module"]).stem
    cfg = [s for s in low(m["model"]).split("/")]
    cfg = cfg[:-1] + [cfg[-1][:-4], "cfg"]
    mode = m["mode"]
    if isinstance(mode, dict):
        cm = u.tup(u.cord("simulate"), 0, mode["simulate"], 100, NO)
    elif mode == "generate":
        cm = u.tup(u.cord("simulate"), 0, 1, 100, YES)
    else:
        cm = u.tup(u.cord("exhaustive"), YES, 0)
    op = u.tup(u.cord("check"),
               u.tup(NO, NO, NO, NO, 0, NO, 0, cm))
    roots = u.lst([u.path(*sdir.split("/"))] + [u.path(r) for r in ROOTS])
    src = u.tup(u.cord("clay"), 0, u.cord(DESK), (u.cord("ud"), case_ud),
                u.cord(root), u.unit(u.path(*cfg)), roots)
    large = m["size"] == "large"
    #  the agent-wide quotas bound these (`default-quota:job-lib`): 4 MB of
    #  source in flight across all jobs, 8 MB of artifacts retained -- which
    #  is why every result is deleted once its census row is written
    limits = u.tup(3_000_000, 1024,
                   budget if large else 10**9,      # max-states
                   10**7,                           # max-depth
                   #  max-time = the wall cap: `+step` checks it BEFORE any
                   #  work, so the slice behn re-fires after an interrupt ends
                   #  the job `%limited %time` instead of re-running (R4.0e)
                   int(wall) << 64,                 # max-time (@dr)
                   4_000_000, 0)
    return u.tup(op, src, limits, 0, 0)


def request_parse(mod: str, case_ud: int, secs: int = 600):
    """R4.1: an `%analyze` of one module (SANY's parse + semantic + level +
    lint), its imports resolved from the module's own directory and then the
    three library roots, as CI's classpath orders them"""
    sdir = low(os.path.dirname(mod))
    root = Path(mod).stem
    op = u.tup(u.cord("analyze"), u.tup(YES, YES, YES, YES))
    roots = u.lst([u.path(*sdir.split("/"))] + [u.path(r) for r in ROOTS])
    src = u.tup(u.cord("clay"), 0, u.cord(DESK), (u.cord("ud"), case_ud),
                u.cord(root), 0, roots)
    limits = u.tup(3_000_000, 1024, 10**9, 10**7, secs << 64, 4_000_000, 0)
    return u.tup(op, src, limits, 0, 0)


def run_parse(a) -> int:
    """R4.1: the parse census -- every module of `parse.json` through
    `%analyze`; the pin's SANY accepts all 373 (tier2/examples/sany)"""
    work = json.loads(PARSE.read_text())["parse"]
    if a.only:
        work = [m for m in work if a.only in m["module"]]
    census = Path(a.census or REPO / "desk/test-data/blackbox/parse-census.txt")
    done = set()
    if census.exists():
        done = {json.loads(l)["module"] for l in census.read_text().splitlines() if l}
    case = desk_case(1)
    print(f"%{DESK} at revision {case}; {len(work)} modules, {len(done)} done", flush=True)
    rid = 2
    for m in work:
        if STOP.is_set():
            print("stopped by SIGTERM, between modules", flush=True)
            return 0
        if m["module"] in done:
            continue
        jid = "p-" + re.sub(r"[^a-z0-9-]", "-", low(m["module"]))[-60:]
        t0 = time.time()
        submit(rid, jid, request_parse(m["module"], case, a.parse_secs))
        rid += 1
        while True:
            row = summarize(peek_job(rid, jid))
            rid += 1
            if row["status"] != "running":
                break
            time.sleep(a.poll)
        row.update({"module": m["module"], "proof": m["proof"],
                    "secs": round(time.time() - t0, 1)})
        row["class"] = "agree" if row["status"] == "success" else "disagree"
        with census.open("a") as f:
            f.write(json.dumps(row) + "\n")
        poke(rid, jid, u.tup(u.cord("delete-result"), u.cord(jid)))
        rid += 1
        print(f"{m['module']}: {row['class']} {row.get('reason') or row.get('error', {}).get('message', '')}"[:200], flush=True)
    return 0


# ------------------------------------------------------------------- wire ---
def poke(rid: int, jid: str, act):
    """Gall `%raw-poke`: the agent's own mark clams the noun."""
    deal = u.tup(u.cord("deal"), u.tup(0, 0, 0), u.cord("tla-lus"),
                 u.cord("raw-poke"), u.cord("tla-lus-action"), act)
    return u.send(PIER, u.tup(rid, u.cord("ovum"), u.cord("g"),
                              u.path("r4", jid), deal))


def submit(rid: int, jid: str, req):
    return poke(rid, jid, u.tup(u.cord("submit"), u.cord(jid), req))


def peek(rid: int, care: str, desk: str, *spur):
    """A conn `%peek` at `[%| %once care desk spur]`: arvo's +22 scry at
    `now`, answered without an event or a compiled thread. The reply is
    `[rid %peek (unit [%omen path cask])]`; returns the cask's noun."""
    #  a peek queues behind a running slice, so it may wait a long time;
    #  the watchdog, not this timeout, bounds a stuck slice
    r = u.send(PIER, u.tup(rid, u.cord("peek"),
                           u.tup(1, u.cord("once"), u.cord(care),
                                 u.cord(desk), u.path(*spur))), timeout=7200)
    _, (tag, res) = r
    if u.uncord(tag) != "peek" or res == 0:
        raise RuntimeError(f"conn: peek {care} {desk} {spur} failed")
    return res[1][1][1][1]


def peek_job(rid: int, jid: str):
    """The (unit job) noun, via the documented `/x/job/<id>` scry."""
    return peek(rid, "gx", "tla-lus", "job", jid, "noun")


def desk_case(rid: int) -> int:
    """`%tla-ex`'s current revision number (`ud` of the `%cw` cass)."""
    return peek(rid, "cw", DESK)[0]


# ----------------------------------------------------------------- decode ---
def unlist(n) -> list:
    out = []
    while n != 0:
        out.append(n[0])
        n = n[1]
    return out


def summarize(ujob) -> dict:
    """The census row for a (unit job) noun, CI's categories."""
    if ujob == 0:
        return {"status": "absent"}
    job = ujob[1]
    _req, (stage, (_pend, (_prog, (stats, (diags, (_arts, res)))))) = job
    errs = [d for d in unlist(diags) if u.uncord(d[1][0]) == "error"]
    row = {"stage": u.uncord(stage)}
    if errs:
        (fam, num), (_sev, (st, (msg, _))) = errs[0]
        row["error"] = {"code": f"{u.uncord(fam)} {num}", "stage": u.uncord(st),
                        "message": u.uncord(msg)[:400]}

    def st_of(s):
        g, (d, (q, (dep, _))) = s
        return {"generated": g, "distinct": d, "queued": q, "depth": dep}
    if res == 0:
        row["status"] = "running"
        row.update(st_of(stats))
        return row
    tag, rest = res[1]
    tag = u.uncord(tag)
    if tag == "ok":
        row["status"] = "success"
        row.update(st_of(rest))
    elif tag == "failed":
        row["status"] = "error"
        row["reason"] = u.uncord(rest)[:400]
    elif tag == "cancelled":
        row["status"] = "cancelled"
    elif tag == "limited":
        row["status"] = f"limited {u.uncord(rest[0])}"
        row.update(st_of(rest[1]))
    else:
        vio, s = rest
        v = u.uncord(vio[0])
        row["status"] = {"invariant": "safety failure", "deadlock": "deadlock failure",
                         "assumption": "assumption failure"}.get(v, "liveness failure")
        row["violation"] = v
        row.update(st_of(s))
    return row


#  R4.1 (crash #7): killing this process with a conn exchange outstanding
#  breaks the king's pipe and takes the ship down -- and a SUSPENDED client
#  stops reading, which does the same. SIGTERM instead asks for a stop: the
#  run finishes the model in hand and exits between models
STOP = threading.Event()
signal.signal(signal.SIGTERM, lambda *_: STOP.set())


def serf_pid() -> int:
    """The pier's serf (`.run work --snap-dir <pier>`), found through /proc."""
    for d in Path("/proc").iterdir():
        if not d.name.isdigit():
            continue
        try:
            argv = (d / "cmdline").read_bytes().split(b"\0")
        except OSError:
            continue
        if (len(argv) > 3 and argv[1] == b"work" and argv[2] == b"--snap-dir"
                and argv[3] == PIER.encode()):
            return int(d.name)
    raise RuntimeError(f"no serf for {PIER}")


class Watchdog(threading.Thread):
    """R4.0d/e: a Gall event cannot be preempted. Pokes and peeks queue
    behind it, and a cancel arriving on another driver is STARVED by behn,
    which re-fires the failed slice first, every time. So the watchdog never
    cancels. It interrupts: SIGINT (dojo `C-c`, `dig: intr`, the event
    aborts with no state change) whenever serf RSS passes `cap` MB or the run
    is past `hard` seconds, at most once per `gap` s. The request's
    `max-time` is the wall cap, so once it has passed, the re-fired slice
    ends the job `%limited %time` in `+step` before doing any work. Below
    the wall, repeated interrupts keep a memory runaway short of `meme`,
    which is what kills the ship."""

    def __init__(self, cap_mb: int, hard: float, gap: float = 60.0):
        super().__init__(daemon=True)
        self.cap, self.hard, self.gap = cap_mb, hard, gap
        self.t0, self.last = time.time(), 0.0
        self.pid = serf_pid()
        self.peak = 0
        self.sigints = []
        self.done = threading.Event()

    def rss_mb(self) -> int:
        for l in Path(f"/proc/{self.pid}/status").read_text().splitlines():
            if l.startswith("VmRSS:"):
                return int(l.split()[1]) // 1024
        return 0

    def cpu_ticks(self) -> int:
        f = Path(f"/proc/{self.pid}/stat").read_text().rsplit(")", 1)[1].split()
        return int(f[11]) + int(f[12])      # utime + stime

    def idle(self, secs: float = 3.0) -> bool:
        """Is the serf between events? (an interrupted slice can leave a job
        `running` with no behn timer left to resume it: an orphan)"""
        c0 = self.cpu_ticks()
        time.sleep(secs)
        return self.cpu_ticks() - c0 < 5

    def run(self):
        while not self.done.wait(5):
            r = self.rss_mb()
            self.peak = max(self.peak, r)
            el = time.time() - self.t0
            why = "rss" if r > self.cap else ("time" if el > self.hard else "")
            if why and time.time() - self.last > self.gap:
                self.last = time.time()
                os.kill(self.pid, signal.SIGINT)
                self.sigints.append(why)
                print(f"  watchdog ({why}): {r} MB at {round(el)} s; SIGINT "
                      f"#{len(self.sigints)}", flush=True)


def select_work(work: list, only: str, include_timed_out: bool):
    """The models a run visits, and the timed-out ones it skips."""
    if only:
        work = [m for m in work if only in m["model"]]
    slow = set() if include_timed_out else timed_out_ids()
    return ([m for m in work if m["id"] not in slow],
            [m["model"] for m in work if m["id"] in slow])


def run(a) -> int:
    work, skipped = select_work(json.loads(WORK.read_text())["models"],
                                a.only, a.include_timed_out)
    if skipped:
        print(f"skipping {len(skipped)} timed-out model(s) (timed-out.json; "
              "--include-timed-out runs them)", flush=True)
    #  `.txt`, not `.jsonl`: the file is under desk/, and Clay refuses a
    #  commit holding an extension with no mark (`%no-cast-between %mime`)
    census = Path(a.census or REPO / "desk/test-data/blackbox/census.txt")
    done = set()
    if census.exists():
        done = {json.loads(l)["id"] for l in census.read_text().splitlines() if l}
    case = desk_case(1)
    print(f"%{DESK} at revision {case}; {len(work)} models, {len(done)} done")
    rid = 2
    for m in work:
        if STOP.is_set():
            print("stopped by SIGTERM, between models", flush=True)
            return 0
        if m["id"] in done:
            continue
        jid = re.sub(r"[^a-z0-9-]", "-", m["id"])
        t0 = time.time()
        submit(rid, jid, request(m, case, a.budget, a.wall))
        rid += 1
        wd = Watchdog(a.rss_cap, a.wall + 60)
        wd.start()
        row = {}
        while True:
            row = summarize(peek_job(rid, jid))
            rid += 1
            if row["status"] != "running":
                break
            if wd.sigints and wd.idle():
                #  interrupted, serf idle, job still `running`: nothing will
                #  ever step it again. The serf is idle, so a cancel lands
                poke(rid, jid, u.tup(u.cord("cancel"), u.cord(jid)))
                rid += 1
                row["status"] = "too slow"
                row["orphaned"] = True
                break
            if time.time() - t0 > 3 * a.wall:
                #  the agent should have ended it at `max-time`; stop the
                #  census rather than loop on a job nothing can end
                wd.done.set()
                print(f"STOP: {m['model']} still running at 3x wall", flush=True)
                return 3
            time.sleep(a.poll)
        wd.done.set()
        if row["status"] == "limited time":
            row["rate"] = round(row.get("distinct", 0) / (time.time() - t0), 1)
        if wd.sigints:
            row["watchdog"] = wd.sigints
        row["peak_rss_mb"] = wd.peak
        row.update({"id": m["id"], "model": m["model"], "expected": m["expected"],
                    "size": m["size"], "secs": round(time.time() - t0, 1),
                    "manifest": {k: m[k] for k in
                                 ("distinctStates", "totalStates", "stateDepth")}})
        with census.open("a") as f:
            f.write(json.dumps(row) + "\n")
        poke(rid, jid, u.tup(u.cord("delete-result"), u.cord(jid)))
        rid += 1
        print(f"{m['model']}: {row['status']} ({row['secs']} s)", flush=True)
    return 0


CI = {"success", "safety failure", "deadlock failure", "liveness failure",
      "assumption failure"}


def classify(row) -> str:
    """R4.0e's census classes."""
    st = row["status"]
    if st in CI:
        if st != row["expected"]:
            return "wrong answer"
        man = row["manifest"]
        if row["size"] == "small" and st == "success":
            for k, mine in (("distinctStates", "distinct"), ("stateDepth", "depth")):
                if man.get(k) is not None and man[k] != row.get(mine):
                    return "wrong answer"
        return "agree"
    #  `max-time` is the runner's wall cap, so `%limited %time` IS too slow
    if st in ("too slow", "limited time"):
        return "too slow"
    if st == "runaway":
        return st
    if st.startswith("limited"):
        return ("agree" if row["size"] == "large" and st == "limited states"
                else f"%limited ({st.split()[1]})")
    if st == "error":
        return f"refused ({row.get('error', {}).get('code', '?')})"
    return st


def report(a) -> int:
    census = Path(a.census or REPO / "desk/test-data/blackbox/census.txt")
    rows = [json.loads(l) for l in census.read_text().splitlines() if l]
    from collections import Counter
    c = Counter(classify(r) for r in rows)
    for k, v in sorted(c.items(), key=lambda kv: -kv[1]):
        print(f"{v:4d}  {k}")
    for r in rows:
        k = classify(r)
        if k != "agree":
            print(f"  {k:24s} {r['model']}  {r.get('error', r.get('reason', ''))}")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage")
    ap.add_argument("--run", action="store_true")
    ap.add_argument("--parse", action="store_true")
    ap.add_argument("--only", default="")
    ap.add_argument("--parse-secs", type=int, default=600)
    ap.add_argument("--budget", type=int, default=20_000)
    ap.add_argument("--census", default="")
    ap.add_argument("--poll", type=float, default=10.0)
    ap.add_argument("--wall", type=float, default=3600.0)
    #  2.5 GB: a SIGINT to a FAST memory runaway at 4 GB crashed the serf in
    #  signal recovery (MCChangRoberts, R4.0e2); interrupt with less to unwind
    ap.add_argument("--rss-cap", type=int, default=2500)
    ap.add_argument("--include-timed-out", action="store_true")
    ap.add_argument("--report", action="store_true")
    a = ap.parse_args()
    if a.stage:
        stage(Path(a.stage))
        return 0
    if a.run:
        return run(a)
    if a.parse:
        return run_parse(a)
    if a.report:
        return report(a)
    ap.print_help()
    return 2


if __name__ == "__main__":
    sys.exit(main())
