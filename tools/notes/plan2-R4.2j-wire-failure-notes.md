# R4.2j: `op-wire-failure`, the typed wire's projection of a failing run (in progress)

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

## (a) Runtime evaluation failures: OPEN

EC 2102/2109/2103/2179 still produce `[%failed reason]` with no diagnostic
and no `%trace` of the behavior tlc2 prints. The `incomplete next state`
reason text also differs. Four arms remain withheld.
