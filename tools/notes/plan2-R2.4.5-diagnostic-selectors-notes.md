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

## Running tally

Five of R1.8.6's twelve flag rationales have now been found wrong by
measurement — `-continue`'s premise, `-nowarning`'s polarity, `-view`'s
reachability, `-lncheck`'s method names, and now `-messagesAsErrors` being
verdict-affecting. Four of its *decisions* have held; **this is the first
decision that does not.**

## Touched

`desk/doc/compatibility.md` (three flag rows), `desk/doc/parity-manifest.md`
(`tlc-driver`).
