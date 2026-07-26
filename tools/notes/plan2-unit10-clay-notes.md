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

## Done (10.0)

- `src-clay` split into nine granular ledger rows + umbrella; six `op-gall-*`
  rows added; `tools/check-parity.py --check` clean.
- Baseline recorded above (typed-reject at validate; dead `clay-resolver`;
  forever-retained artifacts; per-request-only quotas; state `%2`).
- Clay differential harness seeded: `desk/test-data/clay/{multi,single}` with
  multi-module `.tla` + `cfg.txt` + `expect.txt` keyed to the frozen inline
  golden (`multi` → `[%ok [5 4 0 4]]`).
- Every 10.1–10.7 behavior has a named positive and negative fixture.
