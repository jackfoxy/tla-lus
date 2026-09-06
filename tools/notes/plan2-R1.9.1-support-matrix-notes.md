# P2-R1.9.1 — the compatibility support matrix

The row: *"Complete the `compatibility.md` support matrix — every row an
explicit green / approved-difference entry with its evidence, no prose-only
claims."*

Measured, this one was **right**, and the document was worse than the row
implied. Two problems, of different kinds.

## 1. The release matrix was stale in every quantitative field

`compatibility.md` opens with a release matrix — the table a reader checks
first. Every number in it was wrong:

| claimed | actual |
|---|---|
| agent state `%1` (migrates from `%0`; `lib/migrate`) | `%3`; `lib/migrate` was **deleted** by R1.5.12b |
| scaffold gate: 9 gates | 11 |
| parity ledger: 65 rows, 35 still owed | **125 rows, 0 owed** |
| "the ledger still carries `partial`/`absent`/`oracle-only` rows" | it does not, as of R1.8.6 |

`lib/migrate` again. That single deletion has now been found stale in four
places by three different units: `scaffold-gate.sh` gate 6 (R1.8.8), the ledger's
`op-gall-version` row and port-map §4 (R1.9.0), and this table. A file that is
deleted stays referenced until something checks.

## 2. The thirteen approved differences were prose only

The ledger says thirteen rows are `approved-difference`. `compatibility.md`
argued each one somewhere across thirty prose sections and 1 600 lines, but
there was **no index** — no way to ask "what does this port deliberately do
differently?" and get an answer you could check for completeness. A reader had
to already know what to look for.

There is now a **Support matrix** section: one row per approved difference, with
*what differs observably*, *why it is approved*, and *the evidence that pins
it*. Writing it forced each one to be stated as a user-visible fact rather than
an implementation note — for example:

- `tlc-coverage` is not "coverage is deferred" but *"coverage counters are not
  reproduced, because `TLC_COVERAGE_INIT/NEXT` are `getEvalCount()`
  (`ActionWrapper.java:147/155`) — an engine-internal cost-model count, not a
  property of the spec"*;
- `tlc-value-order` is not "string order differs" but *"tlc2 orders by intern
  position, and for a 10-line fixture SANY interns 399 strings — syntax-tree
  kind names, internal operator names — before the module's own lexemes; that
  order is an artifact of the Java toolchain's path, not of TLA+"*;
- `tlc-eval-cst` is `approved-difference` and deliberately **not** `replaced`,
  because it still owns the canonical `value` mold that `lib/value` and
  `lib/config` depend on.

Two normalizations that live in the differential **harness** rather than the
engine (the dropped generated-count, the sorted state bindings) are named
alongside, since a reader looking for "what differs" should not have to know
which side of the comparator a difference sits on.

## What keeps it complete

`tools/check-portmap.py` gained two checks:

- **(5) every `approved-difference` ledger row appears in the support matrix.**
  Verified to bite: removing `tlc-coverage` from the matrix fails the gate,
  naming the row. A deliberate divergence can no longer be added to the ledger
  and left out of the document that exists to enumerate them.
- **check (4) was widened.** It already compared quoted tallies against
  `check-parity.py`, but only matched the phrasing `still owed …: N`. The stale
  release matrix said `(65 rows, 35 still owed)` — a shape the check did not
  see, which is why R1.9.0's checker passed over it. It now also matches
  `(N rows, M still owed)` and bare `N still owed`, and it checks the row count
  too. Confirmed against the old text: three failures, correctly named.

That is the shape of the lesson, and it is R1.9.0's lesson one turn later: a
check that only recognizes the phrasing you happened to think of is a check with
a hole in it. The fix is not to trust the next phrasing either — it is that the
matrix now has a completeness check keyed on the ledger, which does not depend
on prose at all.

**The widened check then failed on this unit's own port-map row**, which quotes
the stale `(65 rows, 35 still owed)` while narrating what was wrong with it. The
right answer is the one check (1) already reached for file names: port-map's §7
progress log is *exempt*, because it records each increment's figure on purpose.
A log that could not cite a superseded number would not be a log. Both
exemptions are now stated in the checker's own docstring, so the next person
does not read them as oversights.
