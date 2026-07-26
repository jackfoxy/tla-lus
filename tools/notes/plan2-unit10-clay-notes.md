# Unit 10 (B7 Gall+Clay integration) — inventory, authority, baseline

Subunit 10.0 deliverable. Plan: `~/FoxyLabs/tla-lus/unit-10-plan.md`. Oracle
pin `tlaplus@4ba7d8811`. Unlike the compiler/checker units, **Java is not the
oracle for Gall mechanics**: the typed pipeline in `lib/job` and Arvo's Clay
contract are authoritative. `util.FilenameToStream`/`SimpleFilenameToStream`
is the only Java owner in scope, and only for the module-name → file-name
mapping (lowercased `<name>.tla` over the search roots).

This unit is docs/tools/ledger/fixtures only — no desk deploy, no `-test`
change (mirrors 4.0/7.0). Later subunits (10.1–10.7) land the engine.

## Authority

- **Java (mapping only):** `util.FilenameToStream` — module name → file name;
  `SimpleFilenameToStream` — search-root resolution order. Owns *only* the
  name-to-file semantics, not read mechanics.
- **Arvo Clay (the real read oracle):** `%warp`/`%writ` (async subscribe read)
  and `%cx`/`%cu` scry (synchronous local read + existence). These define the
  request/response shape the kernel's `read-request`/`read-response` mirror.
- **Existing Hoon:** `lib/modules` (`inline-resolver`, `clay-resolver`,
  `resolve` BFS), `lib/job` (`validate`, `do-parse`, the continuation kernel),
  `app/tla-lus` (pokes/watches/arvo/state).

## Baseline (honest, as of 10.0)

- `%clay` is **typed-rejected at `validate`**: `lib/job` +validate returns
  `'unsupported: %clay sources are not loaded yet (unit 10)'` on
  `?=(%clay -.src.req)`. No stub `%ok` is ever produced for a Clay source.
- `clay-resolver` **exists but is dead**: `lib/modules` +clay-resolver is a
  synchronous `.^(@t %cx …)` read guarded by `.^(? %cu …)`, over the search
  roots, module stored under the lowercased name + `%tla`. **The agent never
  invokes it** — only `inline-resolver` reaches `resolve` (via `dump-modres`
  and the inline pipeline). No stage issues Clay cards; `app/tla-lus` on-arvo
  handles only `[%job @ %step ~]` behn wakes, no `%warp`/`%writ`.
- **`step-result` has two outcomes** (`%more`/`%stop`); there is no `%await`.
  A stage cannot request external input.
- **Artifacts are retained forever**: `app/tla-lus` deletes a job's artifacts
  only when the whole job is deleted (`%delete-result`, terminal-gated). No
  retention policy (count/bytes/age), no cleanup path.
- **Quotas are per-request size checks only**: `sur/tla-lus` `limits`
  (`max-source`/`max-modules`/`max-states`/`max-depth`/`max-time`/
  `max-artifact`) enforced per job at `validate`/growth points. No *global*
  agent-state quotas (concurrent jobs, total retained bytes, total in-flight
  source bytes). The WU7.7 `%noun` limit caps the jammed continuation but not
  a `%source-load` cursor (which does not exist yet).
- **State is `%2`**: `app/tla-lus` `state-2 = [%2 jobs=(map req-id job-2)]`;
  `on-load` migrates `%0→%1→%2` (`lib/migrate` jobs-0-to-1, jobs-1-to-2). No
  `%3`/`job-3`, no async-load cursor, pinned case, or quota accounting in
  persisted state.
- **Idempotency, partial**: submit rejects a duplicate *active* id; cancel of
  unknown/terminal is a no-op; wake of a deleted/terminal job is a no-op;
  delete requires terminal, a second delete is a no-op. But resubmit of a
  *terminal* id is undefined; there is no `%writ` dedup/generation guard
  (no `%writ` handler at all); watcher reconnect replays `snapshot` (terminal
  → terminal result, else stage+progress) but is untested against the new load
  stage.

### Desk mark constraint (Clay serving)

The desk has a `%tla` mark (`desk/mar/tla.hoon`) but **no `%cfg` mark**: a
`*.cfg` file reaching Clay aborts `|commit` (`%no-cast-between %mime %cfg`).
So Clay-served cfg bodies use a non-`.tla` marked extension (`.txt`); the
`ModelConfig` parser reads any non-`.tla` extension identically. Module `.tla`
files read over `%cx`/`%warp` via the `%tla` mark. Fixtures follow this in
`desk/test-data/clay/` (`cfg.txt`, not `cfg.cfg`).

## Owner-to-behavior matrix (splits `src-clay`)

Each row: Hoon owner (target, mostly to-be-written), one positive (`+`) and
one negative (`−`) fixture. Fixtures named `clay/<dir>` live under
`desk/test-data/clay/`; request-shaped fixtures (path/quota/idempotency) are
authored as Hoon unit-test cases with their subunit and named here so every
later subunit has named failing fixtures.

| behavior | ledger row | hoon owner (target) | + fixture | − fixture | subunit |
|---|---|---|---|---|---|
| async source-load | src-clay-async-load | lib/job kont %source-load; lib/modules resolver-as-cursor; app on-arvo %warp/%writ | `clay/multi` (2-module graph closes over reads) | `clay/miss` (referenced module absent → %modules %missing) | 10.1 |
| path canonicalization | src-clay-path-canon | lib/source-path (canonicalize, module-path) | `tests/lib/source-path` accept: nested search-root ordering, pinned case | reject: malformed ship/desk/case | 10.2 |
| escape prevention | src-clay-escape | lib/source-path (escape guard) | accept: in-root `sub/spec.tla` | reject: `../secret`, absolute, dotted/`$` segment (names offending segment) | 10.2 |
| revision/content identity | src-clay-identity | lib/modules (loaded `[ship desk case hash]`, hash-keyed parse cache); lib/job thread hash | accept: same content across ships/cases parses once, provenance in artifact | reject: mid-run desk commit does not change pinned source set | 10.3 |
| per-request quotas | src-clay-quota-req | lib/job limits enforced during async load | accept: bytes/modules accrue under bound | reject: growing set crosses `max-source`/`max-modules` → `%limited %source`/`%modules` | 10.4 |
| global quotas | src-clay-quota-global | app/tla-lus state (concurrent jobs, retained bytes, in-flight source bytes) | accept: within global caps | reject: cap crossed → typed terminal naming the limiting resource | 10.4 |
| artifact retention/cleanup | src-clay-artifact-retain | app/tla-lus state (retention policy + cleanup); on-peek terminal artifact scry | accept: terminal artifact reclaimable, delete frees quota | reject: artifact retained past policy is cleaned; over-bound store rejected | 10.4 |
| noun-size | src-clay-noun-size | lib/job %noun limit on `%source-load` cursor (extends WU7.7) | accept: bounded fan-out cursor jams under `max-noun` | reject: pathological fan-out → `%limited %noun` | 10.4 |
| idempotency | src-clay-idempotency | app/tla-lus pokes/arvo; lib/job engine | accept: single-delivery baseline event stream | reject: dup/reordered submit/wake/writ/cancel/delete/reconnect leave state+events unchanged | 10.5 |

`src-clay` is kept as an **umbrella** row (like `op-check-exhaustive`) pointing
at the nine granular rows.

### New `op-gall-*` rows (agent mechanics)

| row | hoon owner | + fixture | − fixture | subunit |
|---|---|---|---|---|
| op-gall-submit | app on-poke %submit | new terminal-resubmit policy (reject or replace under flag) | retried identical submit does not double-schedule | 10.5 |
| op-gall-wake | app on-arvo %step | wake advances an active job | late/dup wake after completion never resumes/re-emits | 10.5 |
| op-gall-writ | app on-arvo %warp/%writ | valid `%writ` for a pending `tag` resumes +step | dup/out-of-order/stale-generation/unknown-job `%writ` dropped | 10.1/10.5 |
| op-gall-cancel | app on-poke %cancel | cancel mid-load seals job | cancel of unknown/terminal is a no-op | 10.5 |
| op-gall-delete | app on-poke %delete-result | delete terminal frees quota | second delete is a no-op, not a crash | 10.5 |
| op-gall-watch | app on-watch snapshot | reconnect mid-run gets stage+progress | reconnect after terminal gets exactly the terminal result (no partial replay) | 10.5 |

## Classification (task 4)

| behavior | class | reason |
|---|---|---|
| async source-load | **required** | replaces the dead synchronous `clay-resolver`; the unit's core |
| path canonicalization | **required** | escape-free source-ref by construction |
| escape prevention | **required** | security invariant; no `..`/absolute/out-of-root |
| revision/content identity | **required** | pinned case + content hash so a result names what it checked |
| per-request quotas | **required** | bytes/modules bounded during async growth, not only at submit |
| global quotas | **required** | agent-level DoS bound (concurrent jobs / retained / in-flight) |
| artifact retention/cleanup | **required** | bounded retention + reclaim on delete |
| noun-size | **required** | extends WU7.7 to the load cursor; no unbounded jammed state |
| idempotency | **required** | correctness under repeated/reordered Gall delivery |
| Clay **write-back** (`allow-write`, `%write-translation`) | **deferred → unit 13** | flag stays accepted-and-ignored (ledger `allow-write`) |
| cfg **source override** (`check-opts.cfg`), SPECIFICATION-form config | **deferred → unit 5 residue** | still typed-rejected (ledger `check-opt-cfg`) |
| PlusCal translate-before-check | **deferred → unit 8** | still typed-rejected (ledger `op-translate`/`check-opt-translate`) |
| new checking semantics | **excluded** | Clay must produce *identical* verdicts to the inline bundle (WU7/8/9 own semantics) |
| distributed Clay, remote-desk live subscriptions | **excluded** | not a first-target surface |
| telemetry / JMX | **excluded** | monitoring out of scope (ledger `tlc-management`) |

No in-scope Gall/Clay behavior is left unclassified.

## 10.1 Asynchronous source-load stage (done)

### What landed

- **`sur/tla-lus`**: `source-ref` (`[ship desk case path]`), `read-request`
  (`[tag source-ref]`), `read-response` (`[tag (each @t @t)]`), and the
  `%await` arm of `step-result`. Also finished the `%clay` `source-bundle`
  shape: `root` is a **module name**, not a path (the file is
  `<search-root>/<lowercased-name>/tla`), and `cfg` is a desk path under a
  marked non-`.tla` extension.
- **`lib/job`**: a new `%modules` stage, planned first for a `%clay`
  bundle. `+do-load` drives a `%load` cursor (`lcur`) that owns the BFS
  queue, the reads in flight (`pend`, by tag), the delivered-but-unabsorbed
  `inbox`, the loaded texts, and the byte/module accounting. `+deliver`
  is the agent's entry point: it appends responses to the cursor's inbox
  (dropping nothing, judging nothing) and `+step` absorbs them.
  `+load-drain` does the judging: hit → parse, declared-name check,
  register, enqueue references; miss → next search root, then the
  standard modules, then a typed failure.
- **Sources through the pipeline**: a new `srcs` record (`root`/`modules`/
  `cfg`) travels on the continuation (`%src`, and on `%parse`/`%tree` as
  `(unit srcs)`). `+srcs-of` returns the request's inline bundle or the
  loaded set, so `%parse`, `%semantic`, and `%config` are
  representation-agnostic — every `?> ?=(%inline …)` is gone. `+carry`
  keeps an inline bundle from ever being copied into the continuation.
- **`app/tla-lus`**: `+advance` handles all three step outcomes.
  On `%await` it turns each `read-request` into a tagged
  `%warp`/`%sing`/`%x` card on wire `[%job id %load <tag> ~]`;
  `on-arvo [%job @ %load @ ~]` converts the `%writ` back into a
  `read-response`, delivers it, and re-enters `+step`.
- **Pinned revision at submit**: `+pin-case` resolves the requested case
  with `.^(cass:clay %cw …)` and stores `[%ud n]` in the job's request.

### Clay facts that shaped the design (verified on the fake ship)

- **A future `%da` case is not settled**: `.^(cass:clay %cw /=desk=/(scot
  %da (add now ~d1)))` bails. A `%sing` `%warp` at an unsettled case waits
  for a commit, so a job could hang forever. Hence the `%ud` pin at submit,
  wrapped in `mule` → a typed rejection instead of a crashed poke.
- **Absent files are answered synchronously**: the agent probes
  `.^(? %cu …)` and, when the path does not exist at the pinned revision,
  synthesizes the negative `read-response` and schedules a wake instead of
  warping. This makes "not under this search root" deterministic and
  keeps the missing-file path from depending on Clay's unborn-path
  behavior. Existing files always go through the real `%warp`/`%writ`.
- **Mark-agnostic bodies**: a `%writ` cage for a `.tla` file is an atom
  (`%tla`), for a `.txt` file a `wain` (`%txt`). `+writ-text` reads the
  vase's noun directly (`?@` → cord, else `of-wain`), so no mark table is
  needed.

### Deliberate deviations

- A standard-module name **is read for** before falling back to the
  vendored text (the plan said standard modules need no read). Attempting
  the read is exactly what lets a user file shadow a standard module, as
  the inline resolver does; the cost is one miss per standard name.
- The load stage parses each module to extract references and discards the
  tree; `%parse` re-parses the root. Sharing that work through a
  content-hash cache is 10.3.
- A paused job has no watchdog timer (see compatibility.md).

### Evidence

- `desk/tests/lib/clay-load.hoon` — 17 cases, all green: the multi-module
  differential against the frozen inline golden (`[%ok [5 4 0 4]]`), the
  single-module case, Clay-equals-inline, the await protocol (first slice
  asks for cfg + root, load budget slices a nine-way fan-out to 8 reads),
  pause/resume at **every** boundary including across the Clay boundary,
  stale/duplicate/unknown-tag responses ignored, search-root order,
  standard-module fallback, the four typed `%modules` failures, and
  `%limited %source`/`%modules` at growth.
- Full ship suite `ok=%.y`.
- **Live** on `~zod` (this is the `op-gall-writ` evidence; it cannot be
  driven from a hand-built bowl because the case pin needs the real desk):

  ```
  :tla-lus &tla-lus-action [%submit ~.c1 [[%check [| ~ [%exhaustive &]]]
    [%clay our %tla-lus [%da now] 'spec'
      [~ /test-data/clay/multi/cfg/txt] ~[/test-data/clay/multi]]
    [1.000.000 64 100.000 1.000 ~m10 1.000.000] |]]
  +tla-lus!tla-lus/status ~.c1
  ```

  → case pinned `[%ud 268]`, `result=[~ [%ok [5 4 0 4]]]`, report artifact
  byte-identical to the inline run. Root `'nope'` → `%failed` with the
  `[%lus 401]` `%modules` diagnostic `Cannot find source file for module
  nope.`

### Corrections to 10.0

- `test-data/clay/single/expect.txt` said `[%ok [3 3 0 3]]`; the mod-3
  counter actually generates 4 states (1 initial + 3 successors), so the
  frozen expectation is `[%ok [4 3 0 3]]` — measured, and asserted in
  `test-clay-single-module` against the inline run of the same text.

### Hoon gotchas hit (all previously known, all re-hit)

- `=.`/`=^` into a **narrowed** wing nest-fails: `?~ inbox.c` then
  `=. inbox.c t.inbox.c`, `?> ?=(^ roots.c)` then `=^ … c`, and
  `?~ cfg-path.c` then `=^ … c` all failed. Fix: copy the field to a
  local, test the copy, and put the widened value back with `c(field …)`.
- Face access across a `$%` fork is `find-fork`: `job.r`/`result.job.r`
  in the tests needed `?> ?=(%stop -.r)` once `step-result` grew a third
  arm.
- `malt` over path literals: a path literal's type is its exact segments,
  which will not nest in `(map path @t)` — cast the list flat first
  (`|=(l=(list [path @t]) (malt l))`).
- `result` is **not** a free mold name in a test context (`/+ *test`
  brings its own); read the field off the job instead of casting.
- Adding two members to the `kont` `$%` (5 → 7) did **not** trip the
  zuse-408 mold compiler; `kont` is not itself in a recursive cycle.

## 10.2 Path canonicalization and escape prevention (done)

### What landed

- **`desk/lib/source-path.hoon`** — the only constructor of a
  `source-ref`. `+read-ref` requires a pinned (`%ud`) case, a well-formed
  desk, canonical segments, and a path under a declared search root;
  `+check-bundle` judges a whole `%clay` bundle at submit;
  `+module-path`/`+module-seg` own the `util.FilenameToStream` mapping;
  `+path-err` + `+err-text` are the typed error and its message.
- **`lib/job`**: `+validate-clay` is now `check-bundle` + `err-text` (so
  the submit-time rejection names the offending segment), `+mod-path` is
  gone in favour of `module-path:sp`, `+load-ask` builds every request
  through `read-ref:sp` (a path error becomes a typed `%modules`
  failure), and `+do-load` refuses to start on an unpinned case.
- **Parse-failure parity**: the loader no longer fails a module that will
  not parse. It registers the text as it arrived and contributes no
  references, so `%parse` reports SANY's own error text — the identical
  failure an inline bundle of the same text produces. (The declared-name
  check stays in the loader: the file name is lowercased, so only the
  loader can compare it against the requested, case-sensitive name.)

### Decisions

- **The config must live under a search root.** The plan's escape rule is
  "every candidate must stay under a declared search root"; making the
  config an exception would leave one unguarded path. The fixtures
  already satisfy it (`roots ~[/test-data/clay/multi]`, cfg
  `/test-data/clay/multi/cfg/txt`).
- **`.` is not a legal segment character.** Rejecting dotted segments
  costs nothing here (Clay stores the extension as its own segment) and
  catches a filesystem-style path smuggled into one knot.
- **Uppercase is rejected** rather than silently lowercased: Clay cannot
  store it, so naming it is more honest than papering over it.
- **The escape guard is defense in depth, not a Clay vulnerability.** A
  `..` segment in Clay is a malformed knot, not traversal, and a read is
  already confined to one desk. Recorded as such in compatibility.md so
  nobody later mistakes the guard for a fixed hole.

### Evidence

- `desk/tests/lib/source-path.hoon` — 18 cases: accepted (in-root, nested
  root, `/` as the desk, lowercasing, a whole valid bundle) and rejected
  (`.`/`..`, `$`-prefixed, dotted, uppercase, empty segment, out-of-root,
  a root's own prefix, `%da`/`%tas` case, empty desk, malformed module
  name, no roots, empty root name, escaping search root, config outside
  the roots, escaping config) — each asserting the typed error *and*,
  for the representative ones, its rendered message.
- `desk/tests/lib/clay-load.hoon` grew to 21: the four new cases are the
  submit rejections seen through `+validate` (escaping root, config out of
  root, malformed module name) and an unpinned-case run stopping at
  `%modules`; `test-clay-unparsable-module` is now a differential against
  the inline run rather than a hardcoded loader message.
- Full ship suite `ok=%.y`.

### Hoon gotchas hit

- `levy`/`lien` are wet: fed a `?~`-narrowed tape they mull-grow. Widen at
  the call site (`` (levy `tape`t knot-char) ``).
- `-.(some-call)` is a syntax error; use `=/` and then `-.face` (or `-:`).
- A path literal cannot spell `..`, `$foo`, `spec.tla`, `Spec`, or an
  empty segment — build those paths flat with `` `@ta` `` casts.

## 10.3 Revision and content identity (done)

### What landed

- **Provenance**: `lib/job` gained `prov` (`[id=source-id hash=@]`) and
  `provs` (root, modules by name, config). The Clay cursor records the
  path each module was actually read from (`refs`, filled from the
  pending read's own `pax`), so `+clay-provs` can name every file;
  `+inline-provs` produces the same shape for a bundle. `+render-sources`
  writes the `%sources` artifact, `+put-sources` stores it.
- **Where it is stored**: at the close of the load (`+close-load`) for
  Clay, on entry to `%parse` for inline — as early as the sources are
  known, so a run that later fails still records what it read.
- **One revision**: already true after 10.2 (pin at submit +
  `read-ref` refusing an unpinned case); 10.3 asserts it over the whole
  read stream of a run.
- **Semantic graph generated once**: `do-config` used to call
  `run-spec-of:config` (which generates the graph internally) *and*
  `generate:semantic` — building the graph and reparsing every module
  twice. New `+run-spec-with:config` takes an already-generated
  `sem-module`; `do-config` generates once and passes it. Observable
  behavior is unchanged, including the `[%tlc 0] internal: module
  generation failed` diagnostic (which `run-spec-of` used to emit and
  `do-config` now emits directly).

### Decisions

- **A provenance record cannot fail a run.** It is engine metadata, not
  the caller's output. When it does not fit inside `max-artifact` it is
  dropped with a `[%lus 402]` warning diagnostic. The first
  implementation made it `%limited %artifact`, which changed
  `test-limited-artifact` from `[5 4 0 4]` to `[0 0 0 0]` — failing a
  sound run because the *engine* wanted to write a note. Warning is the
  honest reading of "bounded" here, and it leaves the frozen behavior
  of the report limit untouched.
- **Standard modules are not listed**: they are vendored, never read, and
  fixed by the desk revision.
- **The cross-stage parse cache was not built.** Sharing trees between
  the load stage, `%parse`, and `generate` would put syntax trees into
  the persisted continuation (jammed at every slice). The cheap half of
  the win — not generating the semantic graph twice — is taken; the rest
  is documented residue.

### Evidence

- `tests/lib/clay-load.hoon` grew to 26: `test-clay-provenance` and
  `test-inline-provenance` are goldens of the record (built independently
  in the test from `shax` of each fixture text, so they assert the hash is
  really the content hash and that both representations agree);
  `test-provenance-omitted-not-silent`; `test-clay-one-revision` (every
  read of a run carries one ship/desk/revision);
  `test-parse-cache-is-content-keyed`.
- Full ship suite `ok=%.y`.

### Hoon gotchas hit

- `?:` branches of different shapes (`[%& j]` vs a gate call returning
  `(each …)`) unify into a fork whose `p` cannot be found — `find-fork` on
  `p.sa`. Cast the `=/` (`=/ sa=(each job-2 step-result-2)`).
- Writing a *wide* value back into a face the compiler narrowed (here `j`,
  narrowed by `?=(%clay -.src.request.j)`) nest-fails. Hand the value to a
  gate of its own instead (`+close-load`).
- `join` is wet: fed a fixed-length list literal it mull-grows. Bind the
  lines as `(list @t)` first.
- **Stale scrollback bit hard again**: a `FAILED` line from a previous
  `-test` run sat above the visible pane and looked like the current
  result twice in a row. `tmux clear-history` does not clear the visible
  screen. Print a marker (`'MARKER-A'`) before the run and read only the
  output after it.

## 10.4 Quotas, retention, cleanup, and noun size (done)

### What landed

- **`gquota`** in `lib/job` (`max-jobs` 8, `max-retained` 8 MB,
  `max-inflight` 4 MB) plus `+default-quota`, with `+quota-reject` as the
  agent-wide gate a new job must pass on top of `+validate`. The agent
  calls it in `on-poke %submit`.
- **Derived accounting**: `+active-count`, `+retained-bytes`,
  `+inflight-source`, `+artifact-bytes`, `+source-charge`. No counters in
  agent state.
- **`+reclaim`**: over the retention bound, the oldest terminal jobs give
  up their artifact bodies first, keeping result/stats/diags and gaining a
  `[%lus 403]` warning. The agent runs it (`+retain`) only when a job
  becomes terminal.
- **`+noun-over`**: the WU7.7 in-flight noun bound, factored out and
  applied to the `%load` cursor as well as the search cursor.

### Decisions

- **Derived, not counted.** All three global figures are computed from the
  jobs map on demand. A counter in agent state would need a migration
  (10.6), a decrement on every path that removes a job, and would drift
  the first time one of those paths was missed. Deriving makes "deleting a
  terminal job frees its quota" true by construction rather than by
  remembering to write it. The cost is an O(jobs) scan at submit and at
  completion, which is bounded by `max-jobs` — the very thing being
  enforced.
- **Reclaim bodies, not jobs.** Evicting whole terminal jobs would make a
  caller's result vanish before it read it. Dropping only the artifact
  bodies keeps every result queryable and reclaims the bulk. The
  `[%lus 403]` warning means a later artifact scry that misses is
  explained by the job's own diagnostics — the alternative (a silently
  empty scry) is indistinguishable from "never existed".
- **A Clay job reserves `max-source`.** Its actual bytes live inside the
  jammed cursor and would have to be cued to be measured. Reserving the
  declared bound is the honest conservative charge, and it is exactly what
  the job is permitted to consume.
- **Two different byte measures**, documented rather than unified:
  `retained-bytes` is the jammed size of a job's artifact map;
  per-request `max-artifact` is the report's own text bytes.
- Task 2 (`max-source`/`max-modules` during async load) already landed in
  10.1 at the growth point, with tests; the ledger row moved to parity
  here rather than being re-implemented.

### Evidence

- `tests/lib/job.hoon` +7: the three bound rejections (with a small quota
  so the caps are reachable in a test), terminal jobs not counting against
  concurrency, deletion freeing the bound, oldest-first reclamation with
  its warning, active jobs spared, under-bound identity, and the shared
  noun predicate.
- `tests/app/tla-lus.hoon` +3: submitting past the concurrency bound is
  rejected and creates no job; a cancelled job frees the bound; a deleted
  one frees it too.
- Full ship suite `ok=%.y`.

## Done (10.0)

- `src-clay` split into nine granular ledger rows + umbrella; six `op-gall-*`
  rows added; `tools/check-parity.py --check` clean.
- Baseline recorded above (typed-reject at validate; dead `clay-resolver`;
  forever-retained artifacts; per-request-only quotas; state `%2`).
- Clay differential harness seeded: `desk/test-data/clay/{multi,single}` with
  multi-module `.tla` + `cfg.txt` + `expect.txt` keyed to the frozen inline
  golden (`multi` → `[%ok [5 4 0 4]]`).
- Every 10.1–10.7 behavior has a named positive and negative fixture.
