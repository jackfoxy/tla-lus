# P2-R1.8.0 — residue audit: measure before designing

Docs-only unit. R1.8 inherited eight `partial` rows whose residue text was
written at different times by different subunits. This unit measures each
claim against the pin and the tree **before** any of it is scheduled, on the
standing rule this release earned four times over: *a row's residue text is a
hypothesis, not evidence.*

Result: **four of the eight rows were already closed** and were carrying stale
text. Three of the four remaining have real, named residue. One (`tlc-driver`)
had no measurable scope at all and now has one.

Ledger effect: 117 terminal / 8 owed → **121 terminal / 4 owed**.

---

## Closed by measurement (re-statused here)

### `tlc-queue` `partial` → `parity`

Residue as written: *"in-memory BFS queue; Disk*Queue excluded"* — a scope
note, never a defect. Measured, the row's whole owner surface is claimed by
two rows that are already terminal:

| Java | Disposition | Evidence |
|---|---|---|
| `IStateQueue`, `StateQueue`, `MemStateQueue` | `tlc-safety-bfs` **parity** | that row names `tool.queue.StateQueue/MemStateQueue` as its own owner: FIFO frontier in generation order, first-seen depths, and the states-left-on-queue count match byte-for-byte |
| `beginChkpt`/`commitChkpt`/`recover` | `tlc-resumable` **parity** | disk-checkpoint byte format is `replaced` by Gall's noun-save; the behavioral resume contract is verified at every slice boundary |
| `sEnqueue`/`sDequeue` | single-worker port | `-workers` is not a port surface (see the driver inventory below) |
| `DiskStateQueue`, `DiskByteArrayQueue`, `ByteArrayQueue` | excluded | the row's own note |
| `StateDeque` | **dead in the pin** | `grep -rl StateDeque` outside `tlc2/tool/queue/` returns nothing — nothing constructs it |

The states-left-on-queue count is not merely spot-checked: it is a compared
field in the tier-2 subdir batches (`gen-tier2-tests.py:907`) and in the mc
corpus, and `check.hoon:375` records a fix made specifically to it (a violating
state is counted distinct but never enqueued). `tests/lib/mc` green.

### `tlc-util-combinatorics` `partial` → `excluded`

Residue as written: *"subset/enumeration helpers partial"*, Hoon column
`lib/eval` — the CST driver R1.4 retired. The row bundles three unrelated
utilities; measured, **none has an observable surface in scope**:

- `util.Combinatorics` — its only consumer in the entire pin is
  `SubsetValue.java` (lines 347/348/367/374/449/611), reached through
  `getRandomSetOfSubsets` and `numberOfKElements`. `getRandomSetOfSubsets` has
  exactly two production callers, both in `tlc2/module/Randomization.java`, and
  `Randomization` is already `excluded` by `tlc-module-excluded` ("RNG-dependent").
  `numberOfKElements` has one caller, `KSubsetValue.java:61` — and **nothing in
  the pin ever constructs a `KSubsetValue`**. So the port needs no `choose`
  table, no Pascal table, and no unranking: the only paths that reach them are
  an excluded module and dead code.
  (Corroboration that this is the right reading: `SubsetValue.java:110` guards
  the `SUBSET A \subseteq SUBSET B` rewrite with `!(other instanceof
  KSubsetValue)`. The port's R1.5.2 reduction agrees unconditionally precisely
  because that subclass never occurs.)
- `BitVector` — liveness-internal (`AbstractGraphNode`, `PossibleErrorModel`,
  `LiveCheck`) and distributed-mode. Its observable behaviour is the liveness
  verdict, owned at `parity` by `tlc-live-scc`/`-lasso`/`-fairness`/`-checkpoint`.
- `Vect` — a bare growable array in 59 files. No semantics of its own.

Subset *enumeration* itself — what the note's wording gestures at — is
`tlc-enum`, terminal at `approved-difference` since R1.4.1 (58 compared
definitions, `ev-sets` byte-exact).

`excluded` rather than `parity`: claiming parity would assert the port
reproduces `Combinatorics`, which it does not and must not.

### `src-clay-async-load` `partial` → `parity`

Residue as written: *"Residue: path canonicalization/escape (10.2), pinned-case
identity + hash-keyed cache (10.3)"*. Both landed. `compatibility.md` headers
**§10.2 Path canonicalization and escape prevention — at parity** and **§10.3
Revision and content identity — at parity**, and in fact every subunit the row
could be waiting on is headed at parity: 10.4 (quotas/retention/noun),
10.5 (idempotency/delivery), 10.6 (API versioning/state migration), with
§10.7 the measured close.

What was actually stale is §10.1's own *"Not yet done in this subunit"* table,
which still lists 10.2–10.6 as owed while each has since been closed by its
own section further down the same file. **Fixed here** — the table is replaced
by a pointer to those sections. This is how the row's residue text went stale:
it was copied from that table.

The equivalence is measured, not asserted (§10.7): for the same texts the Clay
and inline paths produce the same result, `run-stats`, diagnostics, rendered
report and typed counterexample, compared field by field across a passing run,
an invariant violation, a deadlock and a rejected config. `tests/lib/clay-load`
(17 cases) green.

Remaining items are documented non-support with owners elsewhere, not residue
on this row: cfg source override (typed rejection — `check-opt-cfg`), Clay
write-back (unit 13 — `tlc-driver`), PlusCal (its own `absent` row), no
watchdog for a `%writ` that never arrives (port-specific; a settled pinned case
makes an unanswered read a Clay bug), and cross-stage tree sharing (duplicate
*work*, not divergent *behaviour*).

### `src-inline` `partial` → `parity`

Residue as written: *"multi-module resolution not yet wired into %check"*.
Contradicted in the same tree by `compatibility.md:800`, which records that
multi-module resolution inside `%check` landed in unit 10. Measured:
`job.hoon:1011` calls `(analyze-graph:semantic root.src modules.src)` and
`job.hoon:1093` calls `(generate:semantic root.src modules.src)` — the whole
module map, on the same path for inline and Clay, with `%parse` walking
`~(key by modules.src)` (`job.hoon:948`).

Direct evidence: `clay-load.hoon` `+test-clay-equals-inline` runs a **two-module
inline bundle** (`spec` + `helper`) through `%check` and compares it field by
field to the Clay run of the same files; `+test-inline-provenance` asserts the
inline bundle's per-module hashes. Green.

---

## Confirmed real (stay `partial`, now with scope)

### `cfg-validate` — three residues, and one stale paragraph

The three named residues are real and correctly stated:

1. the substitution checks over the **per-module** `mod!lhs <- rhs` tables
   (they need each non-root module's operator list; the graph exposes the root
   plus its EXTENDS imports),
2. `OpRcdValue.toString()` in a 2230 body (every other value shape renders
   byte-exactly through `+render-value`),
3. EC 2281's addendum when the substituting body is non-constant because it is
   **temporal** (tlc2 raises EC 2261 there with its abbreviated expression
   rendering; the port reproduces the dominant 2280 case).

**Stale, removed here:** the row still carried the R1.5.13 measurement
paragraph for EC 2146, ending *"Implementing it needs per-definition
`levelParams` at config-validation time, which `+validate-config` does not
currently receive."* R1.8.1.3b landed 2146 with **both** message variants —
`config.hoon:965` `+msg-2146`, with the plain sentence and the
`Note that a bug can cause TLC to incorrectly report this error.` suffix
selected as the pin selects them. The paragraph describes a design problem
that was subsequently solved; left in place it would have sent R1.8.2 to
thread an `lp` set that is no longer needed.

R1.8.2 scope is therefore the three items above and nothing else.

### `cfg-runspec` — one residue, verified present

*"the job kernel's sliced liveness path passes `~` for the gate — its
continuation does not carry the SPEC name/fairness — so its report omits the
hint the console path emits."* Verified at `job.hoon:1374`, where the comment
sits on the live call site. The same call site carries a second, adjacent gap
from R1.1.R1: it passes the root action name `'Next'` where the console path
passes `sctx`'s `aname` (`Action` under a SPECIFICATION). **Both are one fix**
— widen what the `%live` continuation carries — and R1.8.3 should take them
together rather than paying the continuation-shape change twice.

### `check-opt-cfg` — no residue of its own

Inherits exactly `cfg-validate`'s three, and closes when R1.8.2 closes. The
"cfg source override is still typed-rejected" clause is a documented
non-support (§10.7), not residue. R1.8.2 and this row are one unit of work.

### `tlc-driver` — had no scope; here is one

*"exhaustive/simulate modes partial; flags map to request mold"* named no
behaviour. `TLC.java`'s argument loop accepts **46 flag literals**. Classified
against `sur/tla-lus.hoon`'s `check-opts`/`check-mode`/`limits` (the buckets
partition all 46):

**Mapped today — 5.** `-modelcheck` → `[%exhaustive ...]`; `-simulate` →
`[%simulate seed num depth]` (its `num=` suboption included); `-deadlock` →
`deadlock=?`; `-seed` → `seed`; `-depth` → `max-depth` / the simulate `depth`.

**Excluded by an already-terminal row — 19.** `-dfid` (`tlc-dfid`);
`-workers` (single-worker); `-checkpoint` `-recover` `-cleanup` `-metadir`
(`tlc-resumable`: the disk byte format is `replaced`); `-fp` `-fpmem`
`-fpbits` `-gzip` (fingerprint-set internals); `-coverage`; `-debug`
`-debugger`; `-generateSpecTE` `-noGenerateSpecTE` `-noGenerateSpecTEBin`
`-teSpecOutDir` `-noTE` `-noTEBin` (trace explorer, `tlc-module-excluded`).

**No output channel or filesystem on this engine — 7.** `-dump` `-dumpTrace`
`-loadTrace` `-userFile` `-tool` `-postCondition` `-aril`. Typed rejections by
construction, not gaps — but not currently *written down* as such, which is
part of why the row reads open.

**Already dispositioned elsewhere — 1.** `-config` is the cfg source override,
typed-rejected under `check-opt-cfg` and §10.7.

**Usage — 2.** `-h`, `-help`.

**Genuinely owed, behaviourally observable — 12.** This is R1.8.6's real scope:

| Flag | Effect in the pin | Port |
|---|---|---|
| `-maxSetSize` | bounds set enumeration; overflow is a reported EC | no equivalent anywhere in `desk/` |
| `-difftrace` | `TLCGlobals.printDiffsOnly` — a trace prints only changed bindings | absent; changes rendered trace bytes |
| `-terse` | `TLCGlobals.expand = false` — values print unexpanded | absent |
| `-continue` | `TLCGlobals.continuation` — keep going past the first violation | absent; the port always ends the run |
| `-invlevel` | level at which invariants are checked | absent |
| `-lncheck` | when liveness runs (`default`/`final`/`seqfinal`) | named only in `port-map.md`; never dispositioned |
| `-generate` | `-simulate` with `Tool.probabilistic` set — the *generate* mode (`TLC.java:465-470`) | absent; no probabilistic successor pick |
| `-inv` | an invariant supplied on the command line | port takes invariants from the cfg only |
| `-view` | a VIEW override on the command line | port takes VIEW from the cfg only |
| `-nowarning` `-suppressMessages` `-messagesAsErrors` | diagnostic filtering and severity promotion | `lib/diagnostics` has the severity machinery; no selector |

Also unmapped but **already implemented**: `-simulate stats=basic|full`
(`TLC.java:487-490`) selects the action-statistics table, which R1.7 built and
`gen-sim-stats-tests` compares — it needs a flag, not an engine.

Three of the twelve (`-difftrace`, `-terse`, `-continue`) change **rendered
output bytes**, so they are differential-testable the moment they exist;
`-maxSetSize`, `-invlevel` and `-lncheck` change **verdicts**. R1.8.6 should
decide each one's disposition — map, typed-reject, or exclude with a reason —
rather than "map the flags".

---

## What the audit paid for

Four rows closed without writing a line of Hoon; one row (`tlc-driver`) went
from an unschedulable sentence to a 46-flag inventory in which exactly 12 are
owed and each has a named decision;
one stale design constraint removed from `cfg-validate` that would have sent
R1.8.2 down a dead path; one pair of adjacent gaps in `cfg-runspec` merged so
the continuation shape changes once.

Every claim above was checked against the pin (`tlaplus@4ba7d8811`) or the
tree, not against the residue text. `tests/lib/clay-load` and `tests/lib/mc`
re-run green; `tools/check-parity.py` well-formed after the re-statuses.
