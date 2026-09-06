# P2-R1.8.3 — the job kernel's report is the console path's

Closes `cfg-runspec`. Ledger 123 terminal / 2 owed → **124 / 1**. Only
`tlc-driver` remains.

## Three symptoms, one cause

R1.8.0's audit found `cfg-runspec`'s named residue had a **twin at the same call
site**; R1.8.2, working on a different row, found a **third symptom**. Scheduling
them as one unit was the whole point — each would otherwise have paid for the
same continuation-shape change.

| Symptom | Owner as written | Reality |
|---|---|---|
| the sliced liveness report omits the EC 2257/2259 stuttering hint | `cfg-runspec` residue | `job.hoon` passed `~` for the gate: no SPEC name, span or fairness to build one from |
| the trace's root action name is always `Next` | R1.1.R1 "documented gap" | the console path passes `sctx`'s `aname` — `Action` under a SPECIFICATION |
| a SPECIFICATION-form config is typed-rejected | *nothing* — no ledger row cited it | `job.hoon:1100`, although R1.8.1 landed the decomposition and `check:check` ran it |

The cause is one sentence: **the `%live` continuation carried no
SPECIFICATION-form state.** Everything the kernel could not say about a
SPECIFICATION, it could not say because it had never been given it.

## The change

- `%live` continuation gains `sname`, `sloc`, `fair`, `aname`.
- `%bfs` continuation gains `aname` — a SPECIFICATION now reaches the *safety*
  path too, where the trace's per-action attribution needs the same fallback
  name. Missing this would have left symptom 2 half-fixed in exactly the place
  no liveness test looks.
- `+resolve-targets` generalized to take the three config **names** rather than a
  whole `cfg-ast`. The kernel calls it with a `run-mode`, the console path with
  its ast, and both decompose a SPECIFICATION through the same code. This is the
  structural point: the two paths cannot drift again because there is only one
  resolver.
- `+do-config` split. Its mode-specific half keeps INIT/NEXT's name-level
  diagnostics (`no INIT in config`, `no definition for NEXT X`) so those messages
  do not move; the new `+config-run` — resolved Init/Next bodies down to the
  engine continuation — is reached by both modes.
- The kernel's `oss-of` call passes the real fairness conjuncts where it used to
  pass `~`, so a SPECIFICATION's WF_/SF_ conjuncts take part in normalization as
  they do on the console path.
- The stuttering gate is tested against **the OrderOfSolution being reported**
  (`~[o]`), not the whole list — tlc2 tests `this.oos`, so a spec whose first
  violated property has empty PEMs prints no hint even when a later one would.

## How it is tested

Not with another frozen golden per path — that is how the two drifted in the
first place. `tests/lib/job` now asserts

```
kernel %report artifact  ==  (check:check spec cfg)
```

over four shapes:

| test | what it pins |
|---|---|
| `…-console-2257` | a STUTTERING counterexample under INIT/NEXT — the hint the kernel used to drop |
| `…-console-2259` | the same property under a SPECIFICATION carrying **no** fairness: 2259 names the spec and its source location. Unreachable from the kernel before this unit |
| `…-console-fair` | a SPECIFICATION **with** fairness: no hint at all, trace labels from the decomposed action |
| `…-console-safety-spec` | a plain safety run under a SPECIFICATION |

Two reports that drift apart now fail a test instead of both looking plausible.

Shards re-run green: `job` (209 arms), `liveness-message`, `liveness-verdict`,
`mc`, `sim`, `sim-live`, `cfg-runspec`, `spec-decomp`, `clay-load`, and
`tests/app` — the last because both continuation molds changed and `tests/app`
is what resumes a jammed cursor across a Gall reload.

## Note for whoever writes tests in this shard

TLA+ inside a Hoon `'''` block is **literal**: write `/\`, `\/`, `x'`. The first
draft escaped them (`/\\`, `\\/`, `x\'`) as one would inside a `'…'` cord, and
all three SPECIFICATION cases came back `Error: parse error` — which the equality
assertion caught immediately, because the kernel returned `''` where the console
returned a parse-error line.
