# R4.1b: the parse census, proof modules included (2026-10-11)

```text
Sub-unit: R4.1b (exit evidence: tools/examples.py --parse over parse.json)
Census:   desk/test-data/blackbox/parse-census.txt (373 rows, one per module)
Oracle:   the pinned SANY accepts all 373 (tier2/examples/sany)
```

## First pass (on the final R4.1 code): 367 of 373 agree

About 3.7 h of wall clock. The six that disagreed:

| module(s) | cause | fix |
|---|---|---|
| `MisraReachability/APParReach`, `MCParReach`, `ParReachProofs` (via `ParReach.tla` 235:17); `ewd840/EWD840_proof` (302:10) | **parser**: a fairness subject that is an instance member, `WF_R!vars(R!Next)`, `WF_TD!vars(…)`, was "Ill-structured fairness expression" | `lib/syntax` `+fairness-expr`: the subject is SANY's `ReducedExpression` → `NoOpExtension`, `(ident [(args)] !)* ident`, now parsed as a prefixed general id |
| `ewd998/EWD998_proof` (31 × EC 4271) | **semantic**: `ASSUME NEW op(_,_) PROVE … FoldFunction(op, …)`: a `NEW` operator declaration was bound at arity 0 | `lib/semantic` `+newsymb-name` returns the declaration's arity (`+us-arity`); both binding sites use it |
| `tcp/tcp_proof` (5,661 lines) | **performance**: the job's 600 s analysis limit | none yet: ACCEPTED in 310 s through a generator (no job overhead), and re-run through the runner with `--parse-secs 3600` |

All 57 proof modules otherwise agree.

## New tests

- sem cases (SemDump goldens, byte-exact): `fair-inst` (`WF_R!vars(…)`,
  `SF_R!vars(…)`), `fair-inst-param` (`WF_I(x)!vars(…)`), `new-opdecl`
  (`NEW op(_,_)` passed as an operator argument).
- **Withheld** sem case `inst-def-order`: the defs an INSTANCE imports enter
  the instancer's context in `java.util.Hashtable` order over the instancee's
  context (`Generator` → `Context.getByClass`), so SemDump lists `R!Next`
  before `R!vars`; the port lists declaration order. Only the dump observes
  it; no verdict moves. New tracker row R4.2ac.

## Runner

`tools/examples.py --parse-secs N` sets the per-module analysis time limit
(default 600 s).

## Front-end speed (a finding, not a fix)

The census times the whole `%analyze` per module, library modules
included. Most take 10–80 s; the slowest are proof modules: `tcp_proof`
(310 s outside the job, over 600 s inside it), `bcastByz` 237 s,
`EWD687a_proof` 221 s, `EWD998_proof` 209 s. SANY takes seconds. Analysis
runs once per check, so this does not touch model-checking throughput, but
it sets the latency of every `%parse`/`%analyze`/`%check` request. Proposed
as a new R4.P row at the next check-in.
