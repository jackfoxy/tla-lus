# R4.2l — config targets and VARIABLEs follow EXTENDS (2026-10-09)

**Status: DONE.** It still needs the census re-run (R4.0e2) to count how many
of the about 29 refusals it clears.

## The bug (measured)

`lib/job.hoon` checked that each config target exists with
`body-of-def:check tree <name>`, which searches the ROOT module's syntax tree
only:

- INIT (:1370) and NEXT (:1372) in `+do-config`
- INVARIANT (:1450) in `+config-run`

The Next label's node (:1482) and the VARIABLE set/order (`var-names` /
`var-order` of the root tree, :1414) used the same root-only tree.

Everything else already went through the semantic graph (`defmap-of`
includes EXTENDS imports since unit 6C.1, and `vars.mo` includes extended
modules' variables). An MC-style root (`EXTENDS Spec`, with the targets
defined in `Spec`) was therefore refused: `no definition for INIT Init` in
the minimal probe, `... INVARIANT <name>` in the census.

A name that NO module defines never reached this guard. The config validator
refuses it first, with tlc2's own text (`The invariant Nope specified in the
configuration file\nis not defined in the specification.`). So the guard
fired only on names an EXTENDed module defines, which is exactly the false
refusal.

## Fix

- INIT/NEXT/INVARIANT existence: `(~(has by (defmap-of:ne mo)) name)`.
- VARIABLEs: `order = (turn vars.mo head)`, `vars = (silt order)`.
  Measured: for one module this equals the old declaration order
  (`y b m` both ways), so no golden moved.
- The Next label: the new `+def-node` returns the root's own node, else
  parses the defining module (`origin` on the `sem-def`) from the bundle.
  The label now names that module. tlc2 prints
  `<Next line 5, col 9 to line 5, col 18 of module Spec>`.

## Evidence

- New arms in `tests/lib/job.hoon`, expected values from the pinned jar:
  - `test-extends-config-targets`: `[%invariant 'Inv' |]`, 3/3/0/3
  - `test-extends-next-label`: the three `State` lines, with module Spec
  - `test-extends-undefined-invariant`: the validator's tlc2 text
- Shards green on `tla-zod`: job 124 (121 + 3), app 41, clay-load 36,
  blackbox 40, safety-gen 10.

## Found on the way: variable ORDER (new row, R4.2t)

tlc2 prints (and fingerprints) state variables in UniqueString order, not
declaration order. One module declaring `VARIABLES y, b, m` prints
`b, m, y` at the pin; the port prints `y, b, m`. Across EXTENDS (`Spec`
declares `m`, the root declares `y, b`) the pin also prints `b, m, y`, while
the port's semantic order is root first, then imported (`y, b, m`).

- Approved difference `tlc-value-order` covers string VALUE order, not
  variable order. This is a separate, pre-existing divergence in every trace
  whose declaration order differs from tlc2's.
- The corpus never caught it, because no golden declares variables out of
  that order.
- It needs a measurement of what tlc2's order actually is (intern position,
  `InternDump`) before any fix, and the `tlc-uniquestring` /
  `tlc-value-order` rationale may extend to it. That would be an
  approved-difference decision for the user.

Not in the TLC parity of `ASSUME`s yet: `check-assumes` reads `assumes.mo`,
the root's own. Whether tlc2 checks an EXTENDed module's ASSUMEs is
unmeasured; the census re-run will show it.
