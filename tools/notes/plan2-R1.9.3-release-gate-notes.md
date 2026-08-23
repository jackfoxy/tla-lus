# P2-R1.9.3 — the real release gate

`scaffold-gate.sh` has always said what it is, in its own banner: it proves
scaffold **hygiene**, not parity, and it **passes whatever the ledger owes** —
it only prints the number. That was the right instrument while rows were open.
The ledger closed at R1.8.6, so the instrument can now exist.

`tools/release-gate.sh` runs the scaffold gate and then adds six release-only
gates:

| | gate | why the scaffold gate could not |
|---|---|---|
| R1 | ledger **closed** — zero `partial`/`absent`/`oracle-only` | the scaffold gate reports the count and passes regardless |
| R2 | **tier 2** green (`tier2.py --check`) | the scaffold gate runs only tier 1 |
| R3 | no stubs/TODOs in **port** code | never checked |
| R4 | every refusal documented **both ways** | never checked |
| R5 | upgrade / restart | gate 6 checks the *mechanism*; this also requires the test that exercises it |
| R6 | reproducible oracle artifacts (`regen.sh --check`) | run by `validate.py` inside tier 1, but never asserted as a release condition |

## R3 and R4 had to be scoped by measurement, not by intent

**R3 (no stubs).** A naive `grep -r TODO desk/` fails immediately — but every
hit is in `lib/stdmods.hoon`, the **vendored MIT StandardModules**, whose TLA+
text contains upstream `TODO`s and must stay byte-verbatim. `default-agent`,
`dbug` and `skeleton` are stock Urbit libraries. The gate exempts those four
files by name and checks the rest, so the check means "no stub in code we
wrote" rather than "no occurrence of a string".

The `!!` surface is deliberately **not** part of this gate: R1.2.7 already
audited it to 16 labelled sites with an argument recorded beside each, and
`lib/eval.hoon`'s header documents its own exemption. Re-litigating that with a
grep would be a worse check than the audit it would replace.

**R4 (refusals documented both ways).** This is the one that found bugs. The
gate asserts that the set of `'unsupported: …'` literals in `desk/lib` and
`desk/app` **equals** the set `compatibility.md`'s typed-rejection table lists.
Running it the first time found the set unequal in both directions:

- **documented but gone**: `unsupported: temporal property form (only <>P,
  []<>P, []P; unit 8)`. R1.8.1's full normalizer removed that rejection —
  `<>P`, `[]<>P`, `[]P`, `~>`, `-+->`, `WF_`/`SF_` and `<>[]` all run now, and
  a formula the normalizer genuinely cannot decompose gets **the pin's own**
  `TLC cannot handle the temporal formula …`. The doc had promised callers a
  refusal that no longer exists.
- **real but undocumented**: `unsupported: INVARIANT and PROPERTY in one config
  (unit 7)` — a refusal a caller can hit, listed nowhere.

Both fixed; the two sets are now equal, and the gate keeps them that way. A
one-directional check would have caught only the second.

## A bash lesson, paid for once

The gate's first run reported `RELEASE GATE: FAIL` with all six release gates
green and the scaffold sub-run dying on a syntax error at line 52 — in a file
`bash -n` said was clean. The cause was mine: I edited `scaffold-gate.sh`
(rewriting its banner to point at the new gate) **while the release gate was
executing it**. Bash reads a script incrementally by byte offset, so inserting
eight lines mid-run made it resume in the middle of a statement. The file was
never broken; the running interpreter was. Re-run on the settled file, clean.

Worth writing down because the failure looks exactly like a real defect and
nothing in the output points at the cause.

## What the gate still cannot do

Run the ship suite. `-test /=tla-lus=/tests ~` needs a running ship, so the gate
names it as the remaining condition instead of pretending — exactly as the
scaffold gate always has. R1.9.4 is where the two are run together and the
acceptance sentence is asserted rather than asserted-by-hand.

`scaffold-gate.sh` is kept, not replaced: it is the fast hygiene check to run
per-increment, and the release gate calls it rather than duplicating its ten
other checks. Its banner now points at the release gate so nobody mistakes one
for the other again — which is the mistake R1.8.8 found had already been made
for nine units.
