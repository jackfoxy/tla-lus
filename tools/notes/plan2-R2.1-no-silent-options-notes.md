# P2-R2.1 — no silent options

Charter: make `allow-write` a typed rejection, and **sweep the whole request
mold for any other option accepted-and-ignored**. The sweep was the unit.

## The sweep

Every field of `request`, checked for whether any Hoon file reads it:

| field | reads | verdict |
|---|---|---|
| `allow-write` | **0** | silent — fixed here |
| `analyze-flags.syntax` | **0** | silent — fixed here |
| `analyze-flags.{semantic,level,lint}` | gate their stage *and* its diagnostics | fine |
| `check-opts.{translate,cfg}` | typed rejections already | fine |
| `check-mode.{deadlock,seed,num,depth}` | read | fine |
| `limits.*` (all six) | each enforced where its resource grows | fine |
| `source-bundle` `%clay` `{cas,roots,cfg}` | read | fine |
| `pcal-opts.{fairness,termination,gen-cfg}` | unread — but `%translate` is rejected at submit, so unreachable | fine: the caller gets a rejection, not silence |

Two silent options, not the one the plan predicted.

## `allow-write`

R1.0's row said "the flag is ignored". Measured, it is **read by no Hoon file
at all** — not ignored by decision, never consulted. Now:

```
unsupported: Clay write-back (allow-write); the agent is read-only
```

at submit. Correct regardless of what R2.2 decides, and R2.2 replaces it with
the real mechanism. The ledger row stays `partial`: the capability is still owed,
only the silence is gone.

## `analyze-flags.syntax` — and a wrong fix caught mid-unit

The three siblings gate whether their stage runs and reports. `syntax` was read
by nothing, so the obvious fix was to make it symmetric: gate the syntax stage's
diagnostics. **I implemented that, and it was wrong.**

`parse-typed` (`syntax.hoon:3718`) returns `[tree diags fatal]`, and on success
its diagnostic list is **always `~`** — every parse error is fatal, by design
("SANY recovery beyond PErrors accumulation is not ported"). So at the `do-parse`
site the only diagnostics that can exist are:

- `~` on a clean parse, or
- `[%lus 400] parser crashed in <module>`.

A `syntax=|` gate there would suppress *nothing*, or suppress **a parser-crash
report** — which is precisely the thing that must never be suppressible. The
symmetry with its siblings is a coincidence of naming, not of semantics.

So `syntax` has **no possible meaning** in this port: parsing is mandatory
(every later stage consumes the tree), a parse error is fatal, and a successful
parse says nothing. It is refused rather than given an invented meaning:

```
unsupported: syntactic analysis cannot be skipped; every later stage consumes the tree
```

This is the same shape as VIEW and ALIAS in R1.8.6 — keep the field, refuse the
value that would be a lie. Inventing a meaning to make a flag "do something"
would have been a worse outcome than the silence it replaced, because it would
have looked correct.

Worth stating plainly: the standing rule caught **my own fix, inside the unit
that exists to enforce it**, and it cost one measurement to catch.

## Verification

`tests/lib/job` gains four arms — each refusal, and each corresponding
accepted case, so the rejections key on the flag being *set* rather than on the
op:

- `test-validate-allow-write-rejected` / `-off-accepted`
- `test-validate-syntax-off-rejected` / `-on-accepted`

Shards green: `job`, `clay-load`, `fuzz`, `tests/app`. No existing test passed
`syntax=|`, so nothing regressed.

`compatibility.md`'s typed-rejection table gains both, and the **both-directions
check now passes** — the set of `'unsupported: …'` literals in `desk/lib` and
`desk/app` equals the set the table lists, which is release-gate R4. `api.md`
updated in the same pass, since it documented `allow-write` as a live option.
