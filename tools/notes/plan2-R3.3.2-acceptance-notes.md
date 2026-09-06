# R3.3.2 — R3's acceptance, computed

```text
Sub-unit: R3.3.2 (R3 close-out, second of three)
Rows: none touched
Planned: `tools/r3-acceptance.py` + extend `release-gate.sh` for tier 3 as a
  REPORT. Do not edit `r1-acceptance.py`.
Found: the script does its job on the first run -- it reports R3 NOT ACCEPTED,
  and the clause that fails is the one decision R3 has not taken.
```

**Tools and docs only. No desk change.**

## 1. R3's acceptance sentence, stated because nothing else states it

`R3-work-breakdown.md` opens with where R2 left off rather than with an
acceptance paragraph, so this unit writes the sentence down and then computes
it:

> Every in-scope ledger row is terminal — `parity`, a tested
> `approved-difference`, `replaced` or `excluded` — with none owed; every
> differential CENSUS is empty, so no divergence is being carried; the docs
> agree with the ledger and the tree; the release gate passes; and the full
> ship suite is green. **Tier 3 is REPORTED, never gated.**

Five clauses, one report. `tools/r3-acceptance.py` computes each and prints
`R3 ACCEPTED` only if all five hold.

## 2. The clause R1 did not have: no census carries a divergence

R1's script asserted the ledger, coherence, the gate and the suite. R3 adds one
more, because **R3's whole character was censused divergences**: R2.8.2b froze
three in the examples batch and R3.0 closed them; R3.2 froze a fourth
(`BagsTest`) and R3.2a closed that. "The censuses are empty" is exactly the
thing a reader would otherwise take on faith, and it is the difference between
a closed ledger and a closed *project* — a row can be `parity` while a frozen
list beside it still carries an entry.

The clause reads all seven frozen lists out of `gen-tier2-tests.py` and the
withheld-arm map out of `gen-mc-tests.py`, by importing them, so it cannot
drift from the generators that own them.

**Its scope is stated rather than assumed.** It does NOT include the `SKIPS` in
`gen-stdops-tests.py` and `gen-core-eval-tests.py`: what remains there is
documented approved differences — `Print` has no console on this engine, tlc2's
multi-binder function print order — which `compatibility.md` carries and which
are terminal, not owed. Asserting those empty would demand the port stop
differing where it has argued, in writing, that it should.

## 3. Tier 3 is reported, and the decision is kept where it runs

`release-gate.sh` gains a `===== tier 3: REPORT, not a gate =====` section that
**never touches `FAIL`**. It runs `tools/tier3-report.py` only under `--tier3`
(the report drives a live ship), and otherwise prints why there is no clause:

> Report-only by R2.8.1a: median workload spread 15.6% on a fresh boot, over
> its own ±15% bar. Do not promote this to a clause without re-measuring.

That sentence is in the gate's *output*, not only in a comment, because the
next person to think "we should gate on performance" will be reading a gate
run, not a source file. R1.1.R3 named the failure mode — *a flaky gate is one
everyone learns to ignore* — and the way to keep a measured decision from
decaying into an omission is to make the tool say it every time.

`r3-acceptance.py` mirrors this: tier 3 is a `REPORT` line, never a clause, and
supplying `--tier3-log` prints the numbers without changing the verdict.

## 4. `r1-acceptance.py` is untouched, deliberately

It has printed `R1 NOT ACCEPTED` since R2.0 re-opened the ledger, and that is
the record of what R1 proved. A phase that wants a verdict writes its own
script. Editing a red gate to make it green is the failure mode the whole
discipline exists to prevent, and it is easiest to commit in exactly this
unit — the one whose job is to produce a verdict.

## 5. Running the gate found two clauses that had been red, unseen

This is the unit's largest finding and it is not about the script. **Running
`release-gate.sh` — which this unit had to do to extend it — showed R3 and R4
FAILING**, and both had been failing for a long time:

* **R3 (no stubs or TODOs): 1 hit**, `desk/lib/config.hoon:740`, in a COMMENT
  describing *tlc2's* Java TODO: *"its own TODO says the message would be bogus
  anyway"*. Prose containing the token, not a stub. Reworded; the clause greps
  for a token and should keep doing so.
* **R4 (refusals documented both ways): 11 undocumented refusals.** Nine
  predate R3 — `-coverage` in its three forms, `-continue with -dfid`,
  `-difftrace`, `-view`, `_PERIODIC`, `_RL_REWARD`, and probabilistic `CASE`.
  **Two are R3.0c's, and R3.0c introduced them by accident**: the multi-binder
  probabilistic messages were reworded to begin `unsupported:` — which is what
  makes a message *visible* to this clause — so narrowing a refusal to name its
  engine also brought it into the gate's view, correctly, and nothing added it
  to the table.

**Why nobody saw it.** `release-gate.sh` has failed by design since R2.0
re-opened the ledger, and the whole of R2 read that as "R2 in progress". A gate
expected to fail stops being read, so its other clauses rot behind the one
everybody knows about. **R1.8.8 found that a gate nobody runs is not a gate;
this is the sibling — a gate everybody expects to fail is not a gate either.**
`check-portmap.py` passes and R3.3.1 called the docs coherent, and both were
true: R4 is a stricter, different check that no unit had read the output of.

All eleven documented and the TODO reworded, so the gate now reads:

```
  PASS  scaffold-gate.sh: all gates
  FAIL  ledger not closed — 1 row(s) still owed
  PASS  tier2.py --check
  PASS  no TODO/FIXME/XXX in port code
  PASS  compatibility.md's refusal table matches the desk exactly
  PASS  version-tagged state, coercing on-load, resume-across-reload test
  PASS  oracle baseline regenerates byte-identically
  REPORT  tier 3 — not run (needs a ship); report-only by R2.8.1a
```

Six of seven green, one red for a named reason. That is a gate again.

## 6. First run of the acceptance script, and the decision it surfaces

```
  FAILS  every ledger row terminal, none owed
           134 rows, 133 terminal, 1 owed
  HOLDS  every tier-2 census empty, no mc arm withheld
  HOLDS  docs coherent with the ledger and the tree
  FAILS  release gate passes            (--skip-gate: not run, so not asserted)
  FAILS  full ship suite green          (evidence the caller must supply)
  REPORT tier 3 (performance)           report-only by R2.8.1a
```

Two of the three failures are the script working as designed: a gate that was
not run and a measurement that was not supplied are not passes.

**The third is a real decision R3 has not taken.** The owed row is
`check-mode-generate` — `+psolve` still refuses a multi-binder existential or
universal in PROBABILISTIC mode, which R3.0c made visible by porting the
exhaustive path. R3 cannot be accepted while it stands, so the project has two
honest ends and this unit does not get to pick:

* **close it** — one named measurement (does `SubsetEnumerator` reseed on
  `reset()`? that decides the RNG call sequence and therefore which successor a
  `-generate` run picks), then the same odometer the exhaustive path already
  has; or
* **hand it to R4 by name**, the way R2 handed its three re-opened rows to R3,
  with the measurement written down so the next phase starts from it.

What must not happen is the third option: an acceptance script edited to stop
asking.
