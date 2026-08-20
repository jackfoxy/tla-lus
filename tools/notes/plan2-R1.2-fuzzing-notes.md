# R1.2 — Fuzzing + fixture expansion (unit 11) — measurement notes

Parent plan: `~/FoxyLabs/tla-lus/R1.2-fuzzing-plan.md` (.0–.7).
Oracle pin: `tlaplus@4ba7d8811`.

## R1.2.0 — kickoff (docs only)

### The headline: a reachable crash, found by inspection before any fuzzer was written

```
---- MODULE A ----
EXTENDS Naturals
VARIABLE x, y
Init == x = 0 /\ y = 0
Next == x' = 1 - x /\ y' = y
Live == <>(x = 1 /\ y = 0)
====
INIT Init / NEXT Next / PROPERTY Live
```

`check:check` **bails `%tlc-live-statepred-junction`**. TLC runs it to a verdict:
`Error: Temporal property Live was violated.` / `2 distinct states found`.

There is nothing exotic here — an eventually-operator over a conjunction of two state predicates.
It was found by reading `+st-pred-bool:liveness` against `+cs-eval:liveness`, not by fuzzing, which
is the first thing `.0` has to say about how much surface is unexplored.

**The cause is an asymmetry between two evaluators over the same mold.** Both walk a `live-expr` at
a state:

| arm | handles | bails on |
|---|---|---|
| `+cs-eval` (checkState) | `%bool %neg %conj %disj %state` | `%act %enabled %all %even %next` |
| `+st-pred-bool` (tableau node consistency) | `%bool %neg %state` | `%next %all %even` **`%conj %disj`** `%act %enabled` |

`+state-preds-of:tableau` keeps a particle's members with `le-level <= 1`, and `le-level` of a
`%conj` is the max of its children — so a conjunction of two state predicates has level 1, survives
the filter, reaches `+st-pred-bool`, and hits a bail that `+cs-eval` would have evaluated. The
R1.6.2 `TBGRAPH` projection makes this visible: `leadsto-viol`'s golden shows a particle whose
second member *is* a conjunction (there at level 3, so the filter drops it — which is why no
existing fixture trips this).

This is `.3`'s first fixture and probably its first fix. It also validates the plan's ordering:
`.3` (temporal/liveness) was already flagged as the increment to do first among the middle four.

### (a) The bail surface, classified

29 `!!` sites in port libraries. The first cut is **not** reachable-vs-unreachable, it is
**production-reachable at all**:

**19 sites are in a test-only driver.** `lib/eval.hoon`'s CST evaluator (`+eval` over `node`) is
reached only from `desk/tests/lib/eval.hoon`. Production imports `lib/eval` for its *types*
(`value:ev`, `vfield`, `vpair`) and four CST helpers (`kids-of`, `is-kind`, `op-name`,
`genid-name`) — R1.4.4 retired the CST driver to test-only and R1.4 deleted the dead state
generator from `check.hoon`. No input a user submits reaches those 19, **including all six
unlabelled `!!`** (lines 528, 530, 569, 570, 579, 582).

That materially re-scopes the plan: DoD item 3 ("no unlabelled `!!` remains in port code") is about
a test-only file, so `.0` recommends **either deleting the CST driver or exempting it explicitly**
— a decision for `.4`, not a fuzzing target. The `!!` hits in `lexer.hoon:148` and
`syntax.hoon:111/181` are the TLA+ operator `!!` in token/precedence tables, not crashes at all.

**The production-reachable surface is 21 sites, all labelled:**

| site | tag | first read |
|---|---|---|
| `liveness.hoon:30-36` (7) | `%tlc-live-statepred-{next,temporal,junction,action,enabled}` | **`%conj`/`%disj` PROVEN REACHABLE (above)**; the rest need the same test |
| `liveness.hoon:253-257` (5) | `%tlc-live-checkstate-{action,enabled,temporal,next}` | checkState is built from level<=1 PEM entries; `%act`/`%enabled` should be impossible — argument owed |
| `liveness.hoon:277-279` (3) | `%tlc-live-checkaction-{temporal,next}` | checkAction is level<=2; `%all`/`%even` should be impossible — argument owed |
| `tableau.hoon:86-87` (2) | `%tlc-live-encountered-actions` | **has a real EC**: 2249 `TLC_LIVE_ENCOUNTERED_ACTIONS`, "TLC encountered actions when computing closure." Convert, don't bail |
| `temporal.hoon:810` (1) | `%tlc-live-wrong-formula-format` | **has a real EC**: 2214. Already fired on five test-model specs (R1.6.0); now unreachable via `+ast`'s user-op branch, but that is a fix upstream, not a proof |
| `config.hoon:400` (1) | `%cfg-value-unexpected` | `+render-value` over a `cfg-value` variant `parse-cfg` cannot produce — argument owed |
| `job.hoon:515` (1) | `%tla-lus-unplanned-stage` | an internal invariant on the stage plan, not input-driven — argument owed |
| `diagnostics.hoon:128` (1) | `[%unmapped-ec code]` | an EC with no message mapping; reachable iff any emitter can produce an unmapped code |

Two of the 21 already map to real tlc2 error codes (2214, 2249), so for those the conversion target
is not invention: emit the EC as a typed rejection. That is the pattern to prefer everywhere —
**a bail with a tlc2 EC behind it is a diagnostic waiting to be wired**, not an assertion.

### (b) Generator strategy — per stage, and why the current one does not generalize

`tests/lib/fuzz` generates a random token soup inside a module frame. That reaches the lexer and
parser and essentially never reaches `sem`, `config`, or liveness — a random token stream almost
never parses. So:

- **Front end** (lexer/parser): keep the existing token-soup generator. It is the right shape and
  the invariant is already enforced.
- **Everything past it**: **mutate the existing corpora** rather than generate from a grammar. The
  repo already holds hundreds of *valid* inputs (`test-data/{parse,sem,cfg,liveness,mc,safety}`),
  and small mutations of a valid module stay parseable far more often than anything generated from
  scratch. Mutation operators to start with: delete/duplicate a line, swap two operators of the
  same arity, change a level (prime/unprime a variable, wrap a subformula in `[]`/`<>`), and
  perturb a `.cfg` key.
- **Decoding** (`.5`): no generator needed — `jam`/`cue` round-trips with bit-flips and truncation.

Grammar-directed generation is explicitly **not** chosen at `.0`: it is a large build whose payoff
is unclear next to a corpus that already exists, and it can be revisited if mutation plateaus.

### (c) The budget — `mule` is not enough

`mule` catches a bail; it does not catch a loop. R1.8.1.4's liveness build ran 480 s without a
verdict on a 5-state spec. So the runner must classify **four** outcomes, not two:

```
%ok  %rejected  %bailed  %budget
```

with `%budget` produced by a step bound the runner threads into the stage (the port already has the
device: `build-graph-cap`/`live-graph-cap`, `+expand-cap`, `fuel` in `eenv`). A `%budget` result is
a *recorded failure*, not a hang — an arm must never be able to wedge the ship, which the dev-log
already records as a real cost (`[[tla-lus-dev-environment]]`, dojo wedge recovery).

### (d) Shrinking — deliberately none at `.0`

A delta-debug over the mutation list is cheap to add later, but the mutation strategy in (b)
produces inputs that are already close to a valid corpus case, so the reduction distance is small.
Decision: **no shrinker in `.1`**; revisit if a found crash is not obviously minimal. The
already-found `%tlc-live-statepred-junction` case is six lines, which supports this.

### (e) Where arms and fixtures live

- **Arms**: extend `tests/lib/fuzz.hoon` rather than adding per-stage shards. One shard keeps the
  runner in one place and keeps the seeds together; the arms name their stage
  (`test-fuzz-liveness-*`, `test-fuzz-cfg-*`).
- **Fixtures**: a reduced crash lands in the corpus that *owns the stage* — a liveness crash in
  `test-data/liveness`, a config crash in `test-data/cfg-val` — so it is picked up by that stage's
  existing generator and comparator, and becomes a permanent tier-1 case. It does **not** land in a
  fuzz-specific corpus, which would leave it outside every differential.

### Consequences for the plan

- `.4`'s scope shrinks to a decision (delete the CST driver, or exempt it) plus `node-eval`, since
  `lib/eval`'s 19 sites are test-only.
- `.3` gains a proven fixture and a probable fix before it starts.
- DoD item 3 needs the test-only carve-out written into it.

## R1.2.1 — the harness

### What landed

`tests/lib/fuzz.hoon` now has one runner instead of three ad-hoc arms. `+fz-run` takes a seed, a
run count, a **generator** (`[index rng] -> input`) and a **stage adapter** (`input -> fz-outcome`),
and returns only the failures — each carrying the input that caused it, so the case is reducible.

```
+$  fz-outcome  ?(%ok %rejected %bailed %budget)
+$  fz-fail     [i=@ud out=fz-outcome inp=@t]
```

`%ok` and `%rejected` both pass: a typed rejection is a correct answer, and the invariant is about
crashing, not about accepting. `%bailed` and `%budget` are failures.

### The budget is a contract on the adapter, not a feature of the runner

This is the design point worth recording. `mule` catches a bail; it does not catch a loop, and
R1.8.1.4 found a liveness build that ran 480 s on a five-state spec. Hoon offers the harness no
timeout it can impose from outside — so `+fz-run` **cannot** bound a stage. What it can do is
require that each adapter call its stage with the caps that stage already owns (`live-graph-cap`,
`+expand-cap`, `fuel:eenv`) and report a cap-hit as `%budget`.

That obligation is unenforceable in code, so it is written in three places: the shard header,
`doc/testing.md`, and here. An adapter that forgets it does not fail loudly — it hangs the arm,
which is exactly the failure mode `[[tla-lus-dev-environment]]` records as costly.

### The runner is tested, not assumed

`test-fuzz-runner-classifies` drives four **synthetic** stages — one that bails, one that reports a
budget, one that succeeds, one that rejects — and asserts the runner reports exactly the first two,
with the offending input attached. Synthetic on purpose: it stays true whatever the port does, so it
tests the harness rather than the port.

`.0`'s real crash (`<>(x = 1 /\ y = 0)` → `%tlc-live-statepred-junction`) is deliberately **not**
used here. It belongs to `.3` as a corpus fixture, and an arm built on a bug is an arm that fails
the moment the bug is fixed.

### Retrofit

The three existing parser arms now go through `+fz-run` with the `+fz-parse` adapter and the
`+gen-module` / `+gen-fixed` generators, so there is one mechanism. Coverage is unchanged (200 + 120
random modules, 10 hand-written garbage inputs); what changed is that a failure now names the run
index and hands back the input instead of collapsing to `%.n`.

`+gen-fixed` — a generator over a fixed list — is what lets a hand-written adversarial set share the
runner with the random ones, and it is how `.2`–`.5` will feed reduced fixtures back through.

### Result

`fuzz` 4/4 green. `doc/testing.md`'s Fuzzing section rewritten: the four outcomes, the adapter's
budget obligation, the reduce-and-freeze procedure (reduce → commit to the corpus that OWNS the
stage → capture its golden → only then fix), and an honest statement of what is covered today.

### Hoon note

`=/  name  value` needs a **two-space gap** on both sides of the name; `=/ name  value` is a syntax
error, and the message points at the value rather than at the missing space.

## R1.2.2 — semantic graph + config

### Mutation, not generation

`.0` decided to mutate valid inputs rather than generate from a grammar, and `.2` implements the
line-level operators: drop a line, duplicate a line, swap two lines, replace a line with random
token soup — 1 to 3 edits per case, over a base picked at random. Line-level on purpose: a
character-level edit almost always breaks the parse, and a module that does not parse tells the
semantic stage nothing.

The bases are three corpus modules and three corpus `.cfg`s, **inlined** in the shard. A test cannot
scry Clay for `test-data` (the framework passes no `our`/`now`), so embedding is the only option; the
same constraint every generated shard in this repo works around.

Four adapters: `+fz-sem` (`generate:semantic`), `+fz-cfg` (`+parse-cfg`), and `+fz-runspec-cfg` /
`+fz-runspec-spec` — the whole config path (`+run-spec-of`: parse, validate against the graph,
assemble) with one side fixed and the other mutated. Two arms rather than one because the path takes
*two* inputs, and mutating both at once would almost never produce a pair that validates.

**None of these four can report `%budget`**, and the shard says so: they walk a finite parse tree,
with no state space to bound and no cap to pass. The adapter's budget obligation binds the stages
that *iterate*, which are `.3`'s and `.4`'s.

### 700 cases, zero bails — and why that alone would have been a weak result

No crash was found. That is worth having, but on its own it is nearly meaningless: **an arm that
only asserts "no bails" passes trivially if every mutation is rejected at the parse step and never
reaches the stage under test.** So the reach was measured rather than assumed, with a `+fz-reach`
counter over the same seeds:

| arm | reached the stage | rejected earlier |
|---|---|---|
| `fz-sem` | 99 / 200 | 101 |
| `fz-cfg` | 91 / 200 | 91 |
| `fz-runspec-cfg` | 29 / 150 | 121 |
| `fz-runspec-spec` | 16 / 150 | 134 |

Half of the mutations reach the semantic graph and the config parser; 11–19 % reach the full
run-spec path, which is expected — that path needs a module that resolves *and* a config that
validates against it, so most single edits break the pair.

`test-fuzz-reach-floors` asserts floors of 60 / 60 / 15 / 8 against those exact counts (the seeds are
fixed, so they are reproducible). The floors sit well below the measurements, so ordinary drift does
not trip them — but a change that stops mutations reaching a stage, or makes a stage reject
everything, fails *there* instead of quietly leaving the four arms above passing on nothing.

This is the fuzz form of the hazard R1.8.1.4 recorded for differentials: a filter added to make a
test pass is a test that has stopped measuring.

### Result

`fuzz` **9/9** green. The shard now takes roughly ten minutes (`test-fuzz-sem-no-crash` alone is
~120 s), which is worth knowing before adding more runs.

### Hoon note

`(snag i bases)` on a list narrowed by `?~ bases` nest-fails the wet gate with `-have.%~` — the
zuse-408 hazard this repo keeps hitting. Use `=(0 (lent bases))` for the guard and cast at the call
site: `(snag bi `(list @t)`bases)`.

## R1.2.3 — temporal normalizer + liveness

### The fixture came first, and it found a second bug

Per the reduce-and-freeze procedure, `.0`'s crash was committed **before** being fixed:
`test-data/liveness/conj-statepred` (`Live == <>(x = 1 /\ y = 0)`), with its oracle goldens captured
by `gen-liveness-tests.py` — corpus 16 → 17 cases, `temporal-struct` 16 → 17 arms,
`liveness-product` 15 → 16.

That ordering paid immediately. Fixing the reported bail turned the arm from a crash into a
**structural mismatch**, which the R1.6.2 `TBGRAPH` projection then made legible:

```
expected  TABLEAU 1 / TBINIT 1
          {[]-<line 6, col 12-25>, -<line 6, col 12-25>, ()[]-<line 6, col 12-25>}

actual    TABLEAU 2 / TBINIT 2
          {[]\/ (-<col 12-16>) \/ (-<col 21-25>), ...}
```

tlc2 keeps `x = 1 /\ y = 0` as **one** `LNState` leaf spanning the whole conjunction. The port had
built a `%conj` of two `%state` leaves, so `pushNeg` applied De Morgan to it and produced a
two-node tableau where tlc2 builds one. Without the projection this would have been a silent
structural divergence behind a correct verdict.

### Two fixes, and only one of them is the parity fix

**The normalizer (parity).** `+ast:temporal` built `[%conj …]` / `[%disj …]` unconditionally. tlc2's
`OPCODE_cl`/`OPCODE_dl` build the junction, check its level, and **discard it for a level-based leaf
of the original expression when it is at or below action level**. That is the same rule the
negation, the implication, the if-then-else and the user-operator branch already follow here — the
junction cases were simply missed. With it, `x = 1 /\ y = 0` is one `%state` leaf and the tableau
matches.

**`+st-pred-bool` (robustness).** It bailed `%tlc-live-statepred-junction` on `%conj`/`%disj` where
its sibling `+cs-eval` evaluates them, and `+state-preds-of` can hand it a level-1 junction because
`le-level` of a `%conj` is the max of its children. tlc2 has no case analysis here at all —
`TBGraphNode.isConsistent` calls `tool.isValid` on the expression whatever its shape. The junction
cases are now evaluated.

The normalizer fix alone makes `conj-statepred` pass; the `+st-pred-bool` fix is kept because R1.2
is a robustness unit and a level-1 junction can reach that arm by other routes. The remaining five
bails there are above state level, where a particle member cannot be a state predicate, so reaching
them would be a real invariant violation rather than an input shape — that argument is now in the
code.

### The first adapter over a stage that iterates

`+fz-check` / `+fz-check-cfg` run the whole checker — normalize, tableau, product, SCC, lasso —
over a mutated module (cfg fixed) and a mutated cfg (module fixed). These are the first adapters
where `.1`'s budget obligation actually binds, and it is discharged rather than assumed:
`check:check` carries `live-graph-cap` itself and renders a cap-hit as `Model checking stopped:
state limit reached.`, which `+fz-check-lines` maps to `%budget`. Reach is measured by whether the
output carries a `distinct states found` line — i.e. whether the checker really ran.

Measured: **10 / 40** and **12 / 40**, lower than the `.2` stages because `check:check` needs a
module that parses, resolves *and* validates against its cfg, with a temporal PROPERTY. Floors of
5 and 6 added to `test-fuzz-reach-floors`.

### Result

`fuzz` **11/11**; 80 mutated liveness cases, no bails and no budget hits. `temporal`,
`temporal-struct` (17), `tableau`, `liveness-{product,verdict,lasso,message,accept}`, `mc`,
`sim-live`, `job`, `spec-decomp`, `trace` and `tier2` all green — the tier-2 liveness batch is still
9/9, which matters because the normalizer change touches every liveness spec.

### Hoon note

The wet-gate-on-a-narrowed-list hazard bit twice more in one increment: `(snag …)` and `(lien …)`
both nest-fail with `-have.%~` after a `?~`. Guard with `=(~ x)` and cast at the call site.
