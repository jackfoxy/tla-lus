# R3.1 — the TE-spec decision, taken

```text
Sub-unit: R3.1 (a DECISION, not an implementation)
Row: tlc-repl — stays `excluded`, rationale replaced
Planned: R1.8.6 excluded TE-spec generation with an unblock condition
  ("reconsider once R2.2's write path exists and PlusCal lands"). Both halves
  are now settled, so the condition is owed an answer.
Found: the answer is still "excluded", and the condition named the WRONG
  OBSTACLE. The decisive reason is one it never mentioned, and this repository
  had already acted on that reason twice without writing it down.
```

**Docs only. No code, no generator change, no ship run.**

## 1. The condition is discharged, both halves

R1.8.6 wrote:

> reconsider once R2.2's write path exists and PlusCal lands, since it is a
> *producer* into that path

* **R2.2 built the write path.** The "no output channel or filesystem on this
  engine" bucket that TE-spec generation sat in is no longer true of the
  engine — Clay write-back landed, with path-escape prevention, permission and
  quota.
* **PlusCal is out of the project** (2026-09-04), not deferred, so the second
  half can never be satisfied and a sentence waiting on it would wait forever.

So the condition had to be answered rather than restated. It is retired here.

## 2. The real obstacle: the artifact's identity is the wall clock

`TraceExplorationSpec.teModuleId`:

```java
public static String teModuleId(Date timestamp) {
    final long secondsSinceEpoch = timestamp.getTime() / 1_000L;
    return Long.toString(secondsSinceEpoch);
}
```

and `deriveTESpecModuleName` puts it in the **module name**. Measured on
`DieHard` with the pinned jar:

```
Trace exploration spec path: ./DieHard_TTrace_1788555738.tla
DieHard_TTrace_1788555738.tla
DieHard_TTrace_1788555738.bin
```

The timestamp is therefore in the file name, in the `---- MODULE ----` header
inside the file, in the `.bin` path that gets registered as a `_TLCTrace`
postcondition, and in the console line. **Two runs of the same spec on the same
jar never produce the same TE spec**, so there is nothing a differential can
pin — and this project's evidence is differential end to end.

That is exactly the rule already applied three times:

* `TLCGet("duration")` — refused BY NAME, "the wall clock, which no
  reproducible run may observe" (R2.6.1).
* `_PERIODIC` — measured to stop the same run at 1 677 194 states once and
  1 740 872 the next; "the keyword's observable effect is a function of machine
  speed" (R2.7.7.5).
* `TLC!JavaTime` — excluded on wall-clock nondeterminism, which is why R2.7.4
  could re-point a test at it knowing no capability unit could ever turn it
  green.

"No filesystem" was never the load-bearing reason. It was the one that happened
to be true first.

## 3. The corpus had already decided this — twice, silently

Both of these predate this unit and neither was written down as a decision:

* `gen-mc-tests.py` and `gen-dfid-tests.py` both list `Trace exploration` in
  their `DROP` regex, so the console line has never appeared in any golden.
* `gen-mc-tests.py` deletes `spec_TTrace_*` after every run, with the comment
  *"TLC leaves trace-exploration + fingerprint artifacts (.tla/.bin/.fp, a
  states/ dir) that have Clay marks which abort |commit; remove them"*.

Only `gen-tier2-tests.py` passes `-noGenerateSpecTE`; the rest let the jar write
the artifact and then filter or delete it. So the whole tier-1 corpus is pinned
in a shape that assumes the TE spec is invisible, and porting it would mean
re-pinning those corpora **into** nondeterminism — the cost is not the 2,760
lines, it is the goldens.

## 4. Size, for the record

`TraceExplorationSpec` 395 + `SpecTraceExpressionWriter` 1,210 +
`AbstractSpecWriter` 577 + `MCError` 156 + `MCState` 422 = **2,760 lines**, for
an artifact that cannot be compared to the pin. Recorded so the next reader does
not re-derive the size and mistake it for the reason.

## 5. Decision

**`tlc-repl` stays `excluded`, and its rationale now states the reason that
actually holds.** The REPL half is unchanged and unchanged in reason — it is
interactive, and `lib/eval` uses it as the constant-evaluation ORACLE
(`gen-eval-tests`, 37 cases). The unblock condition is **retired**, not
restated: leaving a condition that has already come true is how a closed
question gets re-opened by a later phase reading an old sentence, which is the
failure mode R2.8.2a and R2.8.2b both hit from the other side.

Ledger unchanged: **134 rows, 133 terminal, 1 owed** (`check-mode-generate`).
