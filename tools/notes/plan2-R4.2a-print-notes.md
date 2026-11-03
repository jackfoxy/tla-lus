# R4.2a: `Print` / `PrintT` (2026-10-13)

**Status: done; reverses R1.4.6 (user-approved 2026-10-13).**

## The pin (measured)

`TLC.Print(v1, v2)` writes `ppr(v1) + "  " + ppr(v2)` and returns v2;
`PrintT(v)` writes `ppr(v)` and returns TRUE (TLC.java:63-101). The write
happens at the moment of evaluation. On one spec with a print at every site:

    "const K"            constant definition (processConstantDefns)
    "assume"  TRUE       ASSUME
    <<"ex", 1>>          ASSUME \E i \in 1..3 : PrintT(..) /\ i = 2
    <<"ex", 2>>            (stops at the first witness)
    <<"init", 0>>        Init
    <<"inv", 0>>         invariant of each new state
    <<"next", 0, 1>>     Next
    <<"inv", 1>> ...

A definition that fails at startup is re-evaluated where referenced, and so
prints again.

## Port

- `rst` gains `out=(list @t)` (newest first). `Print`/`PrintT` left the
  registry for the node-op table (`%print`, `%print-t`; registry 39 -> 37):
  they WRITE, as `TLCSet` does.
- Startup: `+startup-draws` caches a definition whose evaluation drew OR
  printed (once, in tlc2's order); `+may-draw` also fires on a
  `Print`/`PrintT` name; `+assume-rs` threads the whole carrier through the
  ASSUMEs.
- Binders: `\A`, `\E`, `CHOOSE` and the set filter whose body draws or prints
  (`+sem-draws`) run on the carrier (`+eval-quant-rs`), in ContextEnumerator
  order, stopping where tlc2 stops.
- Console (`+check-in`): `swarn`, then the startup/ASSUME/Init lines
  (`irs.c`), then `+safety-run`'s search lines before the verdict. A failed
  ASSUME prints what came before it (`aout`).
- Job: `+drain-output` moves the lines into the `%output` text artifact at
  every BFS slice (and after the ASSUMEs), emptying the carrier so the
  continuation never grows; capped at 1,000,000 bytes with a marker line.

## Tests

mc `print-order`, `print-exists` (pin goldens); core-eval `ev-tlc` `Pr`,
`PrT`, `PrNest` un-skipped; tlcmod `test-print`/`test-print-t` now values;
job `test-print-output-artifact` (budget 1 = budget 256). Census:
PrintValues and Stones agree (they failed on `TLC!Print`); MCEcho moves on
to a recursive function over `Nat` in a LET (`trcl[n \in Nat]`, census
residue).

## Residues (output only)

- `ppr` wraps a long value over several lines; the port prints one line.
- R4.2ao: one action yielding several successors prints all their `Next`
  lines before their invariant lines (tlc2's worker checks each successor
  as it is generated). Measured on `x' = x + d` over `d \in {1, 2}`.
- Prints in the liveness, DFID and simulation console paths are carried
  but only the safety path renders them; the job's liveness graph build
  drains them.
