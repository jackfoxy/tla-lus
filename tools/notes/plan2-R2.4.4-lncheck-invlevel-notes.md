# R2.4.4 — `-invlevel` and `-lncheck`: documentation, verified

No code. R2.4.0 sized this XS and confirmed both are documentation-only; R2.4.4
verified both claims against the pin and **corrected one of R1.8.6's**.

## `-lncheck`: the equivalence holds, the stated mechanism was wrong

R1.8.6 recorded three effects and named two of the methods incorrectly. The
actual ones:

| effect | method / site | meaning |
|---|---|---|
| incremental check | `TLCGlobals.doLiveness()` → `LiveCheck.java:209` | `!(final\|seqfinal\|off)` |
| worker count | `TLCGlobals.doSequentialLiveness()` → `LiveCheck.java:291` | `startsWith("seq")` → 1 worker |
| final check | `LiveCheck.java:238` | `off` skips `check0` |

(R1.8.6 called these `doLiveCheck()` and `isSeqLiveCheck()`. `doLiveCheck()`
exists, but it is an `ILiveCheck` method about whether a checker is a no-op —
unrelated to the flag.)

So the mode table is:

| mode | incremental | final | workers |
|---|---|---|---|
| `default` | yes | yes | N |
| `final` | no | yes | N |
| `seqfinal` | no | yes | 1 |
| `off` | no | no | — |

**Measured** on a violating liveness spec (`<>(x = 3)` over a 4-cycle):
`default`, `-lncheck final` and `-lncheck seqfinal` are **byte-identical** —
same counterexample, same `5 states generated / 4 distinct / depth 4`.
`-lncheck off` prints `Model checking completed. No error has been found.`

**The port is `-lncheck seqfinal`**, not `final` as R1.8.6 said: the kernel runs
`%explore` to completion and *then* the `%liveness` stage, with a single worker.
The distinction is invisible on output — `final` and `seqfinal` differ only in
worker count — so the correction is a matter of naming the port's strategy
accurately, not of behaviour.

`off` is expressible by omitting `PROPERTY`, and the outputs match.

Nothing to port: the port has exactly one liveness strategy and it is a named
TLC one.

## `-invlevel`: confirmed a different subsystem

`-inv` and `-invlevel` both push `RuntimeInvariantTemplate`s into
`ParameterizedSpecObj.INVARIANT` (`TLC.java:582-614`) — the inductive-invariant
machinery, a spec-**construction** path that never reaches `processConfig`. The
port has no analogue of `ParameterizedSpecObj` at all, so this is not a driver
flag the wire could carry; it is a different tool mode.

Confirmed as R1.8.6 recorded it.

## Why this is worth a unit at all

Three of R1.8.6's twelve flag rationales have now been found wrong by
measurement (`-continue`'s premise, `-nowarning`'s polarity, `-view`'s
reachability), plus this one's method names. The inventory's *decisions* have
held up; its *reasons* have not. Checking them is cheap and the reasons are what
the next unit builds on — R2.4.1 would have pinned the wrong diagnostic string
if R2.4.0 had trusted the row.

## Touched

`desk/doc/compatibility.md` (both flag rows), `desk/doc/parity-manifest.md`
(`tlc-driver`).
