# R2.4.3 — render options: `-view`, `-difftrace`, `-terse`

New ledger row `check-opt-render` → **parity**. 118 terminal, owed 12.

## `-difftrace`: R2.4.0's open item, closed by byte-diffing

R2.4.0 flagged this and refused to guess. The code reads as if the flag applies
everywhere:

- `StatePrinter` diffs via `TLCStateMut.toString(lastState)`, which genuinely
  skips a variable whose value equals the previous state's
  (`TLCStateMut.java:365-378`);
- `TLCTrace.java:460` passes a **non-null** `lastState` for every state after
  the first.

Measured instead of read — same spec, same invariant, both modes, output
byte-diffed:

| mode | with vs without `-difftrace` |
|---|---|
| exhaustive | **identical** |
| `-simulate` | states 2-3 omit the unchanged `y` |

So it is honoured on the **simulation** path only. The port therefore carries it
on the `%sim` kont and **refuses it outside `%simulate`** — accepting it on an
exhaustive request would be accepting an option that does nothing, which R2.1
forbids.

I did not chase *why* the exhaustive path doesn't diff despite passing
`lastState`. The parity target is what tlc2 does, and that is now pinned.

## `-view` is cheap only because R2.3.1 happened

`TLCGlobals.useView` makes `TLCStateMut.toString()` render the VIEW's value
instead of the bindings. Measured at the pin: a bare `0` / `1` / `2` — no `/\`,
no variable names, no blank separators.

When R1.8.6 measured this flag, **no engine path evaluated a VIEW at all**, so
it was unreachable. R2.3.1 made VIEW live, and `sctx.view` already carries the
body — this unit only had to render through it.

The flag with no VIEW in the config is **refused**: there is nothing to render,
and silently printing bindings would be the flag doing nothing.

## `-terse` gets no field

`TLCGlobals.expand = false` suppresses expansion of a lazy set value's
`toString`. `tlc-enum` records — as a tested approved-difference — that the port
has no lazy-set *representation* class, so there is nothing to leave
unexpanded until R2.7.2.

Adding a request field that cannot mean anything is the same error R2.1 caught
with `analyze-flags.syntax`. No field.

## Process note: the first attempt was reverted

Threading a render flag reaches ~11 call sites across three renderers. My first
pass used a regex, corrupted two multi-line sites, and then hit a design snag —
`-view` could not reach the kernel without a `check-opts` field that would sit
unread, which is exactly the doctrine violation above.

**I backed the whole thing out** to a verified-clean R2.4.2 tree (the following
`|commit` reported no changed files, confirming byte-identity) and redid it as
explicit per-site edits. The second pass had two ordinary build errors:
`implied-init-run` has `env`, not `vw`/`e`, in scope; and `find` returns
`(unit @ud)`, which cannot be compared with `gth`.

Worth keeping: on a wide mechanical refactor of Hoon call sites, edit by line
number with an assertion per site. A regex over `|=` sample lists and
multi-line `:*` forms will silently mangle the ones that wrap.

## Evidence

`tests/lib/job`: a matched pair on one bundle — `view=|` renders `/\ x = 0`,
`view=&` does not and renders a bare `0` — plus two refusals (`-view` without a
VIEW, `-difftrace` outside simulation).

## Touched

`desk/sur/tla-lus.hoon` (`check-opts.view`, `check-opts.difftrace`),
`desk/lib/check.hoon` (`+render-state` gains `vw`/`e`/`dif`, `sctx.vrend`,
`+render-trace` and `+render-outcome` gain `vw`/`dif`, 5 render-state and 9
renderer call sites), `desk/lib/job.hoon` (`%bfs` kont `vr`, `%sim` kont `df`,
`+finish-bfs`, `+validate` refusals), `desk/tests/lib/job.hoon`,
`desk/tests/lib/clay-load.hoon`, `desk/tests/app/tla-lus.hoon`,
`desk/gen/tla-lus/submit.hoon` (check-opts literals),
`desk/doc/parity-manifest.md`.
