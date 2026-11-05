# R4.4 — Unicode, clause 8 (2026-11-04)

```text
Clause 8: for all 373 parse-census modules converted with the pinned
          `tlauc --skip numsets`, (a) the port's verdict on the converted
          text = pinned SANY's, and (b) the port's semantic graph of the
          converted module = that of its ASCII original
Oracle:   (a) tier2/examples/sany-unicode: SANY exit 0 on all 373
          (examples-oracle.py's Unicode leg, R4.0c)
```

## Findings before any run

- tlauc keeps every line of all 373 modules (none gains or loses a line);
  17 come out unchanged (nothing to rewrite). It changes the width of a
  symbol (`\in` → `∈`) and re-pads junction lists, so **columns move and
  lines do not**.
- Graph identity is therefore taken on the SemDump projection (`+dump-sem`:
  every declaration, definition, theorem, assumption and instance of the
  module, each node's operator, kind and level, and the LEVELS block) with
  every span's **columns elided and its lines kept**. The pin agrees that
  this is the right notion: Java's own SemDump of the R4.4 fixture and of
  its conversion are identical under exactly that elision.
- Imports are not compared inside a module's dump; they are the other
  modules' own definitions, each compared as its own census row. Library
  roots are ASCII in both variants, as CI leaves them.
- The port counts columns per code point, as Java does for BMP input, so
  the converted text is also compared with SemDump **byte-exactly, columns
  included**, in the new shard.

## Tooling

- `tools/examples.py --stage` also writes `unicode/specifications/...`: the
  same directories, each manifest module converted in place as CI's
  `unicode_conversion.py` does, PlusCal modules and configs copied. Licenses
  beside it: `unicode/license.txt` (tlauc) and
  `unicode/specifications/license.txt` (Examples). tla-zod's `%tla-ex` is at
  revision 22 with it (625 files added; no other file changed).
- `tools/examples.py --parse --unicode`: (a), the R4.1b parse census through
  the agent's public wire over the converted copy
  (`desk/test-data/blackbox/parse-census-unicode.txt`).
- `tools/ship/sem-identity.hoon` (a dojo generator, copied to the
  `%tla-lus` mount's `gen/`) and `tools/ship/sem-identity.py` (its tmux
  driver, each call under `guarded.sh`): (b), per module, `+dump-sem`'s
  pipeline over `<dir>` and `unicode/<dir>` with the library roots after
  each, columns elided, plus the `+sany-verdict` rule for both
  (`desk/test-data/blackbox/unicode-identity-census.txt`). Bite: with the
  elision removed, Voting reports `same=n` at its first span.

## New tests

- `tools/gen-unicode-tests.py` → `desk/tests/lib/unicode.hoon` (3 arms,
  registered in `validate.py`): fixture `desk/test-data/unicode/symbols/`
  (written for the suite; A.tla exercises every rewritten spelling, nested
  junction lists, `INSTANCE ... WITH`, temporal operators, `LET`, a
  theorem), converted by the pinned tlauc at generation time. The port's
  `+dump-sem` of both variants = SemDump byte-exact; `+sany-verdict` of the
  conversion = SANY's. Generation fails unless the two goldens are equal
  with columns elided. Bites: one `∈` put back to `\in` in the converted
  source fails the arm. `license.txt` (tlauc) beside it; gen-licenses
  `--check` passes.
- The fixture's instanced module has ONE definition: with two, SemDump lists
  them in Hashtable order (R4.2ac, the approved `var-order-hashtable`
  difference), which the sem suite already withholds.

## Results (2026-11-04)

| census | rows | result |
|---|---|---|
| (a) `examples.py --parse --unicode --parse-secs 3600` (agent wire) | 373 | **373 agree** (`success` = SANY exit 0) |
| (b) `tools/ship/sem-identity.py` (pre-fix, `logs/unicode-identity-census-prefix.txt`) | 373 | accept/accept; 371 identical, 2 not |
| (b) re-run on the fixed code (`desk/test-data/blackbox/unicode-identity-census.txt`) | 373 | **373 accept/accept, 373 identical** |

Clause 8 holds: 373/373 on both halves.

### Interrupts

- ⚠ 11:54: the dojo will not take a path literal whose segment holds a
  `.` (`/specifications/cartalkpuzzle/cartalkpuzzle.toolbox/model_1`); the
  line sat unsent until `guarded.sh`'s 1,800 s cap. The driver now passes
  `(stab '...')`.
- ⚠ 13:06: the 2 non-identical rows, KeyValueStore's ClientCentric and
  MCKVsnap (which extends it). A **port bug, on the ASCII side**: the root's
  LEVELS `lc` was one `i<=3` short of SemDump; the conversion matched
  SemDump. `+bound-key` keyed a binder by `line.col` alone, and
  ClientCentric's `CHOOSE i` (48:21) shares its position with an `i` in
  `Sequences`; tlauc moves ClientCentric's columns, so only the original
  collided. The user chose the full fix.

### The fix (`lib/semantic`)

- `+bound-key` adds the module whose text the binder is in:
  `lenv.mod`, set to the module under check, to the instanced module inside
  a `$SubstIn` body (`+l-substin`; the WITH expressions keep the outer one).
- A subexpression selected from another module's definition
  (`Y == QNonEmpty!:` with `QNonEmpty` from B) is B's node in SANY, so
  `+defentry` records the defining module (`+bodymap`, `+ext-bodies`) and
  `+resolve-one` emits `$Nop:B`; the level check checks its body under B
  (`+nop-mod`). The renderer prints `$Nop`; `node-eval`, `check` and
  `temporal` match `$Nop` by prefix.
- New sem cases `binder-pos-ext` (EXTENDS) and `binder-pos-inst`
  (INSTANCE ... WITH), Java goldens `lc={i<=3,i<=3}`; `sel-ext-def` holds
  the selector half. Bites on the ship copy: the old key fails both new
  cases (one `i<=3`); an untagged `$Nop` fails `sel-ext-def` (`q<=3` twice).
- Gates: sem shard ok; the 65 shards + `lib/unicode` 66/66
  (`logs/r44-regress.txt`); the 16-row targeted census
  (`logs/census-r44.txt`) = census-qs counts on every row; full (b) re-run
  373/373; scaffold gate + `validate.py --check`.

### Times (user: record every final time for the performance docs)

Per-module seconds are in both census files (`secs`). Summary:

| census | total | median | p90 | p99 | max |
|---|---|---|---|---|---|
| (a) agent `%analyze`, converted text, `--poll 5` | 3,037 s (51 min) | 5.7 | 16.1 | 27.3 | 92.3 |
| (b) generator, both variants, fixed code | 4,200 s (70 min) | 7.5 | 23.7 | 53.2 | 123.8 |
| R4.1b ASCII parse census (2026-10-11 code), for reference | 13,593 s | 14.0 | 89.7 | 215.8 | 890.7 |

(a)'s rows include up to one poll interval (5 s; minimum row 5.1 s): 304 of
373 finish under 10 s, 50 in 10–20 s, 18 in 20–40 s, one over 40 s
(`tcp_proof`). (b)'s rows are a dojo generator's wall clock under
`guarded.sh`, both variants plus about 2 s of dojo overhead.

Same-code A/B, `%analyze` through the wire with `--poll 1` (ASCII / converted):
`tcp_proof` 86.4 / 87.3 s, `EWD687a_proof` 43.7 / 46.6, `EWD687a_anim`
47.2 / 39.9, `EWD998_anim` 46.0 / 37.5, `EWD998ChanID_export` 23.5 / 24.8.
**Unicode costs nothing measurable**, so the 4.5× against R4.1b comes from
the code since then (R4.P12's parse cache and Q7's generation memo are the
front-end changes; not separately measured here), not the spelling.

Slowest ten, (a) / (b) / R4.1b:

| module | (a) | (b) | R4.1b |
|---|---|---|---|
| tcp/tcp_proof | 92.3 | 123.8 | 890.7 |
| ewd687a/EWD687a_proof | 39.5 | 80.2 | 221.3 |
| ewd687a/EWD687a_anim | 33.1 | 65.8 | 114.3 |
| ewd998/EWD998_anim | 27.3 | 53.2 | 131.7 |
| ewd998/EWD998ChanID_export | 26.5 | 43.4 | 108.4 |
| ewd998/EWD998PCal_proof | 26.3 | 37.9 | 193.8 |
| bcastByz/bcastByz | 25.6 | 46.3 | 237.5 |
| tower_of_hanoi/Hanoi_anim | 25.2 | 36.1 | 79.1 |
| ewd998/EWD998ChanTrace | 25.0 | 35.0 | 100.8 |
| ewd998/EWD998_proof | 24.9 | 32.8 | 215.8 |

Targeted census wall times (`logs/census-r44.txt` against census-qs, same
counts): within the box's day-to-day drift, except EWD998ChanID 31 s vs
803 s, SimpleAllocator 57 vs 230, MCReachable 33 vs 274, MCNanoLarge 60 vs
180 — census-qs predates Q7/QW, so this is not an R4.4 effect.
