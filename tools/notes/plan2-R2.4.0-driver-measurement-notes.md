# R2.4.0 — driver surface on the wire: measurement

R1.8.6 inventoried `tlc2.TLC`'s 46 flags and decided 12 as **excluded because
the port has no CLI**. That reasoning is sound for the *CLI*; it does not decide
whether the **capability** belongs on the Gall request. This unit decides that,
per flag, and where a request field would live.

Everything below was measured against the pin — either by running `tlc2.TLC`
with and without the flag, or by reading the line the flag actually reaches.
**Three of R1.8.6's stated reasons turn out to be wrong**, which is the point of
measuring rather than re-reading the inventory.

## Verdicts

| Flag | R1.8.6 said | Measured verdict | Where it would live |
|---|---|---|---|
| `-maxSetSize` | excluded (array cap) | **capability, `limits`** — but see below, it is not merely a bound | `limits.max-set-size` |
| `-continue` | excluded ("no single verdict") | **capability** — the premise is wrong, see below | `check-opts.continue` + a violation *list* |
| `-difftrace` | excluded (rendering) | **CLI-only, low value** — and its measured effect was *nil*; see below | (render-opts, if ever) |
| `-terse` | excluded (no lazy-set class) | **CLI-only**, confirmed — nothing to leave unexpanded until R2.7.2 | — |
| `-invlevel` | excluded (different subsystem) | **CLI-only**, confirmed — `ParameterizedSpecObj`/`InvariantTemplate`, not `processConfig` | — |
| `-inv` | excluded (same subsystem) | **CLI-only**, confirmed | — |
| `-lncheck` | documented equivalence | **documentation only**, confirmed — the port *is* `-lncheck final` | — |
| `-generate` | excluded (different engine) | **capability, but a real engine** — sized as its own unit | `check-opts.mode` variant |
| `-view` | render flag (R1.8.6 corrected R1.8.0) | **capability, and now CHEAP** — see below | render-opts |
| `-nowarning` | excluded, "not purely cosmetic" | **CLI-only** — but the stated reason is **backwards**; see below | — |
| `-suppressMessages` | excluded (codes on the wire) | **CLI-only**, confirmed — a filter over typed diagnostics is the caller's | — |
| `-messagesAsErrors` | excluded (severity on the wire) | **CLI-only**, confirmed | — |

## The three corrections

### 1. `-continue`'s premise is wrong — measured

R1.8.6: *"One job yields one typed `result` on this wire; a run that continued
would have no single verdict to return."*

Measured (`INVARIANT x < 2` over a 4-cycle, with and without `-continue`):
without it, one EC 2110 and the run stops. **With it, TLC prints EC 2110 per
violation and then finishes with `Model checking completed. No error has been
found.` plus the full counts** — a completed run, 5 generated / 4 distinct /
depth 4.

So there *is* a single verdict: the run completes. `-continue` does not multiply
the result; it multiplies the **counterexamples**. On this wire that is
`result = %ok` (or `%limited`) plus a *list* of violations, which the artifact
store can already carry — R2.4.2's "needs a decision" is answered by the pin.

Note the counts differ too (5/4/depth 4 vs 3/3/depth 3): continuing explores the
whole graph, so the statistics are the *complete* ones. A caller re-submitting
with the first violation excluded — R1.8.6's suggested workaround — would not
get these numbers.

### 2. `-nowarning`'s stated reason is backwards

R1.8.6: *"at `Tool.java:1005` it also selects a fast path that skips the
UNCHANGED-and-changed diagnostic."*

The guard is `TLCGlobals.warn && s1.allAssigned()` (`Tool.java:1004`), and
`-nowarning` sets `warn = false` (`TLC.java:516-519`). So `-nowarning`
**disables** the fast path; it is the *default* (warnings on) that takes it. The
Java's own comment above that line describes the opposite condition to its
guard, which is probably how the inventory got it backwards.

I could not construct a spec where the flag changes TLC's output: the
`UNCHANGED and changed` example from that comment deadlocks identically with and
without it, in both conjunct orders. **The decision is unchanged** — CLI-only,
the wire carries codes and severities — but the recorded *reason* was wrong and
is corrected in `compatibility.md`.

### 3. `-view` is now cheap, because R2.3.1 happened

`-view` sets `TLCGlobals.useView`, and `TLCStateMut.toString()` (`:329`) renders
the VIEW's value instead of the bindings. When R1.8.6 measured this, VIEW was
not evaluated by any engine path, so the flag was unreachable.

**R2.3.1 made VIEW live.** `sctx.view` / `bfs-opts.view` already carry the body
and `+orbit-fp` already evaluates it. So `-view` is now "render the state as the
view's value" over machinery that exists — the smallest of the render options,
not the largest.

Also: the R2.4.0 row's own note guesses that "`-view`/`-inv` are CLI-level
*overrides* of cfg keys and may stay out". That is right for `-inv` and **wrong
for `-view`**, which overrides nothing — R1.8.6 had already corrected this and
the row did not pick it up.

## `-maxSetSize` is not merely a bound

R1.8.6 reads it as a defensive array cap the port covers with `limits`. It is
that, but it **fails the run**: a spec that exceeds the bound errors in TLC
where the port runs on. So the port is not a superset here — it is a different
outcome on the same spec, a parity question rather than an ergonomics one.

**Correction, from R2.4.1's measurement:** this section originally said "pin the
EC 2172 text". That is the wrong text. `setBound` guards **two** sites with
**two different diagnostics**:

- `StateVec.grow` → `Assert.fail(EC.TLC_TOO_MNY_POSSIBLE_STATES)` = *"Too many
  possible next states for the last state in the trace."*
- `ValueVec.ensureCapacity` → a `WrongInvocationException` = *"Attempted to
  construct a set with too many elements (>N)."*

Measured at the pin, the reachable one is the **second**. `-maxSetSize 5` on a
spec with 21 successors (`x' \in 0..20`) produced no error at all — 442 states,
identical to the default — so the `StateVec` path is not reached by the
exhaustive checker on that shape. The same flag on a spec evaluating
`{i \in 0..30 : TRUE}` aborted with the `ValueVec` message, `While working on
the initial state`, and counts. R2.4.1 pins that.

## One thing left open

`-difftrace` is honored in `StatePrinter` via `state.toString(previousState)`,
which is a genuine per-variable diff (`TLCStateMut.java:365-378` skips a
variable whose value equals the previous state's), and `TLCTrace.java:460`
passes a non-null `lastState`. **Yet a measured run showed no difference at
all** — an invariant violation over two variables printed both bindings in
every state, with and without the flag.

So either an ordinary exhaustive counterexample takes a printer path that does
not pass `previousState`, or something else suppresses it. I did not chase it
down; the *decision* (CLI-only, low value) does not depend on it. **R2.4.3
should resolve which printer path is used before sizing the work**, rather than
assuming the flag does what its name says.

## Net effect on R2.4

| sub | plan | measured |
|---|---|---|
| `.1` `-maxSetSize` | S / low | confirmed **S**, but pin the **ValueVec** message, not EC 2172 — measured, the EC 2172 path is unreachable on the shapes tried |
| `.2` `-continue` | needs a decision | **decided**: run completes, violations become a list. M / med |
| `.3` `-difftrace`, `-terse` | S / low | **smaller** — `-terse` is vacuous today; `-difftrace`'s effect is unconfirmed |
| `.4` `-invlevel`, `-lncheck` | may be documentation | **confirmed documentation-only** for both. XS |
| `.5` diagnostic selectors | S / low | confirmed CLI-only; `-nowarning`'s reason corrected. Documentation |
| `.6` `-generate` | M | confirmed M — a different successor-pick engine |
| — `-view` | "may stay out" | **wrong** — cheapest render option now that R2.3.1 landed |

Sequencing: `.2` is the only one with wire-shape consequences, so it should go
first if R2.4 is going to change `result`. `-view` can ride with `.3`.
