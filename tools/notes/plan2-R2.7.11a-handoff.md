# Handoff — written at the close of R2.7.11 (2026-08-31)

> **SUPERSEDED IN PART — R2.7.11a is DONE (2026-08-31).** `tlc-live-lasso` is
> `parity`; the ledger is **134 rows, 131 terminal, 3 owed**. The acceptance
> hypothesis below was tested and DISPROVED, and the traversal-order worry
> turned out not to apply: the selection is keyed on `+box-free-tf`. See
> `plan2-R2.7.11a-lasso-selection-notes.md`. Item 1 of the owed list is closed;
> items 2-4 stand, and everything under "The dev ship" and "Corpus mechanisms"
> still holds — except that `SKIPS` in `gen-mc-tests.py` is now EMPTY.

For a fresh session. Read `~/FoxyLabs/tla-lus/R2-release-work-breakdown.md`
first; this file says where that plan actually stands and what bit me.

## Where the project is

Committed through **R2.7.10** (`63bc65a2`). Ledger: **134 rows, 130 terminal,
4 owed** (`tools/check-parity.py`). `scaffold-gate.sh` PASS, tier-1
`validate.py --check` OK, `check-portmap.py` coherent, tier-2 census has **zero
divergences**.

**Uncommitted in the working tree**: `desk/doc/parity-manifest.md` (R2.7.11's
`tlc-live-lasso` row update) and `tools/notes/plan2-R2.7.11-lasso-minimality-notes.md`.
Nothing else — R2.7.11 changed no code (its probe was reverted).

The user commits each unit themselves and runs the full suite; **do not run
`-test /=tla-lus=/tests ~` and do not commit**. Ask.

## The four owed rows, in the order I would take them

1. **`tlc-live-lasso` — R2.7.11a.** The unit I just measured and did NOT close.
   Read `plan2-R2.7.11-lasso-minimality-notes.md` before touching it. Short
   version: two length heuristics have each been fitted to one case; the pin's
   prefix comes from `dg.getPath(state, tidx)`, i.e. TLC's own TRAVERSAL ORDER
   over a disk-backed graph. **Test the acceptance hypothesis first** (is the
   port's State-11 node in `gh1389-counting` genuinely accepting?) — it is
   cheap and would explain both directions. Frozen reproducers:
   `gh1389-counting` (the better one, no post-error block) and
   `live-after-inv`.
2. **`tlc-live-normalize` — R2.7.6.2's leftovers.** `Github1389Counting` and
   `ViolatedC` were blocked on POSTCONDITION, which R2.7.7.3 shipped. They may
   simply run now — MEASURE before planning. `ViolatedC` also wants
   `TLCExt!CounterExample`, which is still unported.
3. **`tlc-live-diagnostics` — R2.7.12.** One clause left: the violated-property
   name comes from the FIRST `PROPERTY` rather than the violated one.
4. **`cfg-postcondition`** — two deferred items, both named on the row:
   `-postCondition mod!op` (a REQUEST field, not a `.cfg` keyword) and
   `TLCExt!CounterExample`.

Then R2.7.13 (residue triage), R2.8 (tier 3), R2.9 (close-out).

## The dev ship

```
/mnt/mars/piers/tla-zod/.run --loom 32 /mnt/mars/piers/tla-zod
```
tmux session `tla-zod`; drive with `send-keys` (`-l --` for lines starting with
`-`), deploy by `cp`ing changed files from `desk/` into
`/mnt/mars/piers/tla-zod/tla-lus/` then `|commit %tla-lus`.

**Traps that cost me real time this session:**

- **Scrollback lies.** `tmux capture-pane` shows old runs. Poll for the run's
  OWN command echo and confirm the verdict sits below it, or you will read a
  previous `ok=%.y`. I misread this three times.
- **A commit is not synchronous.** The dojo returns its prompt before Clay
  finishes; wait for the `: /~zod/tla-lus/<rev>/…` lines, not the prompt, or
  the next `-test` builds the OLD shard.
- **`scaffold-gate.sh` reports DRIFT on `evidence-counts.md` after any corpus
  change.** That is the gate doing its job: it rewrites the file, so RE-RUN it
  and expect PASS the second time.
- **Never splice a file positionally on a pattern that repeats in it.** I
  destroyed `lib/config.hoon`'s `.cfg` parser with a `?^ possible.a` splice
  that also matched the parser's `?: =(kw '_POSSIBLE')`. Recovery was
  `git show HEAD:… > file` plus re-applying the unit's edits with asserted
  anchors. Anchor on unique text; assert it.
- **On a mold change, grep the whole tree for its CONSTRUCTORS once.** Widening
  `le-state` broke three test shards' probe leaves, and I found them one at a
  time because I grepped the two files I already knew about.

## Corpus mechanisms worth knowing

`tools/gen-mc-tests.py` has three maps, all printed on every run:

- `SKIPS` — golden captured, arm withheld, reason printed. Currently
  `live-after-inv`, `gh1389-counting` (both R2.7.11a's).
- `APPROVED` — golden stays the PIN's, arm asserts the PORT's output. Currently
  `gh1389-loops`, `gh1389-guard`, `possible-never`, `periodic-fast`,
  `terse-subset`.
- `VARIES` — the pin's own answer is nondeterministic, so golden and port are
  both projected to verdict + header + counts (`live-witness-many`,
  `-nested-many`, `-rec`, `gh1389-violc`).

`opts.txt` in a case dir passes extra `tlc2.TLC` arguments (`-fp 0`, `-terse`,
`-seed`).

## What this session did

R2.7.6.0–.3, R2.7.7.0–.5 (all of R2.7.7), R2.7.8, R2.7.9, R2.7.10, and
R2.7.11 as a measurement. Rows closed: `semantic-graph`, `tlc-driver`,
`tlc-module-excluded`, `cfg-possible`, `cfg-internal-kw`. Owed went 6 → 4 while
three NEW rows were created and two of those closed.

**The pattern that kept repeating, and the reason the plan is worth
distrusting:** eight of these units found their own row's claim wrong —
`tlc-live-normalize`'s "the port does not expand" (shipped in R1.6.1),
`-terse` "unblocked by R2.7.2" (it needs lazy descriptors), `_POSSIBLE`'s
"the read side already exists" (named registers did not exist),
`-messagesAsErrors` "newly owed" (already implemented), `_PERIODIC` "inside the
search loop" (a wall-clock thread), R2.7.7.2's "validation before any state"
(it happens after exploration), and R2.7.11's "the fix is minimality". Open
every unit by measuring its row.
