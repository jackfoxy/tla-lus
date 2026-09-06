# R2.8.2b — the examples coverage, and the rule that under-reported it

```text
Sub-unit: R2.8.2b
Rows: tlc-eval-node, tlc-eval-action, cfg-runspec (all three DEMOTED here)
Planned: consume R2.8.2a's selection rule, add the specs it names under the
  nightly budget, report the count, the rows newly exercised and the runtime
  delta. R2.8.2a's answer was ADD NOTHING and the row provided for closing on
  that.
Found: the rule was wrong in four ways, all in the direction of reporting less
  work than there is. Corrected, it names candidates; applied, the FIRST FOUR
  `tlaplus-Examples` specs ever run through the Hoon checker produce THREE
  divergences, none of them reachable from any spec the corpus already ran.
```

## 1. Why "add nothing" was not the answer

R2.8.2a shipped the rule as `tools/tier2-select.py` and reported *"candidates
that bring an unexercised row: NONE"*. Reproduced exactly, first run. Then
audited, because a rule whose answer is "no work" is the one place an error
cannot be caught by the work failing.

Four defects, each independently sufficient to produce that answer:

1. **The checked set was wrong.** The rule credited `CigaretteSmokers` and
   `SimpleAllocator` as checker-exercised, and dropped `DieHard`. Its
   `CURATED_EXAMPLES` constant was copied from the generator's `CURATED` list —
   which is the **oracle capture** (a pinned `.txt` of Java's output), not the
   checker set. The specs that reach `check:check` are `TLC_BATCH` (14) +
   `TLC_LIVENESS_BATCH` (9) + **`TLC_CURATED` (3)**, and `TLC_CURATED` held only
   `DieHard`, `HourClock`, `TCommit`. Crediting two specs the checker never runs
   hid three features on its own: `assume`, `rcdset`, `symmetry`.
2. **It matched features inside comments.** `SimpleAllocator.cfg` carries
   `\** SYMMETRY Symmetry`, commented out with the upstream author's warning
   that symmetry breaks its liveness properties. That comment was the *only*
   evidence of SYMMETRY coverage anywhere in the corpus.
3. **Its config fallback globbed `*.cfg` and took the first**, so a spec with no
   config of its own was scored on a sibling module's config.
4. **It never asked whether a candidate has a config at all.** A spec TLC cannot
   be pointed at is not a comparator candidate; three in-scope examples specs
   are in that position.

Corrected, the checker set is **26**, and the unexercised list is not four
features but **seven** — `assume`, `bags`, `instance`, `rcdset`, `reals`,
`symmetry`, `view` → `tlc-safety-assume`, `tlc-module-bags`,
`semantic-instance`, `tlc-eval-node`, `tlc-module-reals`, `tlc-symmetry`,
`cfg-view`. **`ASSUME` had no checker-exercised supplier at all**, in a corpus
of 26 specs, and both examples specs that bring it diverge.

**The generalizable bit**, and it is R2.8.2a's own lesson pointed at itself:
that unit found a regenerated artifact does not regenerate the sentences about
it. This one is a step further — **a rule written to answer "is there work?"
was itself the artifact nobody checked**, and its answer was quoted forward as a
measurement. It shipped as code precisely so it could be re-run; re-running it
is not the same as auditing it.

## 2. What was added, and what it cost

`TLC_EXAMPLES_BATCH` in `tools/gen-tier2-tests.py` → the generated
`test-tlc-examples-batch` arm in `desk/tests/lib/tier2.hoon`. Same comparator
(`+tlc-batch-run`, the whole projection), same census discipline as the two
test-model batches: one `mule`-isolated arm, divergences **frozen by name** so
the arm fails if a new one appears or a frozen one is fixed.

Four specs, ordered cheapest-first by MEASURED port cost — the rule's own
tie-break, where it had been using file size as a proxy:

| spec | rule picked it for | tlc2 | port | s |
|---|---|---|---|---|
| `AsynchronousInterface/Channel` | `rcdset` | ok, 12 distinct, depth 2 | **agrees** | 2.1 |
| `SimpleMath/SimpleMath` | `assume` | ok, 0 distinct, depth 0 | refuses | 3.0 |
| `CigaretteSmokers` | `assume`, `rcdset` | ok, 6 distinct, depth 2 | refuses | 5.7 |
| `SimplifiedFastPaxos/Paxos` | `symmetry` | ok, 1207 distinct, depth 22 | refuses | 19.7 |

**Runtime delta: +31.7 s**, measured by running the generated arm verbatim on
the ship, against a `tier2.hoon` dominated by `test-sany-batch` at ~7.5 min
(the first three alone were 8.7 s; `Paxos` is most of the rest). Not
budget-bound — the rule ran out of candidates first, which is what R2.8.2b's
row said would close it.

**Rows newly exercised: one, green.** `Channel` brings record sets
(`[val: Data, rdy: {0,1}, ack: {0,1}]`) and agrees byte-for-byte. The other
three are the rule's real yield and they are all refusals.

## 3. The three divergences

Each is a REFUSAL — the port answers a typed error where tlc2 answers a verdict
— so none is a wrong answer, and each is invisible to every existing arm.

**`CigaretteSmokers` → `tlc-eval-node`.** `ChooseOne(Ingredients, LAMBDA x :
smokers[x].smoking)`. `+resolve-oparg` (`node-eval.hoon:1748`) resolves an
operator argument by NAME (`+oparg-name`); an anonymous `$OpArg` has none, so it
answers `~` and `+bind-params`/`+bind-psub` raise. **The row predicted this and
mis-assigned it**: R1.4.1b wrote that the operator-valued-argument site is
*"reachable only via LAMBDA, which is absent from the WU3 semantic graph — a
unit-3 residue, not this row's"*. R1.3.1 then put LAMBDA op-args IN the graph.
The unit-3 half closed, the evaluator half was owned by nothing, and the row
closed at R2.7.16 with it open. `tlc-binders` says it from the other side —
*"the only skips anywhere in the shard are three LAMBDA sites in `ev-oparg` (a
unit-3 residue)"*. Confirmed at minimal scale so the future fix has a target
that is not a 60-line spec:

```tla
Pick(S, P(_)) == CHOOSE y \in S : P(y)
Init == x = Pick({1, 2, 3}, LAMBDA n : n > 2)
```

tlc2: ok, 1 distinct, depth 1. Port: `Error: unsupported operator-valued
argument.`

**`SimpleMath` → `cfg-runspec`.** A config with **no behaviour spec at all**.
`+resolve-targets` (`check.hoon:2449`) requires INIT+NEXT or SPECIFICATION;
tlc2 runs an ASSUME-only module as an ordinary BFS with zero initial states and
reports completion, 0/0/0, depth 0. That is the documented idiom for using TLC
to evaluate expressions — `SimpleMath` and `PrintValues` exist for it and say so
in their own comments. **The refusal fires at `check.hoon:2520`, before
`+check-assumes` at `:4276`**, so the port does not check the assumptions
either, which is the whole content of such a module. `PrintValues` measures the
identical refusal and was deliberately NOT added: same row, no new coverage,
corpus weight.

**`Paxos` → `tlc-eval-action`.** `\E a \in Replicas, m \in p1aMessages : ...` —
a multi-binder existential in ACTION position, in all four of its actions.
`node-eval.hoon:2091`/`:2530`. R1.4.1b measured that the CONSTANT multi-binder
`\E`/`\A` already evaluate and that **"only the action paths are open"**;
R1.4.3 closed the multi-binder CONSTRUCTORS and nothing tracked the action path
afterwards. **And the second measurement is the sharper one**: the rule picked
Paxos for SYMMETRY — it is the only in-scope `tlaplus-Examples` spec with an
uncommented `SYMMETRY` line — so *the port never reaches symmetry on the one
spec that would test it*. `tlc-symmetry` stays unexercised by tier 2 and there
is no other examples supplier.

Ledger: **134 rows, 131 terminal, 3 owed** (was 134/0 after R2.7.16).

## 4. What the rule says now, and what it does not

With the four specs counted as checked, the rule returns **no candidates**: 30
checked, `bags`/`instance`/`reals`/`view` unexercised, and no in-scope
`tlaplus-Examples` spec with a config of its own supplies any of them. **That is
the answer R2.8.2a gave, arrived at for the first time honestly**, and R2.8.2b
closes on it.

**One more correction to the rule, made because this unit's own additions
would otherwise have overstated it.** A censused spec has to count as checked,
or the rule proposes the same specs forever — but counting it as *coverage* is
what R2.8.2a did with the oracle capture. `Paxos` is the case that forces the
distinction: it was selected for SYMMETRY and the port refuses it on a
multi-binder action existential, so the symmetry machinery is never reached.
The tool now prints three groups, not two:

```
  exercised, AGREEING: alias, choose, constraint, except, fairness, fcnset,
                       finitesets, rcdset, recursive, seq, subset, temporal, tlcops
  reached ONLY by a censused divergence: assume, symmetry  <- the port refuses;
                                                              not coverage
  NOT exercised: bags, instance, reals, view
```

So what R2.8.2b actually bought in agreeing coverage is **one feature**
(`rcdset`); what it bought in *measurement* is three refusals that nothing was
looking for. Those are different quantities and the tool now says which is
which.

What a future coverage unit would have to look at, named rather than left to
be rediscovered:

- `tlc-module-bags` is suppliable, but from the **test-model** corpus, not
  examples: `BagsTest.tla` plus `suite/test23bis`, `test36`, `test50` are all
  `check`-class with configs. R2.8.2a's note says the four rows it found
  *"would have to be built rather than found"*; that is true for examples and
  false for the corpus, and `tools/tier2-select.py --corpus both` now shows it.
- `cfg-view`, `semantic-instance`, `tlc-module-reals` have no supplier in
  either corpus at the pin.
- `tlc-symmetry` has exactly one, `Paxos`, and it is blocked behind
  `tlc-eval-action`. Closing that row makes this spec a symmetry differential
  for free — the highest-value single fix the census points at.

## 5. Process notes

- **The probe shard.** Verifying a new tier-2 arm by running `tier2.hoon` costs
  30+ minutes (`test-sany-batch` alone is ~7.5 min at 100% CPU). Every
  measurement here was taken by generating `desk/tests/lib/tier2-probe.hoon` —
  the shard's own 123-line preamble plus the one arm under test — committing and
  running that. The final arm was verified by extracting it **verbatim from the
  regenerated `tier2.hoon`**, not by rebuilding it, so what ran is what ships.
  The probe file is deleted; it is not part of the desk.
- **`tools/__pycache__` is tracked in git.** `tier2-select.py` now imports the
  generator (so the checked lists cannot drift from it) and that import rewrote
  a committed `.pyc`. It sets `sys.dont_write_bytecode` before importing.
- **The oracle cost is not the file size.** The rule ordered candidates
  cheapest-first by `.tla` size; measured against the pin, `c1cs` (9 KB) and
  `bosco` (8 KB) both time out at 180 s while `Paxos` (10 KB) answers in 4.2 s.
  The batch is ordered by measured port cost instead, and the tool's ordering
  is documented as the proxy it is.
