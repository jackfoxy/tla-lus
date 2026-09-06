# R2.7.6.2 — the TLCExt boundary, and what was behind it

```text
Sub-unit: R2.7.6.2
Claim being measured: "closing Github1389Counting / ViolatedC is not liveness
  work: it is R2.7.7's POSTCONDITION evaluation plus one more TLCExt surface"
Measurement result: WRONG, and the way it is wrong is the unit's whole content.
  POSTCONDITION is the smaller half. With the POSTCONDITION removed, BOTH
  fixtures still fail --- one on a known defect, one on a SOUNDNESS defect no
  corpus case could see.
```

## The measurement

Both fixtures use `TLCExt` for exactly one thing: a `POSTCONDITION` over
`CounterExample`. Their liveness content is ordinary — `AtMost(4)`, a counting
safety property, and `Reach(3)`, nested eventualities. So the plan's claim was
testable directly: run each with the `POSTCONDITION` line removed from the
`.cfg` and nothing else changed. If they pass, the residue really is
POSTCONDITION alone.

They do not pass.

| case | pin | port |
|---|---|---|
| `gh1389-counting` | counter-example ends at **State 10** (`x = TRUE`) | one state longer: adds **State 11** (`x = FALSE`) |
| `gh1389-violc` | lasso `0 -> 25 -> back to 1` | lasso `0 -> **99** -> back to 1` |

Verdicts and all three counts match in both (`5/2/depth 2`;
`10001/100/depth 2`). Nothing about the search is wrong. The witnesses are.

## Finding 1 — a second instance of lasso minimality

`gh1389-counting` is `live-after-inv`'s defect again: the trace is right and
runs one state too long. It is a **better target** than the frozen case R2.7.5
left, because no post-error block is involved — this is an ordinary
counting-safety property, so the fix has nowhere to hide. Belongs to
`tlc-live-lasso` (R2.7.11).

## Finding 2 — an UNSOUND witness, and the 13-line reproducer

`gh1389-violc`'s property is `Reach(3) == <><><>(x = 99)`. The port's
counter-example passes **through `x = 99`**, which *satisfies* the property, so
the behavior it prints is not a counter-example at all.

Narrowed by four probes, each a `mc` case kept in the corpus:

| probe | property | successors | pin | port | |
|---|---|---|---|---|---|
| `live-witness` | `<>(x = 99)` | `{0, 5, 99}` | 5 | 5 | ✅ |
| `live-witness-nested` | `<><><>(x = 99)` | `{0, 5, 99}` | 5 | 5 | ✅ nesting alone is not it |
| `live-witness-many` | `<>(x = 9)` | `0..9` | varies (1..6 seen) | 8 | sound, see finding 3 |
| `live-witness-nested-many` | `<><><>(x = 9)` | `0..9` | varies | 8 | sound |
| `live-witness-rec` | `Reach(3)`, same formula via RECURSIVE expansion | `0..9` | varies, always sound | **9** | ❌ **unsound** |

The three-successor probes pass only because the choice is forced. The last two
rows differ in **one thing**: whether the nested eventualities are written
literally or reached through recursive operator expansion. Written literally the
port picks a sound witness; reached by expansion it picks the promise value
itself.

**So the expansion produces a live-expression tree that loses the inner
obligation.** R2.7.6.0 confirmed expansion against three fixtures whose shapes
could not show this: `Github1389` holds, and `Violated`/`ViolatedB` have two
states and no choice of witness. `live-witness-rec` is 13 lines and 10 states.

## Finding 3 — the witness is nondeterministic AT THE PIN, and gate 2 caught it

The first attempt froze all five goldens. `scaffold-gate.sh` gate 2 then FAILED
with four of them changed after regeneration — not a port problem: **tlc2's own
witness varies run to run.** Six runs of the same jar on the same unchanged
spec, reading the loop state:

```text
live-witness-many         x = 1, 2, 3, 2, 5, 6
live-witness-nested-many  x = 1, 8, 5, 5, 4, 8
live-witness-rec          x = 8, 5, 1, 4, 3, 5
gh1389-violc              x = 6, 64, 11, 3, 21, 11
live-witness              x = 5, 5, 5, 5, 5, 5   (choice FORCED)
```

So "the port takes the largest candidate where tlc2 takes one in its own graph
order" was **the wrong statement of a real observation**: there is no pin answer
to match. This is `tlc-dfid`'s situation exactly, and R2.5's discipline applies
— where tlc2's own answer varies, nothing can match it and no oracle says what
matching would mean, so the varying part is dropped and everything else is
compared.

`gen-mc-tests.py` gained `VARIES`: for those cases the golden AND the port's
output are projected to the verdict, the counter-example header and the counts.
`live-witness-many` and `-nested-many` are green under that projection and stay
in the corpus as regression tests.

**And this is what makes Finding 2 precise rather than anecdotal**: every one
of the pin's twelve draws above is a SOUND witness — never 9, never 99 — and
the port's is not. `live-witness-rec` and `gh1389-violc` are therefore WITHHELD
rather than projected: the projection passes on them (verdict and counts are
right) and would hide the defect.

## What this does to the row

`tlc-live-normalize` **cannot close here.** Its original claim was stale
(R2.7.6.0), its bound is a tested approved difference (R2.7.6.1) — and this
unit found a *new*, sharper residue on the same row: expansion is not just
present, it is **wrong in a way that produces an unsound counter-example**.
That is a better residue than the one R2.0 wrote, and it is measured.

The POSTCONDITION dependency stands as well, unchanged and smaller than the
plan thought: after the two defects above are fixed, both fixtures still need
`POSTCONDITION` + `TLCExt!CounterExample` to run as upstream writes them
(R2.7.7.2).

## Evidence

Three goldens frozen with their arms withheld (`gh1389-counting`,
`gh1389-violc`, `live-witness-rec`); two projected under `VARIES` and green;
three controls byte-exact. `-test /=tla-lus=/tests/lib/mc ~` — **`ok=%.y`**,
65 arms of 68 cases. `scaffold-gate.sh` PASS, including the gate 2
reproducibility check that found the nondeterminism in the first place.
