# R4.2j: `op-wire-failure`, the typed wire's projection of a failing run (DONE 2026-10-14)

```text
Row: op-wire-failure (absent; created by R4.0f)
Evidence: tests/lib/blackbox arms withheld in tools/gen-blackbox.py KNOWN;
  un-withholding one is the proof its fix holds.
Done early: (b) and (c), each small and already measured. (a) is open.
```

## (c) `%analyze` module-resolution text: DONE

When an inline bundle fails to resolve, `do-semantic` used to emit
`[%lus 401] 'module resolution failed'`. It now re-runs `+resolve` to get
the typed `mres-err` and words a missing module or a file/module name
mismatch with the `%clay` loader's own SANY texts (`+missing-msg`,
`+mismatch-msg`). A cycle or an unparsable module keeps the generic text;
the parse stage has already reported the latter. The black-box arms
`missing-dependency` and `module-name-mismatch` are un-withheld.

## (b) False ASSUME: DONE, and it was wrong in two layers

**The wire.** A false ASSUME was `[%failed msg]`. It is now
`[%violated [%assumption <location>] *run-stats]`, with the `[%tlc 2104]`
diagnostic kept. The variant had existed in sur since unit 2 and had never
been produced. tlc2 exits 10 here, which CI calls `assumption failure`. A
non-boolean ASSUME (EC 2105) stays `%failed`, as tlc2's run errors do.

**The text, on BOTH paths.** `+check-assumes` returned `'An assumption is
false.'` and `'Evaluating an assumption failed: ...'`. tlc2 prints the MP
templates with the location as `%1%`, measured:
- `Assumption line 4, col 8 to line 4, col 12 of module A is false.`
- `Evaluating assumption line 4, col 8 to line 4, col 12 of module A failed.`
  followed by the cause.

`lib/diagnostics` had the templates. `+check-assumes` never used them, and
the only test was Hoon-side (`safety-gen`), so nothing compared against the
pin (L6). The messages are fixed, and `safety-gen` now expects the pin's
text. One approximation remains, stated in the code: `sem-thm` has no
origin, so an ASSUME imported through EXTENDS is located in the root module.

## (a) Runtime evaluation failures: DONE (2026-10-14)

Measured with `tla2tools.jar -tool` on the four fixtures:

| fixture | pin | port now |
|---|---|---|
| IncompleteInit (`y` never assigned) | EC 2102 `current state is not a legal state` | diagnostic `[%tlc 2102]` |
| IncompleteNext (`Next == x' = x + 1`) | EC 2109 `Successor state is not completely specified by the next-state action. The following variable is not defined: y.` + behavior (Initial predicate, Next) | the same text and code; `%trace` artifact ending in the incomplete successor |
| InvariantEvaluation (`1 \div x` at x = 0) | EC 1000 wrapping 2179, then EC 2103 | diagnostic `[%tlc 2103]`, message the cause (`The second argument of \div is 0.`) |
| Evaluation (`\div` by 0 in Next) | EC 2179 + behavior (Initial predicate) | diagnostic `[%tlc 2179]`; `%trace` up to the expanded state |

`outcome`'s `%error` carries `ec` and `trace`; `+bfs-step` classifies a
next-state failure (`+next-states-raw-rs` leaves completeness to it, so it can
name the variables: sorted, as `getUnassigned` is, and the action when
`getActions` has several); `+finish-bfs` and the init-failure path emit the
diagnostic. All four black-box arms are green (runtime 19); `KNOWN` is empty
and the ledger row is `parity`.

The console path's `%error` rendering is unchanged (one `Error:` line, no
trace).
