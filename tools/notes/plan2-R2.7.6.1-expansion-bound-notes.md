# R2.7.6.1 — the expansion bound, tested instead of asserted

```text
Sub-unit: R2.7.6.1
Claim being measured: "`+expand-cap` vs EC 1005 is an approved difference"
Measurement result: confirmed as a difference, WRONG about its shape --
  the two fixtures reach the pin's single outcome by two different port paths,
  and the port's own bound was invisible in its output.
```

## What the pin does, and what the port did

tlc2 has no bound on tableau expansion. When a RECURSIVE temporal operator's
expansion reaches no base case it inlines until the JVM stack overflows, and
`TLC.process` reports **EC 1005** — the four-line `This was a Java
StackOverflowError` template. That is the pinned outcome for both
`Github1389Loops` and `Github1389StateGuard`.

The port cannot do that: a Hoon runaway is an uncatchable hang, not a
throwable. `+expand-cap` bounds it at 1.000 nested user-operator expansions —
the same trade `live-graph-cap` already makes for the graph build.

**But the bound was invisible.** A capped expansion fell through `+user-op`'s
`fall` and produced the pin's **EC 2213** text, `TLC cannot handle the temporal
formula <loc>` — which is the message for a formula *tlc2 also refuses*
(`Github525`, `Github742`). Two materially different situations, one message:
"neither engine handles this" and "the port stopped where tlc2 kept going" are
not the same answer, and a caller could not tell them apart.

## What shipped

`+user-op` now has a `capped` arm producing a rejection that NAMES the bound:

```text
Error: expansion bound reached (1000 nested user-operator expansions)
translating the temporal formula line 7, col 37 to line 7, col 42 of module
spec; the recursion reaches no base case. tlc2 has no bound here: it overflows
the JVM stack and reports EC 1005
```

and it **propagates** that one error where every other failure keeps tlc2's
swallow-and-fall-through. The exception is safe precisely because the cap has
no tlc2 counterpart to imitate: swallowing it walks back out to the outermost
`fall`, which then reports EC 2213 at the PROPERTY's location — the difference
hiding itself.

The marker is a port-local sentinel `+cap-ec`, **not** EC 0: `lib/stdops`'
unsupported-operator rejection already uses 0 and can arrive here through
`+eval-const`, and that one must keep the swallow. `aerr`'s `ec` is never
rendered — the console path (`+live-struct-raw`) and the kernel
(`job.hoon`'s `[%failed msg]`) both read `msg` alone — so the sentinel never
reaches a caller.

## The correction R2.7.6.0 needed

R2.7.6.0 recorded these as "ONE difference reached two ways". **Measured, that
is wrong.** Only `Loops` is a cap case. `StateGuard`'s recursion is guarded by
a STATE variable (`Prop == op(x)`), so its expansion fails on its FIRST attempt
and never recurses at all — proved by lowering `+expand-cap` to **3** and
re-running: its output is byte-identical. It is refused with EC 2213, which is
the right message for it, since the formula genuinely cannot be translated.

So: **two port behaviours, one pin outcome.** Neither run produces a verdict on
either side, which is what makes the pair an approved difference rather than a
gap.

## How it is tested — and why a withheld arm was not enough

`gen-mc-tests.py` gained an `APPROVED` map beside `SKIPS`. For a case in it:

- the **golden stays the pin's**, captured and rewritten every generator run,
  so a change at the pinned jar shows up as a diff on `out.txt`;
- the **emitted arm asserts the PORT's** output, with the reason and the pin's
  own lines quoted in a comment directly above it;
- the reason prints on every generator run (`APPROVED-DIFFERENCE <case>: ...`).

That tests the difference in **both directions**: a port regression fails the
arm, and a port that quietly starts agreeing with the pin fails it too, so the
approval has to be re-decided rather than lapsing into silence. A withheld arm
(`SKIPS`) proves neither. Both `SKIPS` entries from R2.7.6.0 are deleted.

## Deliberately not done

Routing the cap to the wire as `[%limited kind=%expansion]`, the way
`live-graph-cap` yields `%limited`. It is arguable — but `%limited` means "the
run stopped early, here is what it found", and a capped tableau expansion has
no partial result at all: no states were explored, and the pin's own outcome is
a hard failure. `[%failed <message naming the bound>]` says exactly that. If a
caller later needs to branch on the cause programmatically rather than read the
message, the wire change is small and can be argued then.

## Evidence

`-test /=tla-lus=/tests/lib/mc ~` — **`ok=%.y`**, 61 arms (62 cases, 1
withheld: `live-after-inv`, R2.7.11's target). Both approved-difference arms
pass. `gh1389-ok`/`-viol`/`-violb` still byte-exact against the pin.

Ledger: `tlc-live-normalize` keeps this clause as a TESTED approved difference
and stays `partial` on **R2.7.6.2** alone (`Github1389Counting` /
`ViolatedC` want `POSTCONDITION` + `TLCExt!CounterExample`, which is R2.7.7).
Support matrix row in `compatibility.md` rewritten to the measured shape.
