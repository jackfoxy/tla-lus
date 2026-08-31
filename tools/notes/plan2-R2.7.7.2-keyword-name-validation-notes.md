# R2.7.7.2 — the keyword names the pin resolves EARLY

```text
Sub-unit: R2.7.7.2
Claim being measured: "the pin rejects a postcondition that names nothing,
  names a constant, or takes arguments -- three ECs, cheap and independent"
Measurement result: SPLIT. Three of the four keywords validate EARLY and are
  matchable now, byte-exact. POSTCONDITION does not, and its clause moves to
  R2.7.7.3. And the must-not-be-constant rejection does not fire at all.
```

## What is early and what is not

`SpecProcessor` calls `processRLReward`, `processPeriodic` and
`processConfigPossible` at construction (lines 944-948) — before a single
state. Measured at the pin, a bad name there produces a clean diagnostic and
**no counts**, because the run never starts:

```text
Error: The periodic NoSuchOp specified in the configuration file
is not defined in the specification.

Error: TLC requires periodic not to take any argument, but one was given: Two
```

POSTCONDITION resolves in `Spec.getPostConditionSpecs`, called after
exploration — R2.7.7.0 measured the pin printing the state counts first and
only then throwing. **An early check cannot reproduce that**, so this unit does
not try: the POSTCONDITION clause lands with the evaluation in R2.7.7.3, where
the timing can match. That is the sub-unit's boundary moving on evidence, not
scope being dropped.

## The rejection that does NOT fire, and why it matters

`processRLReward` carries a must-not-be-constant branch (EC 2233), and it is
**unreachable**. The lookup is in SpecProcessor's SNAPSHOT, not in `defns`,
precisely because — the source says so — "any constant expression in defns will
have been evaluated into a Value". So a constant-valued definition is still an
`OpDefNode` and is accepted. Measured: `_RL_REWARD Konst` with `Konst == 1 = 1`
runs to a normal verdict.

`+ck-snapshot-def` therefore omits 2233 deliberately, and
`test-cfg-keyword-name-constant-is-accepted` pins that. Reusing the existing
`+ck-action` — which is otherwise the identical shape — would have rejected a
config the pin accepts, and no corpus case would have caught it.

`processPeriodic` has no constant branch at all: two rejections, not three.

## Where it went

`+ck-keyword-names` is called from **both** paths, because they do not share
one: `+validate-config` (kernel) gains it as the LAST link of its fail-fast
chain, matching `SpecProcessor`'s own ordering, and `+search-ctx-seed`
(console) calls it directly — the console never calls `validate-config` at all,
so without this a caller there would see R2.7.7.1's "unsupported" refusal for a
config the pin rejects with its own diagnostic.

**Order matters and is the point of the unit**: the name check runs BEFORE the
refusal. A malformed name is the pin's diagnostic; only a well-formed one is
this port's refusal.

The port already had the exact machinery — `+v-notdef` / `+v-noarg` produce the
pinned message text and `+ck-action` the 2229/2233/2228 shape for INIT/NEXT —
so this is four call sites and one variant, not new diagnostics.

## Evidence

Four new `mc` cases, all **byte-exact** against the pin and all passing:
`cfg-periodic-undef`, `cfg-rlreward-undef`, `cfg-possible-undef` (EC 2229, both
lines) and `cfg-periodic-arg` (EC 2228). Four new `tests/lib/cfg-runspec` arms:
the three not-defined rejections, the takes-an-argument rejection, a resolvable
name that must NOT be rejected, and the constant case above. Shard 13/13.

## Rows

`cfg-internal-kw` and `cfg-possible` keep `partial` — their name validation is
now at parity, their capability is not (R2.7.7.4/.5). `cfg-postcondition` is
unchanged by this unit and says why.
