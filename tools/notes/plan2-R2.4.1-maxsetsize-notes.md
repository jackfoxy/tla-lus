# R2.4.1 — `-maxSetSize` as `limits.max-set-size`

New ledger row `limit-max-set-size` → **parity**. `tlc-driver` stays `partial`
for the rest of R2.4.

## The port already had the bound, and the same default

`lib/value.hoon`'s `max-card` is `1.000.000` — **exactly `TLCGlobals.setBound`'s
default**. The port has enforced the same limit at the same magnitude since
unit 6; what it lacked was the knob and the wording. That made this unit small,
and it is worth writing down because the row was sized on the assumption that
the bound had to be built.

## Which of the two sites is reachable — measured

`setBound` guards two places with **two different diagnostics**:

| site | diagnostic |
|---|---|
| `StateVec.grow` | `Assert.fail(EC.TLC_TOO_MNY_POSSIBLE_STATES)` = *"Too many possible next states for the last state in the trace."* |
| `ValueVec.ensureCapacity` | `WrongInvocationException` = *"Attempted to construct a set with too many elements (>N)."* |

R1.8.6 (and R2.4.0's first draft, which I wrote) named **EC 2172**. Measured at
the pin, that is the wrong one:

- `-maxSetSize 5` on `Next == x' \in 0..20` — 21 successors, far over the
  bound — ran **clean**: 442 states generated, identical to the default. The
  `StateVec` path is not reached by the exhaustive checker on that shape.
- `-maxSetSize 5` on a spec evaluating `{i \in 0..30 : TRUE}` **aborted**:

  ```
  Error: Attempted to construct a set with too many elements (>5).
  While working on the initial state:
  x = 0
  ```

  followed by the usual counts.

So the ported message is the `ValueVec` one. Note it names the **bound**, not
the actual size — a detail that only shows up by running it.

## Where it lives in the port

`+force` (`lib/value.hoon`) is the same boundary: the point at which a lazy set
must become a value. It already refused oversized sets there; it now takes the
run's bound and reports tlc2's wording.

Threading:

- `eenv` gains `setmax`, because the bound bites deep inside evaluation.
- **`+with-setmax` is a setter, not a `+make-env` parameter.** `+make-env` has
  ~30 call sites across `check`, `job` and the test shards, and only the few
  that actually hold a `limits` have anything to say; a parameter would have
  touched all thirty to pass a default.
- `bfs-opts` gains `setmax`, because `+env-of` is where a search builds its
  context. That is a kont-shape change, the same deliberate pre-release
  contract break R1.5.12b and R1.7 made.

The console path (`check:check spec cfg`) takes no `limits` and so passes 0 —
the engine default, which is tlc2's default. Console behaviour is unchanged by
construction.

## This is a parity bound

Worth being explicit, because R1.8.6 excluded the flag partly on the grounds
that the port's `%limited` is "strictly more informative": **exceeding
`setBound` FAILS the run in tlc2.** Before R2.4.1 the port ran on where tlc2
stopped — a different outcome on the same spec, not a nicer message for the
same outcome.

## Evidence

A matched pair in `tests/lib/job`: the same spec and the same bundle, run twice
with only `limits.max-set-size` different — `0` (default) completes `%ok`, `5`
fails with tlc2's exact text. One field, two outcomes, so the test proves the
bound is what decides rather than that a number matches.

## Touched

`desk/sur/tla-lus.hoon` (`limits.max-set-size`), `desk/lib/value.hoon`
(`+force`), `desk/lib/node-eval.hoon` (`eenv.setmax`, `+with-setmax`,
`+base-env`, 4 `+force` sites), `desk/lib/check.hoon` (`bfs-opts.setmax`,
`+env-of`, 19 opts literals), `desk/lib/job.hoon` (`default-limits`, 3 opts
literals), `desk/tests/lib/job.hoon`, `desk/doc/parity-manifest.md`.
