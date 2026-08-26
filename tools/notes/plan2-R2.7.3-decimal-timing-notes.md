# R2.7.3 — decimal-literal timing and out-of-domain wording

The row named two items. **One was already done, and the other was understated.**

## The out-of-domain wording was already at parity

Both `ev-errors` and `ev-domerr` compare in full — no skips. The three wordings
the pin uses are already modelled in `+apply-oob`, and which one appears depends
on the function's value class and the argument:

```
[i \in 1..3 |-> i][9]   FcnLambdaValue  In applying the function …
F == […]  F[9]          FcnRcdValue     Attempted to apply function: …
F["x"]                  FcnRcdValue     …with integer domain to the non-integer…
```

Nothing was owed here. Checking first cost a few minutes and saved re-doing it.

## The decimal timing is a difference of VERDICT, not of timing

The row (and the support matrix) called it *"same outcome, different point"*.
Measured, that is wrong in the direction that matters.

tlc2 fails in `SpecProcessor.processConstantDefns` on a `DecimalKind` node
(`Assert.fail(EC.TLC_CANT_HANDLE_REAL_NUMBERS, ...)`), which runs while the spec
is being processed. So **any decimal anywhere in the module aborts the run
before a single state is computed**, whether or not anything evaluates it:

| spec | pin |
|---|---|
| `Dec == 1.5` never referenced | `Error: TLC can't handle real numbers.` / `1.5`, no model checking |
| `Next == x' = x /\ 1.5 > 0` | same |
| `Unused == x > 1.5` (state-level, unreferenced) | same |

The port rejected at EVALUATION. So a spec carrying an unused decimal **ran to
completion here and aborted there** — not the same outcome at a different point,
a different answer.

`+first-decimal` now scans the parse tree for an `%n-real` at spec processing,
on both paths (`+search-ctx` for the console, `+do-config` for the kernel), and
fails with EC **2244**, added to `+ec-body`. Scanning the PARSE TREE rather than
the reachable definitions is what matches "anywhere in the module".

## Two defects the corpus case caught

Neither was visible from reading; both came from writing
`desk/test-data/mc/decimal-unused` and running it.

1. **`+num-value` truncates.** It returns the first leaf under the node, so
   `1.5` came back as `1`. It is correct for `N_Number`, where there is one
   leaf, and wrong for `N_Real`, which has several. `+real-text` joins them.
2. **The pin's 2244 template is TWO LINES** — `TLC can't handle real numbers.\n%1%`
   — and every console failure here was rendered as a single cord
   (`~[(cat 3 'Error: ' msg)]`), which printed the literal on the message's
   line. `+err-lines` splits a typed failure on newlines and is now used at all
   8 console error sites, so any other multi-line template is handled too rather
   than being the next surprise.

`lore` is not in scope in this build (`-find.lore`), so the split is
hand-rolled.

## Status

`tlc-eval-error` **partial → parity**, owed 8 → 7. Evidence: `ev-errors` and
`ev-domerr` (unchanged, already comparing), the new `decimal-unused` mc case
byte-exact against the pin, and 11 shards green.
