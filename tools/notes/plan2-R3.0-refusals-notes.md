# R3.0 — the three refusals R2.8.2b found, closed

```text
Sub-unit: R3.0 (a, b, c)
Rows: cfg-runspec, tlc-eval-node, tlc-eval-action -> all three `parity`
      check-mode-generate -> DEMOTED `parity` -> `partial` (see §5)
Planned: close the three refusals `test-tlc-examples-batch` froze at R2.8.2b,
  each by making its censused spec agree.
Found: all three are small once measured, and all three had been NAMED in the
  ledger's own prose as somebody else's residue. Two of the three plans in the
  R3 file were wrong in a detail that would have shipped a wrong answer.
```

Each of the three was a REFUSAL — the port answered a typed error where tlc2
answered a verdict — so none was ever a wrong result, and each stayed invisible
for as long as no spec in the corpus had the shape.

## 1. R3.0a — a config with no behaviour spec

`+resolve-targets` required INIT+NEXT or a SPECIFICATION. tlc2 requires
neither: with no behaviour spec it runs an ordinary breadth-first search over
**zero initial states** and prints

```
Model checking completed. No error has been found.
0 states generated, 0 distinct states found, 0 states left on queue.
The depth of the complete state graph search is 0.
```

`+search-ctx-seed` now detects the total absence of a behaviour spec and builds
the search context with no initial states and `%nullodn` bodies the search
never reaches. An INIT without a NEXT is still the config error it always was —
only the *total* absence takes this path.

**The refusal was worse than a missing feature.** It fired at
`check.hoon:2520`, before `+check-assumes` at `:4276`, so the port did not
check the assumptions either — which is the entire content of such a module.
That is the shape to look for elsewhere: a guard placed early enough to skip
work that had nothing to do with what it was guarding.

Two Hoon details cost a build cycle each and are the same mistake twice: a
`?:` whose branches are a hand-written literal and a typed call **loses the
faces**, so `-find.init.p.rt` and then `-find.p.ir`. Annotating the literal's
own fields does not fix it; casting the whole `?:` to the real type does
(`=/ rt=(each [init=… next=… …] @t)`, `=/ irc=sout:ne`).

## 2. R3.0b — a LAMBDA as an operator-valued argument

`+resolve-oparg` asked `ops.e` for a NAME. An anonymous `$OpArg` has none, so
it answered `~` and both binder sites raised.

The fix is that there was nothing to look up: R1.3.1's `+lambda-of` already
encodes everything the definition needs — parameters in `bound`, the generated
body as the args TAIL — so new `+lambda-def` **builds** the `sem-def` instead.
That is what SANY does too (a synthesized `OpDefNode` the `OpArgNode` points
at), which is the point: the two halves were never different work, one of them
just had no owner after R1.3.1 closed the front-end half and R1.4.1b's sentence
kept calling the rest "a unit-3 residue".

## 3. R3.0c — a multi-binder existential in action position

Several binders are **one odometer**, not a different construct: `Tool.contexts`
builds ONE `ContextEnumerator` over every bound group. Two properties of it
were measured before writing any code, and a reasonable guess gets both wrong:

* **Every domain is evaluated in the OUTER context.** `contexts()` passes the
  same `c` to each `eval(domains[i], …)`, so the bounds of
  `\E i \in S, j \in T` are INDEPENDENT — unlike a function constructor's,
  which `+ctx-doms` deliberately binds prefix-wise. The first draft of
  `+bound-domains` threaded the prefix and would have been wrong.
* **`ContextEnumerator.nextElement` advances index 0 first** and carries
  upward, so the LEADING binder varies FASTEST. A nested loop written the
  natural way (head group outermost) produces the opposite order.

New `+bound-domains` and `+bind-rows`; `+solve-exists` AND `+solve-forall` both
take them — the universal is the sibling the same refusal covered, and the
standing lesson says to grep the bin rather than fix the reported one.

**The `mc` case is chosen so the ORDER is observable.** `multibind` ranges
`\E i \in 1..2, j \in 1..3` and checks `x + y < 5`, and its golden carries
7 distinct, **5 states left on queue**, and the reported violation
`/\ x = 2 /\ y = 3`. A set of successors would agree under either odometer
direction; a queue count and a trace do not.

**Paxos is out of the nightly batch on COST, not capability.** It is the spec
that surfaced this and the port no longer refuses it — it explores. But tlc2
answers in 4.2 s and the port had not finished in ~50 min (nor, safety-only
with the PROPERTY stripped, in ~25 min), which is more than the entire tier-2
shard costs today. Recorded in `gen-tier2-tests.py` beside the batch, so the
next reader sees a measured exclusion rather than a gap.

## 3b. The sibling sweep R3.0b's fix actually needed

The standing lesson says: after fixing one instance, GREP THE WHOLE BIN. Doing
that for the LAMBDA gap found **eleven frozen skips carrying the same false
reason** — *"LAMBDA is not in the WU3 semantic graph (unit-3 residue)"*, which
stopped being true at R1.3.1:

* `gen-core-eval-tests.py`: `ev-oparg`'s `A3`, `A4`, `Sel`
  (`Apply(LAMBDA n : n * 2, 7)`, `Fold(LAMBDA a, b : a + b, 3, 4)`,
  `SelectSeq(<<1, 2, 3, 4>>, LAMBDA n : n % 2 = 0)`).
* `gen-stdops-tests.py`: eight more across `SelectSeq`, `BagOfAll` and
  `SortSeq`, including their error cases.

All eleven retired. `core-eval` **155 -> 158** compared definitions, stdops
**91 -> 99**, both `ok=%.y`.

**And retiring them surfaced one real difference the skips had been hiding.**
`SortSeq(<<1, 2>>, LAMBDA x, y : x)` — a comparator that returns a non-boolean
— draws EC 2169 on both sides, but the pin renders the VALUE the comparator
returned (`2`) where the port had a hardcoded `<Operator>` placeholder. That
placeholder was correct only while a LAMBDA could not be applied at all; once
it can, the applied result is what tlc2 names. Fixed to route through
`+arg-error:so` like every other EC 2169 site. **A skip does not just defer a
case, it hides everything downstream of it** — this message had been wrong for
as long as the skip existed and nothing could see it.

**And the full suite then caught the other half of it**, which no shard this
unit ran could: `tests/lib/tlcmod`'s hand-written
`test-sort-seq-not-boolean` asserted the old `<Operator>` placeholder. It is
hand-written, so no regenerated golden could see it going stale — R1.8.8's
lesson for the third time in this project. Corrected against the pin rather
than against the port: `Bad(x, y) == x` over `<<1, 2>>` answers `2` at the pin,
measured directly.

**The sibling here is a NON-generalization, and measuring it was the point.**
`SelectSeq` with an operator that returns a non-boolean prints
`<Operator NotBool>` at the pin — the operator, not the returned value — so
`+op-arg-error` is right there and `tests/lib/seqs` was NOT touched. tlc2's two
implementations genuinely differ. Assuming SortSeq's rule generalized would
have broken a correct arm to match a wrong one.

## 4. What the batch looks like now

`test-tlc-examples-batch` is **3/3 agreeing** and `TLC_EXAMPLES_DIVERGENCES` is
empty: `Channel` (record sets, agreed from the start), `SimpleMath` (R3.0a),
`CigaretteSmokers` (R3.0b).

**`PrintValues` did not join it, and the R3 plan said it would.** R3.0a's row
predicted it as the second no-behaviour-spec supplier once the refusal went.
Measured, it brings a DIFFERENT row: its assumptions are `Print(…)` calls, so
it fails on `TLC!Print` — `tlc-module-tlc`'s standing approved difference, this
engine having no output channel. Adding it would have censused an approved
difference under another row's name. A plan sentence written one unit earlier
was wrong about a spec nobody had run.

## 5. The row this unit OWES, and why it is not a regression

`+psolve`'s `$BoundedExists` / `$BoundedForall` still refuse multiple binders,
in PROBABILISTIC mode (`-generate` / `-simulate`). Until R3.0c the exhaustive
path refused it too, so the engine was uniformly wrong and the gap was charged
to `tlc-eval-action`. Now one engine runs the construct and the other does not,
which is an asymmetry that belongs to whoever owns the probabilistic path —
`check-mode-generate`, **demoted `parity` -> `partial` here**.

It is deliberately not fixed by extending the odometer, because the ordering is
the whole content: `Tool.getNextStates` takes `Ordering.RANDOMIZED` for
OPCODE_be, and `ContextEnumerator` calls `enums[i].reset()` on every carry — so
whether a `SubsetEnumerator` RESEEDS on reset decides the RNG call sequence and
therefore which successor a `-generate` run picks. That is one measurement, and
guessing it yields exactly the confidently-wrong answer this ledger exists to
prevent. The refusal message now names the engine and the unmeasured thing
rather than reading like the exhaustive path's.

Ledger: **134 rows, 133 terminal, 1 owed.**

## Evidence

* 16 shards green: `mc` (105 arms), `stdops`, `stdops-diff`, `core-eval`,
  `bags`, `stream`, `safety-gen`, `neval-action`, `neval-mc`, `neval-probe`,
  `node-eval`, `sim`, `sim-diff`, `sim-live`, `sim-stats`, `generate-diff`,
  `dfid`, `job`, `inv-constraints`, `cfg-runspec`, `spec-decomp`, and the
  regenerated `test-tlc-examples-batch` (3/3, 9.6 s).
* `mc` shard `ok=%.y`, **105 arms**, including the three new cases
  `nospec-assume`, `oparg-lambda`, `multibind` — all byte-exact against the pin
  (arm count checked against the shard's own `++ test-` count, because a
  missing fixture makes an arm silently not run).
* `test-tlc-examples-batch` probe: `Channel`, `SimpleMath`, `CigaretteSmokers`
  all agree; the only failure in that probe was `PrintValues`, on `TLC!Print`.
* `lib/check` and `lib/node-eval` build clean on the ship (`gall: bumped`).
