# R2.4.5 — diagnostic selectors: two confirmed, one corrected

`-nowarning`, `-suppressMessages`, `-messagesAsErrors`. R2.4.0 sized this
"S / low, documentation". Two of the three are documentation. **The third is
not**, and measuring is what showed it.

## `-suppressMessages` — confirmed a display filter

`-suppressMessages 2255` on a spec whose only diagnostic is the EC 2255
state-level-PROPERTY warning: the warning line disappears, the run completes,
**exit 0**, counts unchanged. Pure display. The wire carries codes, so a caller
filters. Excluded, as recorded.

## `-nowarning` — confirmed no measurable effect

R2.4.0 already corrected the stated reason (the fast-path guard needs
`TLCGlobals.warn` TRUE, so the flag *disables* it — the opposite of what was
written). R2.4.5 adds: `-nowarning` on the same spec drops the warning and
completes, exit 0. No spec was found where it changes anything but display.
Excluded.

## `-messagesAsErrors` — NOT cosmetic. Corrected.

Recorded as *"promotes codes to errors; same reasoning — severity is on the
wire"*, i.e. something a caller could reproduce by re-reading severities.

Measured:

| flags | outcome | exit |
|---|---|---|
| none | `Model checking completed. No error has been found.` + counts | 0 |
| `-suppressMessages 2255` | same, warning line dropped | 0 |
| `-messagesAsErrors 2255` | the message printed as `Error:`, **and nothing else** | **255** |

**The run does not happen.** Promoting a code does not restyle a message; it
aborts before model checking. A caller filtering the port's typed diagnostics
would be holding a *completed* run's result — `%ok`, real counts — where tlc2
produced no run at all. That is not a display difference.

### What it would take

The port's diagnostics already carry `code` and `severity`, so the data is
there. The work is a **promotion set on the request** — it applies to `%analyze`
and `%check` alike, so it belongs on `request`, not `check-opts` — plus
promotion at the point a diagnostic is *emitted*, because tlc2 aborts at that
moment rather than at the end.

That last part is what makes it more than a filter: `lib/job` appends to
`diags.j` at **eight** sites, and promoting only at the terminal verdict would
let a run continue past the point tlc2 stops. A faithful port needs a single
emission chokepoint first.

Sized: **S–M** — one request field, a `+add-diag` chokepoint, and the abort
path. Not the "documentation" this row was sized as.

**Deliberately not implemented here.** The row's budget was documentation; the
correction is the unit's finding. Rushing an eight-site refactor at the end of a
long session is exactly how R2.4.3's first attempt had to be reverted. Recorded
as owed with an accurate size instead.

## Implemented — and re-measuring corrected this note twice

Built after R2.4.6, and the standing rule paid again: **two of the claims above
are wrong**, and both would have shaped the port badly.

### 1. It does not always abort *before* model checking

The section above says "the run does not happen". That is true for EC 2255,
which is emitted while the config is processed. It is **not** true in general.
Promotion is `Assert.fail` inside `MP.printWarning` — at the moment of
EMISSION — so a code emitted during checking aborts *during* checking.

Measured, `EC.TLC_UNCHANGED_VARIABLE_CHANGED` (2143), which `Tool.java:1675`
raises while computing successors:

| | outcome | counts | exit |
|---|---|---|---|
| unpromoted | `Error: Invariant Inv is violated.` + trace | 5 generated / 5 distinct / 0 queued | 12 |
| `-messagesAsErrors 2143` | `TLC threw an unexpected exception` + trace to the offending state | **2 / 2 / 1**, depth 2 | **75** |

So the port's promotion is not a submit-time rejection. It has to abort the
engine where the diagnostic is raised and report the statistics reached so far.

### 2. Exit 255 is the config-stage abort, not the flag

The table above records 255. That is EC 2255's abort. A mid-run promotion exits
**75**, and the unpromoted run exits **12**. The exit code follows *where* the
abort happens, not *that* the flag was given.

### 3. Only warnings are promotable — tlc2's rule, not a port choice

`isTlcMessageAsError` is consulted in `MP.printWarning`'s two overloads and
nowhere else. Errors are already errors; `printMessage` never consults it.
Measured: `-messagesAsErrors 2110` (an error code) leaves a run byte-identical,
and a promoted code the run never emits changes nothing. So `+promoted` gates on
`severity == %warning`, and that is parity rather than a narrowing.

## What shipped

`request` gained `promote=(set diag-code)` — on `request`, not `check-opts`,
exactly as this note predicted, because it spans `%analyze` and `%check`. The
set is namespaced by family, which matches the pin: tlc2 keeps `addTlcMessages
AsErrors` and `addSanyMessagesAsErrors` as separate sets.

`lib/job` gained **`+add-diags`**, the emission chokepoint this note said had to
come first. Every in-run diagnostic site routes through it — the ten `diags.j`
mutations became one. The single exclusion is the agent-side retention warning
(`+reclaim`), which fires on an already-TERMINAL job: there is no run left to
abort and tlc2 has no analogue.

A promoted diagnostic is recorded with severity `%error` and never as a warning,
because `Assert.fail` runs *before* `recorder.record` — the promoted code never
reaches the recorder as a warning at all. Nothing after it is emitted, because
in tlc2 nothing after it runs.

**One CLI behaviour is deliberately not ported.** tlc2 refuses an *unknown* code
at argument parsing (`Error: unknown message code: 9999`, exit 1). That is
argument validation rather than the capability — the same CLI/capability split
R1.8.6 and R2.4.0 draw everywhere else — and the port has no code registry to
validate against, so an unrecognised code is inert here. Documented in
`compatibility.md` rather than left implicit.

### Evidence

Four arms in `tests/lib/job`, built around the existing 4802 lint warning:

- `test-promote-warning-fails-the-run` — `%failed`, and 4802 present as an
  ERROR and absent as a warning
- `test-promote-off-keeps-the-warning` — the matched half: `%ok`, 4802 present
  as a WARNING
- `test-promote-unrelated-code-is-inert` — a code the run never emits
- `test-promote-error-code-is-inert` — an error-severity code, mirroring the
  measured `-messagesAsErrors 2110`

### One Hoon trap worth recording

Routing `do-parse`'s per-module diagnostics through the chokepoint nest-failed:
`op.request.j` is narrowed by an enclosing `?=(%check ...)` guard, so `%=` on
`j` itself cannot take the unnarrowed jobstate `+add-diags` returns. The fix is
to copy the `diags` LEG (`=. diags.j diags.j.r`) rather than the whole record —
sound because `+add-diags` touches no other leg. Same family as the zuse-408
narrowing note in the dev memory, in a new place.

## Running tally

Five of R1.8.6's twelve flag rationales have now been found wrong by
measurement — `-continue`'s premise, `-nowarning`'s polarity, `-view`'s
reachability, `-lncheck`'s method names, and now `-messagesAsErrors` being
verdict-affecting. Four of its *decisions* have held; **this is the first
decision that does not.**

## Touched

`desk/doc/compatibility.md` (three flag rows), `desk/doc/parity-manifest.md`
(`tlc-driver`).
