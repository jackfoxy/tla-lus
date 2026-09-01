# R2.7.9 — `tlc-driver`'s residue, re-derived

The plan row said "the two items R2.4.3 and R2.4.5 left owed" and hedged that
"two items is itself a claim". It was three, and one of the three was already
done.

## The re-derivation

| item | status, measured |
|---|---|
| `-messagesAsErrors` | **ALREADY IMPLEMENTED.** `request.promote`, `+promoted` and the promotion inside `+add-diags` are all there, with the mid-run abort semantics R2.4.5 measured (`MP.printWarning` calls `Assert.fail` BEFORE `recorder.record`, so a promoted warning never lands as a warning) and `tests/lib/job` arms. The row's "**Newly owed here**" sentence is stale. |
| `-terse` | still owed, and **my own rescope was wrong about why** |
| `-simulate stats=basic/full` | still owed, and invisible in the console projection |

## `-terse`: the blocker was misidentified

The R2 plan (mine, 2026-08-29) said *"R2.7.2 has landed, so `-terse` is
UNBLOCKED — the port now has the class it was missing"*. Measured, that is
false. Two things:

1. **It is per-Value-class, not a global switch.** At the pin,
   `SUBSET (1..3)` prints as `SUBSET (1..3)` and `(1..4) \X (1..2)` as
   `(1..4 \X 1..2)`, while a set FILTER `{y \in 1..4 : y > 1}` is **expanded
   anyway** — each `Value` subclass decides.
2. **A class tag is necessary and not sufficient.** R2.7.2 gave `%set` a `cls`,
   but the port's set is `[%set cls=@tas p=(list value)]` — the elements are
   already MATERIALIZED. Printing `SUBSET (1..3)` needs the SOURCE DESCRIPTOR
   that tlc2's lazy `SubsetValue` keeps (its base set), which the port does not
   have.

So `-terse` wants a lazy value representation, not a render flag. That is the
same family as the `FcnLambdaValue`/`FcnRcdValue` residue R2.7.2 left on
`tlc-eval-node`, and it is bigger than the row's "S".

**Approved as a difference, and TESTED**: `terse-subset` is an
approved-difference arm — golden is the pin's `-terse` output (via `opts.txt`),
assertion is the port's expanded rendering. It affects rendering only: verdict,
counts and trace shape are unchanged.

## `-simulate stats=basic/full`: an unrequested file

Measured: `-simulate stats=full` writes `<root>_actions.dot` — a Graphviz
action-flow graph — and leaves the console **byte-identical** (13 states
generated either way). So the difference is entirely a side artifact, in the
same class the appendix already excludes `Json` for: *"IO module; the wire
returns typed nouns, not serialized files"*. Nothing is accepted and ignored —
the request has no such field — so R2's invariant is not in play.

## Outcome

`tlc-driver` closes as **approved-difference**, both remaining clauses argued
and one of them pinned by a corpus arm. The stale "newly owed" sentence is
corrected in place rather than deleted, since it records what R2.4.5 measured
at the time.
