# R2.7.14b — `TLCExt!CounterExample` and `-postCondition mod!op`

```text
Sub-unit: R2.7.14b
Rows: tlc-live-normalize  partial -> parity
      cfg-postcondition   partial -> parity
Ledger: 130 terminal / 4 owed  ->  132 terminal / 2 owed
```

R2.7.14a measured the mechanism and wrote it down, so this unit was
implementation against a known target. What it added, and what turned out to
matter.

## The value

`CounterExample` is `TRUE` in `TLCExt.tla` — a placeholder behind a Java
`@Evaluation` override that reads the value out of the evaluation Context:

```java
final Object lookup = c.lookup(tool.getCounterExampleDef());
if (lookup instanceof Value) return (Value) lookup;
return new CounterExample();   // no counter-example: the EMPTY record
```

The port registers `['TLCExt' 'CounterExample' 0]` as an arity-0 node-op and
reads a new `ce` slot on `eenv` — the same slot shape `run` uses for the live
statistics, and the port's analogue of a Context entry. It is filled only
while a POSTCONDITION is evaluated, exactly as tlc2 conses it onto an
otherwise EMPTY Context for that one call. `~` falls back to the empty record,
so `CounterExample.state = {}` on a clean run: the test `_JsonTrace` and
`_DotTrace` use to detect "no violation", pinned by `ce-empty`.

Shape (`CounterExample.java`):

```text
[ state  |-> { <<n, [vars]>> } ,
  action |-> { <<from, actionRec, to>> } ]

actionRec == [name |-> "Next",
              location |-> [beginLine, beginColumn, endLine, endColumn, module]]
```

`context` and `parameters` — which tlc2 adds when the action TAKES parameters
— are UNMEASURED here: no corpus action has any. They are absent rather than
guessed, the discipline R2.7.2's `%fcns`/`%rcds` entry established and
R2.7.13 then had to correct precisely because a guess had been avoided.

## The one thing worth knowing: `loopOrdinal` is not always the loop

There are two liveness call sites and they build DIFFERENT graphs.

```text
LiveCheck.java:854   new CounterExample(states)                    loopOrdinal 0
                     the "safety-like" violation -- the comment there says
                     "treat it as a lasso where the last state stutters
                     forever" -- so NO closing edge is appended
LiveWorker.java:1015 new CounterExample(states, action, stateNumber)
                     the genuine lasso, closing edge appended
```

Both upstream fixtures depend on the difference, in opposite directions:

| fixture | states | actions | why |
|---|---|---|---|
| `gh1389-counting` | 10 | **9** | forward edges only — no closing edge |
| `gh1389-violc` | 2 | **2** | one forward, one closing, both endpoints asserted |

**The port already computes the discriminator.** A counter-example with no
closer is exactly `+box-free-tf`'s — R2.7.11a's rule — so `loopOrdinal` is
`0` when box-free and the loop target otherwise. R2.7.11a and R2.7.14b turn
out to be the same fact seen from two sides: whether a finite prefix
discharges the obligation decides both whether a closer prints and whether
the counter-example graph has a closing edge.

`LiveWorker` reaches the postcondition through `tool.getDebugger()`, which
is not a no-op — `ITool.getDebugger()` returns `TLCGlobals.mainChecker.tool`
when no debugger is attached. Worth checking rather than assuming, because
"it goes through the debugger" reads like "it does not run".

## `-postCondition mod!op`

A `postconditions=(list [module=@t op=@t])` field on `check-opts`, welded onto
the config's list IN ORDER — tlc2 appends both to one `POST_CONDITIONS` list
that `Spec.getPostConditionSpecs` resolves together, so this is a second entry
point into R2.7.7.3's machinery rather than a second mechanism.

A pair rather than the `mod!op` text: splitting on `!` and rejecting an empty
half or an embedded dot is CLI-argument hygiene, not a property of the
postcondition, and this wire has no CLI.

**The module half is checked and a mismatch is REFUSED.** The port's `defs` is
keyed by bare name, so honouring `Other!Post` would silently run the root
module's `Post` — accepting an option and doing something else, the one thing
R2.1 forbids. tlc2 would not find it at all; a refusal naming the mismatch is
reproducible where a guessed diagnostic would not be.

`-dumpTrace <fmt> <file>` installs postconditions through the same
`POST_CONDITIONS` list (`_JsonTrace`, `_TLAPlusCounterExample`, `_TLCTrace`,
…) and belongs to `tlc-driver`, not here.

## Both directions, because a silent pass proves nothing

Restoring the POSTCONDITION line to `gh1389-counting` changes the pin's output
NOT AT ALL — the assertion holds and nothing prints. R2.7.14a caught that and
this unit acted on it:

- `gh1389-counting` and `gh1389-violc` run WITH their upstream POSTCONDITION
  and pass — the strongest available check, since each is upstream's own
  regression test for this operator.
- `Cardinality(S) = 10` → `= 11` on `gh1389-counting` was run by hand and
  produced the pin's EC 2404 line, proving the assertion is evaluated.
- `ce-lasso` asserts the closing edge deterministically (`gh1389-violc`'s
  witness varies at the pin); `ce-lasso-false` asserts three actions where
  there are two and MUST fail.
- `ce-empty` pins the clean-run empty record.

Endpoints in `ce-lasso` are compared as `a[1][1]` rather than against a record
literal: a record field named after a declared VARIABLE draws six lines of
SANY lint per occurrence, which would have buried the assertion in the golden.

## Evidence

**1145 arms, `ok=%.y`, 0 FAILED** across `mc` (94 cases), `job`, `clay-load`,
`cfg-runspec`, `tlcmod`, `core-eval`, `stdops`, `liveness-message`.

Ledger **132 terminal / 2 owed** — `tlc-safety-assume` (R2.7.15) and
`tlc-eval-node` (R2.7.16) are what is left before R2.9 can assert closure.
