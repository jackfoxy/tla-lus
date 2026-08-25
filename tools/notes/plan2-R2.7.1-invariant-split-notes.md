# R2.7.1 — EC 2107 / 2110 on the wire

The row: *"The wire collapses 'violated by the initial state' and 'violated by a
behavior' into one `[%invariant name]`. **This is the one unit that moves the
public contract** — it bumps `api-version` to 2."*

The first half is right and is now fixed. **The second half is wrong, and the
desk's own doctrine is what says so.**

## The split

`violation` gains `initial=?` on `%invariant` and `%property`:

```hoon
+$  violation
  $%  [%invariant name=@t initial=?]
      [%deadlock ~]
      [%property name=@t initial=?]
      [%liveness name=@t]
      [%assumption name=@t]
  ==
```

| | pin | flag |
|---|---|---|
| invariant, initial state | EC 2107 `Invariant %1% is violated by the initial state:` | `&` |
| invariant, behavior | EC 2110 `Invariant %1% is violated.` | `\|` |
| property, initial state | EC 2108 `Property %1% is violated by the initial state:` | `&` |

**It is not cosmetic.** An initial-state violation has no behavior, and tlc2
prints no state-graph statistics for it. Without the flag a caller holding a
`trace` cannot tell whether it is a counterexample or a single offending state.
The console report has distinguished the two since R1 — only the typed result
did not, which is what made this a wire defect rather than an engine one.

The three arms that take no flag take none for a reason: a deadlock and a
liveness violation are properties of a behavior by construction, and an ASSUME
is checked before any state exists.

`outcome` already carried `initial=?` internally; the work was threading it to
the wire and auditing every construction site. Five needed a decision rather
than a mechanical edit:

- `-continue` violations are **behavior** violations by construction — an
  initial-state one returns from `doInit` before the search starts.
- Simulation reports what a behavior violated; it has no initial-predicate
  phase of its own.
- DFID's implied-init `%prop` can **only** be initial.
- The liveness path is a behavior violation.
- DFID's implied-**action** violation is a residue — see below.

## `api-version` stays 1, and that is the rule rather than an oversight

`compatibility.md` §10.6 is explicit:

> **There is no pre-release version history, deliberately.** The desk went
> through several internal reshapes of the job record, the state and the
> `%clay` bundle while it was being built. None of them is a version: no ship
> ever held that state and no caller ever saw that wire. ... So the counters
> were reset to the shipping value ... and `api-version` is 1.

R2's own preamble says the same thing in its first paragraph: *"This is not a
release. Nothing has shipped, no ship holds state worth preserving, and R2 may
reshape the wire and the agent state freely."*

So bumping to 2 would have **re-created exactly the pre-release version history
§10.6 removed on purpose** — and it would have been the second such reshape in
R2 alone, after R2.2 added `write` to `request`. `api-version` moves at release.

The reasoning is recorded at `api-version`'s definition in `sur/tla-lus`, not
only here, because that is where the next reader will be standing when they
wonder why a wire change did not move it. The stale forward-references in
`sur` and `lib/job` that called this "the one unit meant to move
`api-version`" were corrected in the same pass.

Worth noting what did *not* need doing: the agent's **state** version is a
separate counter, and `on-load` **coerces** with `;;` inside `mule` rather than
type-checking with `!<` — which §10.6 records was chosen precisely so a
restyled state still loads. A reshaped `violation` inside a persisted job is
that case.

## One residue, named rather than hidden

An implied-**action** violation is tlc2's EC 2112
(`TLC_ACTION_PROPERTY_VIOLATED_BEHAVIOR`), and this wire still folds it into
`%property` — a third meaning the flag does not address. R2.7.1's scope is the
invariant split, so it is recorded on the ledger row and in `lib/job` at the
site rather than quietly carried.

## Evidence

Two arms in `tests/lib/job` that **are** the split — same operator, same name,
different flag:

- `test-invariant-violated-by-behavior` — `Inv == x < 3` over a counter:
  `[%invariant 'Inv' %.n]`, and a `%trace` artifact.
- `test-invariant-violated-by-initial-state` — `Inv == x > 0` with `Init ==
  x = 0`: `[%invariant 'Inv' %.y]`.

Every pre-existing expectation across `job`, `mar/tla-lus` and `clay-load` was
a behavior violation, so all of them took `%.n` — which is itself a small check
that the flag defaults the way the corpus already believed.

Shards green: job, mar, app, clay-load, sim, sim-live, trace, inv-constraints,
mc, dfid.

Ledger: `tlc-safety-invariant` `partial` → **`parity`**, owed **11 → 10**.
