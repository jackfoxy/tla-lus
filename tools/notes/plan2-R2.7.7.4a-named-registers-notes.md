# R2.7.7.4a — named registers

The surface R2.7.7.4's measurement found missing. `tlc2`'s register store has
two halves; the port had one.

## Pinned semantics

Measured with `PrintT` probes against the pinned jar:

| | |
|---|---|
| key rule | `TLCGetSet.NAMED_REGISTER_PREFIX` is the literal **`s:`** — and that is the whole rule: `TLCSet("plain", 7)` still raises *"The first argument of TLCSet should be a nonnegative integer"* |
| `TLCGet("s:c")` | the value; **unset is EC 2145** with the key UNQUOTED: `TLCGet(s:nope) was undefined.` |
| `TLCGetOrDefault("s:c", d)` | the value, or `d` when unset — no error, unlike `TLCGet` |
| `TLCGet("all:named")` | a RECORD name → **sequence**, one element per worker: `("s:c" :> <<2>>)` |
| coexistence | `TLCSet(3, 42)` and `TLCSet("s:c", …)` in one action leave both readable |

## What shipped

`rst` gains `named=(map @t value)` beside `regs`; `+empty-rst` is `[~ ~ 0 0]`.
`+named-key` is the prefix test. `TLCSet` writes the named half, `TLCGet` reads
it (EC 2145 when unset) and answers `all:named` as the single-element-per-name
sequence this engine's one worker produces, and `TLCGetOrDefault` reads it with
the default. `TLCExt!TLCGetAndSet` inherits it for free — its key is whatever
`TLCGet`/`TLCSet` accept.

## The bug this surfaced, which is the useful part

The first run failed with `TLCGet(s:c) was undefined.` **inside the
postcondition** — the plumbing was right and the postcondition was reading a
FRESH carrier. R2.7.7.3 evaluated postconditions under a rebuilt `eenv` with no
`rst` at all, so any register the run wrote was invisible to them.

That is not a named-register problem; it would have been just as wrong for the
integer store, and no corpus case had caught it because no postcondition had
ever read a register. `+post-cond-lines` now takes the run's FINAL carrier —
`rs.cur.r` on the safety path, and on the liveness path `+build-graph-out`
returns the carrier alongside the graph so the same is possible there. A
postcondition's own writes are visible to the NEXT postcondition, which is
R2.7.4.3's measured rule for conjuncts applied one level up.

**`_Possible`'s entire design depends on this**: `_Track` writes
`s:_possible` during the search and `_CheckName` reads it in a postcondition.
Had R2.7.7.4b been attempted first, it would have failed here with a symptom
pointing at the wrong subsystem.

## Evidence

`tlcset-named`, a new `mc` case, byte-exact against the pin: it writes both
halves from the next-state relation and reads back all five forms — direct
named read, named `TLCGetOrDefault`, an UNSET named default, the integer
register, and `TLCGet("all:named") = ("s:c" :> <<2>>)`. mc + tlcmod green.

## Left for .4b

`_POSSIBLE` itself: the two constraint positions keyed on the predicate's
level, the counting semantics (measured in passing — the counter follows
EVALUATIONS of the wrapped predicate, not accepted transitions), the
temporal-level rejection, and the generated `_CheckName` postconditions.
