# P2-R1.8.8 — R1.8 close-out

R1.8 is done. **All eight ledger rows it inherited are terminal, and so is every
other in-scope row: 125 / 125, 0 owed.**

| row | in | out |
|---|---|---|
| `tlc-queue` | partial | **parity** (R1.8.0, no code) |
| `tlc-util-combinatorics` | partial | **excluded** (R1.8.0, no code) |
| `src-inline` | partial | **parity** (R1.8.0, no code) |
| `src-clay-async-load` | partial | **parity** (R1.8.0, no code) |
| `cfg-validate` | partial | **parity** (R1.8.2) |
| `check-opt-cfg` | partial | **parity** (R1.8.2) |
| `cfg-runspec` | partial | **parity** (R1.8.3) |
| `tlc-driver` | partial | **replaced** (R1.8.6) |

Half of them closed by measurement alone. That is the unit's own headline: the
audit (`.0`) cost one sitting and cancelled four units of planned work.

## Gates

| gate | result |
|---|---|
| tier 1 — `validate.py --check` | **PASS**, all goldens reproduce byte-identically from the pin |
| tier 2 — `tier2.py --check` | **PASS**, inventory + curated oracle + comparator shards reproduce byte-identically from the pins |
| full ship suite — `-test /=tla-lus=/tests ~` | **PASS** — `ok=%.y`, **1959 arms, zero failures**, after the one failure below was analysed and censused |
| `check-parity.py` | 125 rows, **0 owed**, well-formed |
| `scaffold-gate.sh` | **PASS**, 10/10, after the gate-6 fix below |

`evidence-counts.md` regenerated: `gen-cfg-val-tests` 27 → **39** across R1.8.2
(+8) and R1.8.6 (+4); compared cases **1063**.

## The close-out found a stale gate

`scaffold-gate.sh` gate 6 required the literal migration chain
`jobs-0-to-1` / `jobs-1-to-2` / `jobs-2-to-3` in `lib/migrate`.

**R1.5.12b deleted that chain on purpose** — the commit says so in the code it
left behind: *"Nothing has been released, so the pre-`%3` chain that used to live
in /lib/migrate was collapsed rather than carried."* The gate was not updated
with it. So the scaffold gate had been **failing since 2026-08-17**, through
R1.6, R1.7, R1.1.R0–R4 and R1.8.0–.6, and nobody saw it, because every unit in
that stretch ran only its touched shards.

The code was right and the gate was wrong. Gate 6 now checks the **mechanism the
design actually guarantees** rather than one historical chain:

- a `+$  versioned-state` union exists,
- `on-load` **coerces** the stored noun (`;;(versioned-state …)`) instead of
  requiring it to nest — which is the property that keeps a mold change from
  discarding completed results,
- `on-load` dispatches `?-  -.old` on the version tag,
- the current state mold matches the script's own `DESK_STATE` (`%3`), a variable
  that until now was printed in the summary and never actually asserted.

That last one is the useful part: the next version bump has to touch
`DESK_STATE`, and the gate will say so.

**Lesson, and it is the same one this release keeps learning.** A gate that never
runs is not a gate — it is a claim. Nine units passed over a red gate because
their scope was "run the touched shards", and the touched-shard discipline is
correct but it cannot see a gate. R1.1.R4 recorded the sibling of this: the full
suite caught a cross-shard breakage that touched-shard runs structurally could
not. Both belong to close-out units by construction, which is why R1.8 has one.

## The full suite found one real failure — and it vindicated R1.8.6

`tests/lib/tier2/test-tlc-batch` failed:

```
Github746 -> Error: unsupported: ALIAS (trace rendering through an alias; unit 7)
```

`Github746.cfg` declares `ALIAS Alias`, and R1.8.6 turned the silent ALIAS
no-op into a typed rejection. The first reading is "R1.8.6 broke a passing
spec". Measuring it says otherwise. Run against the pin, TLC renders the
violating state **through the alias**:

```
Error: Invariant Inv is violated by the initial state:
/\ i = 1
/\ foo = "bar"
/\ j = TRUE
```

The port printed the raw binding `i = 1`. **The silent ignore had been producing
a wrong trace all along**, and the comparator structurally could not see it:
`tlc_projection` starts capturing trace lines only after
`Error: The behavior up to this point is` or `Error: The following behavior
constitutes a counter-example`, and an initial-state violation is announced by
`Error: Invariant Inv is violated by the initial state:` — neither marker. So
the spec agreed on `[verdict, counts, depth]` while disagreeing on every state
line beneath them.

This is a pre-existing divergence becoming **visible**, which is precisely what
refusing an unsupported option buys. It is censused, not silenced:
`TLC_BATCH_DIVERGENCES` gains the entry with that reasoning, and the safety
batch reads **13/14 agree, 1 listed**. Restoring the silent ignore would re-hide
it; closing it means implementing alias trace rendering, which is a feature and
not close-out work.

Note the shape of this, because it is the third instance in one unit: a
projection that does not look at something cannot report it agreeing. The
generated count is dropped by design and *documented*; the alias-rendered
initial state was dropped by accident and was not.

## What R1.8 did not do

Nothing in R1.8's scope was left out. Two things it deliberately handed on:

- **VIEW-based fingerprinting and ALIAS trace rendering** are unimplemented.
  R1.8.6 turned them from silent no-ops into typed refusals with the pin's own
  validation errors, which is the release doctrine, not a substitute for the
  feature. If they are ever wanted they are their own unit, not residue on a
  closed row.
- **The scaffold gate is still the scaffold gate.** Its own header says the real
  release gate additionally requires the ledger closed to terminal statuses —
  which is now true, for the first time. Replacing it is R1.9.3's job, and R1.9.3
  can now actually do it.
