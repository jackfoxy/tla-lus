# P2-R2.2 — Clay write-back: the mechanism

The first R2 unit that builds something. A terminal run can now persist its
artifacts to Clay. The agent was read-only end to end before this — no
`%c %info` anywhere in `app` or `lib`.

## The plan was wrong about the ack, and that simplified the unit

R2.2's own description said: *"the async `%c %info` round-trip and its ack"*.
Measured against `lull`:

```hoon
[%info des=desk dit=nori]     ::  internal edit
```

and Clay's gift set is `%writ` (a read response) and `%wris` (a subscription
change). **Neither answers an edit.** `%info` is fire-and-forget: there is no
round trip and no ack.

That is the third R2 plan-claim measurement has corrected, after `tlc-dfid`'s
and `tlc-coverage`'s sizes. It removes work (no `on-arvo` write path) and it
*determines the design*: since a failure cannot be reported back through the
job's result, **everything knowable must be checked at submit**. By the time a
card is emitted, a refusal would be a Clay bug — the same argument
`compatibility.md` §10.7 makes for the absent `%writ` watchdog.

## A boolean could not express this

`allow-write=?` said *may write* and nothing about **where**. An `%inline`
bundle has no desk to infer a destination from, so there was no convention to
fall back on either. The wire field is a target:

```hoon
+$  write-target  [=desk pax=path]
write=(unit write-target)     ::  ~ is read-only, and is the default
```

This is a wire change — pre-release, and R2 already accepts them.

## `+write-ref` is a separate guard, deliberately

The obvious implementation is `+read-ref` with a flag. It would be wrong: the
two differ in **every rule that matters**.

| | read | write |
|---|---|---|
| revision | must be **pinned** (`%ud`), so a mid-run commit cannot split the source set | none — a write lands at the head; writing to a past revision is meaningless |
| roots | must lie **under** a declared search root | must lie **outside** every one of them |

The second is the security-shaped rule: **a run may not write over the sources
it is checking.** Overlap is refused in *either* direction — a target under a
read root *and* a read root under the target — because either lets a write reach
a source the run would then re-read on a resumed slice. Segment canonicalization
is shared, because escape is escape.

`lib/source-path` remains the only constructor of both a `source-ref` and a
`write-target`, so a path cannot be named except through a guard.

## The write belongs to the agent

`+step` is pure and returns `[%stop events job]` with no cards. That is not
incidental — it is what lets the scaffold gate assert that no file under
`desk/lib` or `desk/sur` touches Clay. So the kernel decides *what a run
produced* and the agent decides *where it goes*: `+write-cards` turns a terminal
job with a target into `%info` edits.

Artifacts map to marks by kind — `%text` → `%txt` (a `wain`, the desk's own
mark), `%trace` → `%noun` — with the artifact name as the final path segment, so
`%report` lands at `<pax>/report/txt`. A passing safety run writes two files
(`report`, `sources`); a violating one writes three.

## PlusCal-independent, on purpose

Nothing here knows what a translator is. When PlusCal lands in R3 it adds a
*producer* into an existing, tested path rather than a new subsystem — and the
parts that are easy to get wrong under schedule pressure (escape prevention, the
overlap rule, submit-time validation) are already built and already tested. That
was the whole argument for scheduling the mechanism before the translator.

## Verification

- `tests/lib/job`, four arms on the guard: overlap refused, a target outside the
  roots accepted, an `%inline` bundle accepted (it declares no roots, so nothing
  of its own can be overwritten), a malformed desk refused.
- `tests/app/tla-lus`, two arms on the cards — the only observable, since
  `%info` has no ack: a write target emits exactly two `%c %info` edits for a
  passing run *and* the job still reaches its normal verdict; no target emits
  none, so the read-only default is unchanged.

Shards green: `job`, `clay-load`, `fuzz`, `tests/app`. Ledger **17 → 16 owed**;
the row is renamed `allow-write` → `src-clay-write`, since it now names a
capability rather than a flag.

`check-portmap.py` caught two things before I did: the new `write-target` mold
missing from `api.md`, and the tally in `compatibility.md` still reading 17.

## A note on the test fixtures

Two of the four guard tests failed on first run — both because *my fixtures*
were malformed (`roots=/` is a path, not a list of paths; a cfg outside its own
declared root), and bundle validation correctly caught them before the write
guard ran. The implementation was right and the test was wrong, which is the
better way round.
