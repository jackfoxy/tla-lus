# P2-R1.8.6 — the `tlc2.TLC` driver surface, flag by flag

Closes `tlc-driver`, the last owed row. **Ledger 124 terminal / 1 owed → 125 / 0.**
Every in-scope row is now terminal.

## What this unit actually was

`tlc-driver`'s residue read *"exhaustive/simulate modes partial; flags map to
request mold"* — a sentence naming no behaviour, which is why it survived eight
units without being schedulable. R1.8.0's audit turned it into an inventory of
`tlc2.TLC`'s **46 flag literals**. This unit **decides** each one.

The port has no CLI. Its driver is the typed Gall request (`check-opts`,
`check-mode`, `limits`), so the row is `replaced` in exactly the sense
`sany-pipeline` already is: *the CLI front-end becomes the Gall API*. The work
was to account for all 46 rather than wave at them.

| Bucket | Count |
|---|---|
| mapped to the request | 5 |
| excluded by an already-terminal row | 19 |
| no output channel or filesystem on this engine | 7 |
| dispositioned elsewhere (`-config`, `-h`, `-help`) | 3 |
| **decided here** | **12** |

The 7 "no output channel" flags (`-dump`, `-dumpTrace`, `-loadTrace`,
`-userFile`, `-tool`, `-postCondition`, `-aril`) were excluded *by construction*
all along — but that had never been written down anywhere, which is part of why
the row read open. Silence is not a disposition.

## The twelve, and what measuring changed

Full table with reasons in `compatibility.md`. The ones where measurement changed
the answer:

- **`-maxSetSize` is not an enumeration-size error.** It sets `TLCGlobals.setBound`
  (default 1,000,000), a defensive **array growth cap** on `StateVec.grow`
  (EC 2172) and `ValueVec.ensureCapacity`. The port bounds the same resources
  through `limits` and `max-noun-bytes` and returns a typed `%limited` naming the
  resource — strictly more informative than *"Too many possible next states for
  the last state in the trace."* Excluded, with an equivalent.

- **`-lncheck` is an equivalence, not a gap.** `TLCGlobals.lnCheck` has exactly
  three consumers: `doLiveCheck()` (`!(final|seqfinal|off)`), `isSeqLiveCheck()`
  (`startsWith("seq")`), and `LiveCheck.java:238` (`off` disables). The port's
  kernel runs `%explore` to completion and *then* the `%liveness` stage — which
  is structurally **`-lncheck final`** — and `off` is expressible by omitting
  `PROPERTY`. The port has one strategy and it is a named TLC one. Documented.

- **`-inv` and `-invlevel` are a different subsystem.** Both build
  `InvariantTemplate`s on `ParameterizedSpecObj` (the inductive-invariant
  machinery), not config invariants through `processConfig`.

- **`-nowarning` is not purely cosmetic.** At `Tool.java:1005` it also selects a
  fast path that *skips* the UNCHANGED-and-changed diagnostic. Still excluded —
  the port emits typed diagnostics with codes and severities, and never takes a
  different evaluation path to avoid producing one — but the asymmetry is worth
  recording.

- **`-simulate stats=basic|full` needs no toggle.** The port reports the
  action-statistics table unconditionally, i.e. it behaves as `stats=full`.

## Measuring `-view` found a real defect

R1.8.0's inventory had guessed `-view` was "a VIEW override on the command line".
It is not: it sets `TLCGlobals.useView`, which makes `TLCStateMut.toString()`
render the VIEW's value instead of the bindings. Chasing that down surfaced
something a level below the flag:

> **`VIEW` and `ALIAS` were parsed, validated, carried in the `run-spec` — and
> silently ignored by every engine path.** Neither `lib/job` nor `lib/check` ever
> read those fields.

Not cosmetic. tlc2 fingerprints the **VIEW's value**
(`TLCStateMutExt.fingerPrint`, 262ff), so dropping a VIEW makes the port report
*more distinct states* than tlc2 and can change whether a run terminates. A spec
with `VIEW V` got a confidently wrong answer.

Fixed to the release's standing doctrine — an unsupported option is refused or
documented, never silently degraded:

1. **`VIEW` is validated exactly as `Spec.getViewSpec` does**: EC 2229 (not
   defined), 2233 (resolves to a constant), 2228 (takes an argument), all with
   the role string `view function`. `+ck-action` already produced those three
   codes and message bodies for INIT/NEXT, so this is a call, not a new message.
2. **Both are typed rejections** at `%config` (kernel) and in `search-ctx`
   (console).

**`ALIAS` is deliberately not validated**, and this is the measurement worth
keeping: `Spec.getAliasSpec` runs only when a trace is *printed*, so tlc2 accepts
an **undefined ALIAS at config time**. The corpus case `val-alias-undef` asserts
`ok` precisely so a later "make VIEW and ALIAS symmetric" cleanup cannot
over-validate it. The asymmetry is real and now pinned.

VIEW-based fingerprinting and ALIAS trace rendering stay unimplemented. They are
now honest refusals instead of wrong answers.

## Tests

- `cfg-val` 35 → 39: `val-view-undef` (2229), `val-view-const` (2233),
  `val-view-arg` (2228), and `val-alias-undef` (**ok** — the pin's asymmetry).
- `tests/lib/job`: `test-view-refused-not-ignored`,
  `test-alias-refused-not-ignored`, and `test-view-definition-alone-is-fine` —
  the last because the refusal must key on the *config option*, not on a `V`
  definition merely existing in the module.

Shards green: `job`, `cfg-val`, `cfg`, `cfg-runspec`, `mc`, `liveness-verdict`.
