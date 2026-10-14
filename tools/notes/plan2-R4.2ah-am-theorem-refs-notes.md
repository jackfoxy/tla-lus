# R4.2ah / R4.2am: theorems and selectors as values (2026-10-13)

**Status: code done; census below.**

## R4.2ah: a reference to a named theorem or assumption

`MCReachabilityTest`'s `ASSUME \A i \in DOMAIN Test : Test[i]` evaluates
`Test`, whose elements are `\A Succ \in SuccSet : P(Succ)!Reachable0`, a
LEMMA of the parametrized instance `P(Succ) == INSTANCE
ReachabilityProofs`. tlc2 evaluates a theorem reference by evaluating its
body. The port refused it (`a theorem/assumption is not an evaluable
value`).

- `+thm-defs:semantic`: a module's NAMED theorems/assumptions as definitions
  keyed `$thm:<name>` (a name no source or config can spell), with the
  theorem's params (an instanced theorem carries the instance parameters,
  its body the `$APSubstIn` wrapper).
- `+ext-defs` adds them for every EXTENDed user module, `+defmap-of` for the
  root.
- `%thm-assump` in `+eval-apply-rs` evaluates through `+eval-user` under the
  `$thm:` name; an unnamed or missing one keeps the refusal.
- `+with-cdefs` and `+startup-draws` skip `$thm:` entries: tlc2's
  `processConstantDefns` walks `getOpDefs()`, which has no theorems, and a
  LEMMA body may be expensive or unevaluable.
- mc `thm-ref` (pin golden): a THEOREM and a parametrized-instance LEMMA in
  Init and an ASSUME.

## R4.2am: a selector on an EXTENDed definition or theorem

`MCVoting`'s `ASSUME QuorumNonEmpty!:` names a THEOREM of the EXTENDed
`Voting`. `+resolve-sels` looked the selector's base up in the module's OWN
definitions and theorems (`+bodymap`), so it resolved to `nullODN` and the
ASSUME failed with `unresolved operator (nullODN)`. SANY resolves it against
the whole context.

- `+ext-bodies`: the bodies the module inherits through EXTENDS
  (transitively, user modules only), merged under the module's own.
- Computed only when a `$Sel` placeholder exists (`+has-sel`), so a module
  with no selectors pays nothing.
- sem case `sel-ext-def` (SemDump golden): `Pos(3)!1` and `QNonEmpty!:` on
  definitions of an EXTENDed module.

## Found, not fixed (dump-only): R4.2an

Two SemDump projections differ for an EXTENDed module (both pre-existing;
measured with SemDump against `dump-sem` on the ship):
1. SemDump lists the INHERITED theorems in the extender's dump
   (`theorem name=QNonEmpty`); the port lists only the module's own.
2. An ASSUME over an inherited CONSTANT: SemDump's module constraints have no
   entry for it (`ASSUME \A q \in Q : q # {}`) or `Q<=3` (through a
   selector); the port has `Q<=2` for every form.
Neither moves a verdict. `sel-ext-def` keeps its ASSUME out for that reason.
