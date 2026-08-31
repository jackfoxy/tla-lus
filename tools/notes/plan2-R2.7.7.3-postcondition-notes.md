# R2.7.7.3 — POSTCONDITION, evaluated

```text
Sub-unit: R2.7.7.3
Claim being measured: "evaluated after exploration; failure is EC 2404, an
  evaluation error EC 2405; unblocks R2.7.6.2's fixtures"
Measurement result: confirmed, with three details the row did not have -- all
  of which change the code.
```

## The three details

**1. It runs after a VIOLATION too, not only on a clean run.** Measured: an
invariant violation with a postcondition prints the safety trace, then
`Error: Postcondition Post at <loc> is false.`, then the counts. So the
postcondition line sits in the same slot as R2.7.5's post-error temporal block,
and both error paths need it — not just `%ok`.

**2. On a clean run, a failing postcondition REPLACES the completion line.**
The pin prints the error and the counts, and **no** `Model checking completed.
No error has been found.` — `MP.printError` is the run's outcome. A naive
implementation appends the error and keeps the completion line, which reads as
both at once.

**3. An unresolvable NAME arrives as an unexpected exception.** R2.7.7.0
measured it; this unit reproduces it: four fixed lines, `The exception was a
java.lang.RuntimeException`, then `: The post condition X ... is not defined in
the specification.` — after the counts. It is not a typed diagnostic at the pin
and it is not one here.

## What shipped

- `+post-cond-lines` resolves each name at FETCH time (the pin's timing, not
  spec-processing), evaluates the body against an env carrying the run's FINAL
  statistics — a postcondition typically reads `TLCGet("distinct")`, and the
  counters standing before the search would answer with zeros — and renders
  EC **2404** / **2405** through `+ec-body`, both added to `lib/diagnostics`.
- `+unexpected-exception` reproduces tlc2's wrapper. It cannot go through
  `+err-lines`, which prefixes `Error: ` to everything it renders, and only the
  first of those five lines carries it.
- `+out-stats` reads the four counters off an outcome: every arm carries them,
  but `%limited` leads with `what`, so the faces do not line up across the
  union and a bare `depth.out` does not resolve.
- **Both paths**, on the same terms: the console through `sctx`'s new `pcs`,
  the kernel through the `%bfs` kont's — and, because the kernel's config is
  gone by render time, `run-spec` gains `postconditions`. That is the honest
  place for it now that the engine ACTS on them.
- `POSTCONDITION` moves `+kw-refused` → `+kw-handled`; the drift guard
  (R2.7.7.1) forces the two lists to stay exact, so the move could not be
  forgotten. `test-cfg-postcondition-refused-by-name` became
  `test-cfg-postcondition-is-handled-not-refused`, which says the move was
  intended rather than accidental.

## Evidence

`cfg-post-false` and `cfg-post-undef` — frozen by R2.7.7.0 with their arms
withheld — now pass **byte-exact** and are emitted. mc 74 cases; cfg-runspec,
job and app green.

The tier-2 census moves rather than closes: `SubseteqNextState` is refused one
keyword LATER now, on `_POSSIBLE`, which is R2.7.7.4's. Its entry was re-frozen
from the ship run for the second time this unit-chain — the first draft of the
R2.7.7.1 entry predicted the wrong keyword, and this is the same lesson from
the other direction: the census records what the port DID, and the port's
answer changes as capability lands.

## Deferred, with reasons

- **`-postCondition mod!op`** (the CLI form). It is a REQUEST field, not a
  `.cfg` keyword, so it is a wire addition rather than a config path — and no
  corpus case uses it. R2.7.7.1's invariant is unaffected: the flag does not
  exist on this wire, so nothing accepts and ignores it.
- **`TLCExt!CounterExample`**, which a postcondition may read after an error.
  No corpus case in this unit needs it; `Github1389Counting`/`ViolatedC` do,
  and they are R2.7.6.2's, which named this dependency. It wants the trace as
  a VALUE, which is its own piece of work.

Both are recorded on `cfg-postcondition` so the row does not read as closed.
