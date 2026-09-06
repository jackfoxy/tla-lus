# R3.2 — the rule's follow-ons, and what the first bags supplier found

```text
Sub-unit: R3.2
Rows: tlc-value-composite -> DEMOTED `parity` -> `partial` (a WRONG ANSWER)
      cfg-runspec: a second refusal closed (the sibling R3.0a missed)
Planned: run R2.8.2b's corrected rule and act on its three named follow-ons --
  add a `tlc-module-bags` supplier from test-model, add `Paxos` as the symmetry
  differential now that R3.0c unblocked it, and record the rows with no
  supplier.
Found: one of the three follow-ons is impossible, one is a cost exclusion, and
  the one that worked found a defect in a DIFFERENT row -- a wrong answer in
  core value equality that nine units of green evidence could not see.
```

## 1. (b) is impossible, and the rule was proposing it

The plan said: *"After R3.0c, add `Paxos` as the symmetry differential it was
selected to be."* Two measurements say no, and the second is a defect in the
tool:

* **`Paxos` is out on cost** — R3.0c already measured it (tlc2 4.2 s, the port
  not finished in ~50 min, nor safety-only in ~25).
* **`Github432` — the corpus's only other SYMMETRY candidate, and the one the
  rule now ranked FIRST — cannot be run at all.** Its config is a Java-unit-test
  TEMPLATE: `CONSTANT Humans = {%1%}`. The pinned jar answers `Error: TLC threw
  an unexpected exception.` So the rule was proposing a spec that cannot be a
  comparator case in any port state.

`tools/tier2-select.py` now treats a config containing `%1%`-style placeholders
as no config at all, alongside the specs that have none. It is the only such
config among the 218 `check`-class specs — and one was enough to hand this unit
a candidate that does not exist. Same class as the four defects R2.8.2b fixed
in the same tool: the rule checked that a config EXISTS, never that the pin can
RUN it.

**So `tlc-safety-symmetry` has no viable tier-2 supplier in either corpus**, and
that is now a measured statement rather than an open expectation.

## 2. (a) worked, and cost two findings on the way in

`BagsTest` is the corpus's only `tlc-module-bags` supplier that is flat enough
for `TLC_BATCH` (the other three — `suite/test23bis`, `test36`, `test50` — are
subdir specs the batch cannot address). Getting it to run at all needed a fix,
and running it found a defect.

### 2a. A SPECIFICATION with no initial predicate is not an error either

`BagsTest`'s spec is `Spec == [][TRUE]_<<>>` — a dummy, so TLC runs and checks
the 126 ASSUMEs. `+resolve-targets` refused it: *"the SPECIFICATION has no
initial predicate"* (`check.hoon:2456`). tlc2 answers it exactly as it answers a
config with no behaviour spec at all — zero initial states, `Model checking
completed`, 0/0/0, depth 0.

**R3.0a fixed the sibling seven lines earlier and did not sweep the bin.** The
init is now handed on as `%nullodn`, the same marker R3.0a's path uses, and
`+search-ctx-seed` reads THAT rather than carrying a second flag, so both
shapes take one code path. Charged to `cfg-runspec`, which R3.0a had just
closed — no demotion, because the row closes again in the same unit.

### 2b. The real find: a RECORD does not compare equal to a FUNCTION

With the spec running, 6 of the 126 assumptions fail. Bisected in two ship runs
(8 groups, then 22 single-assumption arms) rather than 126 module evaluations,
which was measured at over 25 minutes and abandoned:

```
AS82   h (+) h = [a |-> 6, b |-> 4, c |-> 2]
AS83   [c |-> 3, d |-> 2, e |-> 1] (+) h = [a |-> 3, ...]
AS93   [c |-> 3, d |-> 2, e |-> 1] (-) h = [c |-> 2, d |-> 2, e |-> 1]
AS106  BagUnion({[a |-> 3, ...], [c |-> 3, ...]}) = [a |-> 3, ...]
AS124  BagOfAll(LAMBDA elem : elem, h) = h
AS126  BagOfAll(LAMBDA elem : IF elem = "a" THEN "b" ELSE elem, ...) = [b |-> 5, c |-> 1]
```

They are **exactly** the assumptions whose EXPECTED VALUE is a record literal.
Every tuple-shaped or `:>`-built expectation passes — including
`BagOfAll(LAMBDA elem : TRUE, h) = TRUE :> 6`, which takes a record as INPUT.
So it is not the bag arithmetic and not Bags at all.

Confirmed on four lines with no Bags in them:

```tla
ASSUME([a |-> 1] = ("a" :> 1))                       \* pin TRUE, port FALSE
ASSUME([a |-> 1, b |-> 2] = ("a" :> 1) @@ ("b" :> 2)) \* pin TRUE, port FALSE
ASSUME([x \in {"a"} |-> 1] = [a |-> 1])              \* pin TRUE, port FALSE
ASSUME(DOMAIN [a |-> 1] = {"a"})                     \* both TRUE
```

**Cause, one line**: `+fcn-like` (`lib/value.hoon:93`) is
`?=(?(%fcn %seq) -.v)`. It admits a tuple but not `%rec`, so `+equal-norm`
never takes the function path for a record and falls through to a `%rec`-only
branch; `+fcn-pairs` has no `%rec` case either. In TLA+ a record IS a function
whose domain is a set of strings, and tlc2's `RecordValue` compares equal to
`FcnRcdValue`. `lib/value.hoon:141` even says so in a comment — *"1..n) and a
record (string domain). Bags are exactly these values"* — the code knows; the
equality does not.

**Why nine units of green said nothing.** `tlc-value-composite`'s evidence is
`ev-composites` / `ev-lookup` / `ev-sets` / `ev-domain`, compared **byte-exact
on RENDERING**. A rendering differential cannot see an equality: both values
render the same, and nothing in the corpus ever asked whether they ARE the
same. R2.7.13's lesson in a new place — the corpus was uniform in the deciding
dimension.

**Why it is not fixed here.** Making them equal is a STATE-IDENTITY change: two
values that compare equal must also fingerprint equal, or the checker counts
two equal states as distinct and every `distinct` count moves. That is
R2.3.1's class of risk and belongs in its own unit, with `+fp-enc` and
`+normalize` measured alongside `+equal-norm`.

Frozen both ways: the `mc` case **`rec-fcn-eq`** (golden captured from the pin,
arm withheld via `SKIPS` with the reason printed on every run) and the
`tlc-batch` census entry for `BagsTest`, which is machine-checked — the arm
asserts the exact divergence list, so a fix or a new divergence fails the test.

## 3. (c) and (d), recorded

* **`cfg-view`** and **`semantic-graph`** (INSTANCE) have no in-scope supplier
  in either corpus at the pin. Their evidence stays tier-1-only —
  `cfg-view`'s matched `view`/`view-off` pair (R2.3.1) and `semantic-graph`'s
  108 `sem` cases — and that is now written down rather than left as an open
  question the rule re-raises every run.
* **`reals` is NOT coverage debt.** It maps to `tlc-module-excluded`, which is
  the port correctly excluding `Reals`; a spec that exercises it would be
  measuring an exclusion.
* **The guard stays and grew.** `tier2-select.py` already checked its
  feature→row table against the ledger's row names (which found eleven invented
  rows at R2.8.2b); it now also refuses to propose a spec whose config is a
  test template.

## 4. State

Ledger **134 rows, 132 terminal, 2 owed**: `check-mode-generate` (R3.0c, the
probabilistic multi-binder path) and `tlc-value-composite` (this unit).
`tlc-batch` is 15 specs with 1 censused divergence; `mc` is 105 arms with 1
withheld.
