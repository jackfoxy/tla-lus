# R2.7.13 — residue triage: three decisions, and one that measurement changed

```text
Sub-unit: R2.7.13
Mandate: three named residues sitting on TERMINAL rows, so ledger closure
  cannot see any of them. "Each gets a decision: do it here (a and b are
  small), or an appendix entry plus a compatibility.md row (c is the L one).
  What is not allowed is the third option, which is what happens by default."
Outcome: (a) FIXED here. (b) measurement made it NOT small -- row DEMOTED with
  the exact rule and 12 frozen goldens. (c) documented, with the recorded
  description CORRECTED.
```

## (a) EC 2112 folded into `%property` — FIXED

tlc2 has three property codes:

```text
2108  TLC_PROPERTY_VIOLATED_INITIAL           implied INIT, level<=1 predicate
2112  TLC_ACTION_PROPERTY_VIOLATED_BEHAVIOR   implied ACTION, [][A]_v
2116  TLC_TEMPORAL_PROPERTY_VIOLATED          a temporal property
```

R2.7.1 split 2107/2110 for invariants by adding `initial=?`, and `%property`'s
flag distinguishes 2108 (`&`) from 2116 (`|`). 2112 had no representation and
arrived as `[%property name |]` — the same wire value as 2116, so a caller
could not tell a broken STEP from a broken BEHAVIOR.

`violation` gains `[%action name=@t]`. One emit site changes.

**Why it was one edit**: DFID is the ONLY engine that produces an
implied-action violation. `+check`'s console path renders the diagnostic
(`Error: Action property <name> is violated.`, byte-exact since R1.8.1.2) and
returns a `wain` with no typed result; `+run-check` and the job kernel do not
route an implied action at all. No test asserted the folded value.

That last fact is a finding in its own right and is recorded on
`tlc-safety-assume` (already `partial` from R2.7.12): the
`processConfigProps` routing this row claims exists on one of three engines.
R2.7.12's multi-PROPERTY defect is the same gap seen from the other end.

## (b) The FUNCTION representation class — NOT small, row DEMOTED

R2.7.2 closed `tlc-eval-node` and left one skip, `ev-tupbind`'s `FcnT`,
described as *"the same treatment on `vfcn` — another arm, another cycle,
another measurement."* This unit took the measurement.

**The rule is one line of `Tool.java` (OPCODE_fc / nrfs / rfs):**

```java
boolean isFcnRcd = true;
for (int i = 0; i < dvals.length; i++) {
  dvals[i] = this.eval(domains[i], ...);
  isFcnRcd = isFcnRcd && (dvals[i] instanceof Reducible);
}
...
if (opcode == OPCODE_rfs) { fval.makeRecursive(fname); isFcnRcd = false; }
if (isFcnRcd && !EvalControl.isKeepLazy(control)) return (Value) fval.toFcnRcd();
return fval;
```

`Reducible` has **exactly two implementors in the whole tree** —
`IntervalValue` and `SetEnumValue`. So the function class is decided by the
DOMAIN's class and nothing else. That part is small.

**What is not small**: the same predicate governs the BINARY SET OPERATORS, and
R2.7.2's mapping of them is wrong — for a reason worth recording, because it is
the same reason four other units have now hit.

R2.7.2 wrote, honestly and with evidence: *"MEASURED, not assumed. Across every
`eval-core` golden the pin emits exactly three non-enum set classes ... `\cup`,
`\cap`, `\` and UNION all print SetEnumValue there."* True — of every golden it
had, **because every operand in all of them was Reducible.**

```text
(1..3) \cup {4}                  SetEnumValue     both operands Reducible
((1..2) \X (1..2)) \cup {<<9,9>>} SetCupValue     one operand is not
((1..2) \X (1..2)) \cap ...       SetCapValue
((1..2) \X (1..2)) \ {...}        SetDiffValue
UNION {(1..2) \X (1..2)}          UnionValue
[(1..2) -> (1..2)]                SetOfFcnsValue  R2.7.2 left these UNMEASURED
[a: 1..2]                         SetOfRcdsValue  rather than guess -- correctly
```

Same operator, different class, decided by the operands. New corpus case
`ev-lazyclass` pins all of it: **12 definitions diverge and every VALUE agrees**
— only the class column, as on this row from the beginning. Frozen with
per-definition skips naming the rule.

**Decision: demote `tlc-eval-node` `parity` -> `partial`** (R1.4.3's rule —
measured, not inferred) and size the fix as its own unit:

1. `+sexp-class` becomes recursive: an operator's class depends on whether its
   operands are Reducible, which in port terms is `%set-enum` (the port's
   `%intv` values also read as `%set-enum` there, and Interval is Reducible, so
   that collapse is correct here).
2. It gains `%set-cup` / `%set-cap` / `%set-diff` / `%union` and the measured
   `%fcns` / `%rcds`.
3. Then the function class in `+kind-of`, keyed on the domain's — which needs
   **no `vfcn` mold change**, because `+kind-of` already decides the RECURSIVE
   case from the EXPRESSION rather than the value.

**Why not ship step 3 alone today.** It would close the `FcnT` skip and be
green on the whole corpus — and it would be green for exactly the reason
R2.7.2's `\cup` rule was green: every function domain in the corpus is
Reducible. `[x \in (A \cup B) |-> e]` with a lazy operand would be wrong the
day someone wrote it. That is the "third option" this unit's mandate forbids,
wearing a fix's clothes.

## (c) The carrier boundary — documented, and the description CORRECTED

R2.7.4 recorded: *"a draw or a `TLCSet` inside an EXPRESSION-position `\E` /
`\A` / `CHOOSE` / set comprehension ... is evaluated and its effect
discarded."*

Measured, the boundary is **bidirectional**, and the READ side is the one a
user hits first:

```tla
Init == x = 0 /\ TLCSet(0, 7)           \* ACTION position: carried
Inv  == \E i \in 1..3 : TLCGet(0) = 7   \* EXPRESSION position: not carried
```

| | pin | port |
|---|---|---|
| `INVARIANT Inv` | `Model checking completed. No error has been found.` | `Error: TLCGet(0) was undefined.` |

The write in `Init` lands; the read inside the expression-position `\E` sees an
EMPTY carrier, so `TLCGet` FAILS where tlc2 returns `7`. A typed error rather
than a silently different answer — the port's doctrine, and the reason this is
approvable rather than owed. ACTION-position `\E` is unaffected
(`+solve-exists` has carried since R2.7.4.1a).

**Decision: appendix + `compatibility.md` section** (`## Release R2.7.13 — the
carrier boundary`), with the measurement in it. Rows unchanged; R2.7.4's
sizing (*"a unit of its own"*) confirmed rather than shrunk.

## Ledger

`tlc-eval-node` `parity` -> `partial`. **130 terminal / 4 owed** (was 131 / 3).
The unit's mandate was triage, and one of the three turned out to be a row that
should never have been terminal — which is what triage is for.

## The pattern, for the eleventh time

R2.7.2's `\cup` rule and R2.7.5's closer and R2.7.12's property name were all
generalizations from a corpus that happened to be uniform in the deciding
dimension. The tell each time was a claim of the form "measured, all N cases
agree" where N shared a property nobody had named. When a rule is read off
goldens rather than off the Java, write down what the goldens have in common
BEFORE concluding the rule holds.
