# R2.7.7.1 — the four keywords are refused by name

```text
Sub-unit: R2.7.7.1
Claim being measured: "a few lines: every one of the four either does
  something or is named in a rejection, before the run starts"
Measurement result: the rejection IS a few lines. What was not budgeted is
  what the refusal makes visible -- a tier-2 batch spec that was passing while
  two of its keywords were ignored.
```

## What shipped

`+unsupported-kw:config` takes the parsed `cfg-ast` and returns the refusal for
the first unsupported keyword present, naming the keyword AND what it would
take:

```text
unsupported: POSTCONDITION Post; tlc2 evaluates it after state-space
exploration and fails the run when it is false, so accepting it here would
report `ok` for a run tlc2 fails
```

Both paths check it before anything runs — `+search-ctx-seed` on the console
and `+do-config` in the kernel. Two sites, not one, because `run-spec` carries
none of these four fields and each path parses the config itself; the same
shape R2.7.5 used for the EC 2279 guard. The kernel's is a `config-fail` with
code **0**, the port-local code, because the pin SUPPORTS these keywords and
has no EC for refusing them.

## The drift guard, which is the durable half

`+kw-handled` and `+kw-refused` split `+keywords` in two, and
`tests/lib/cfg-runspec`'s `test-cfg-keyword-coverage` asserts:

- their union is `+keywords` **exactly** (both directions, not just a count);
- their intersection is empty.

A keyword added to the parser without a decision now fails there. That is the
guard `gen-stdops-tests.py` gives the 131 operator surfaces, which R2.7.7.0
found this side never had — and its absence is the whole reason POSTCONDITION
sat accepted-and-ignored for two releases with a green suite.

Six arms: the guard, one refusal per keyword, and a clean config that must NOT
be refused. The refusal text is asserted by PREFIX via a `+starts` helper
rather than a hand-counted `scag` length — the first draft counted three of the
four wrong, which is a good argument for never writing the length by hand.

## The consequence, taken deliberately

`SubseteqNextState` was **passing** the tier-2 safety batch with `_POSSIBLE
FullSet GainThree` and a `POSTCONDITION` reading
`TLCGet("all:named")["s:_possible"][1]` — both ignored. It agreed only because
the postcondition HOLDS at the pin, so a verdict+counts comparison could not
see the gap. It is now a **censused divergence**: a refusal rather than a
silent wrong answer.

That is the right trade and worth stating plainly: a green batch that is green
for the wrong reason is worse than a recorded divergence, and the entry closes
with R2.7.7.3 + .4.

**The census entry was frozen from the SHIP RUN, after a first draft got it
wrong.** I predicted `_POSSIBLE` — the keyword the row is about — and the port
refuses on POSTCONDITION first, because `+unsupported-kw` checks in
declaration order, with the console's `Error: ` prefix. `test-tlc-batch`
caught it. The file's own rule ("frozen from the ship run") exists for exactly
this.

## Rows

`cfg-postcondition`, `cfg-possible`, `cfg-internal-kw`: `absent` → **partial**.
The invariant is repaired; the capability is not. Ledger unchanged at 134 rows
/ 9 owed.

## Evidence

`tests/lib/cfg-runspec` 6 new arms, all passing. Config-affected shards (mc,
cfg, cfg-val, cfg-runspec, job, app, clay-load, trace, coverage) green; tier-2
re-run after the census correction.
