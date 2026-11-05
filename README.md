# tla-lus

A native, **headless** [TLA+](https://lamport.azurewebsites.net/tla/tla.html)
toolchain for Urbit — PlusCal translation, SANY-compatible parsing / semantic
analysis / level checking, and TLC-compatible model checking, liveness, and
simulation — running as a Gall agent with **no GUI and no Java at runtime**.

Every stage is a pure, bounded, resumable Gall computation, validated
output-for-output against the Java `tla2tools` at a pinned commit. The Java jar
is used only to generate the differential test goldens; it is never shipped or
called by the agent.

## Quick start

```
::  install and run on a ship that has the desk
|install our %tla-lus
|start %tla-lus

::  model-check an inline spec
=spec '''
---- MODULE Counter ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x' = (x + 1) % 4
Inv  == x < 4
====
'''
::  check-opts is [translate view difftrace continue cfg coverage
::  postconditions mode]; request is [op src limits write promote]
=req  :*  [%check [| | | | ~ | ~ [%exhaustive & 0]]]
          [%inline 'Counter' (malt ~[['Counter' spec]]) `'INIT Init\0aNEXT Next\0aINVARIANT Inv\0a']
          default-limits:job-lib
          ~
          ~
      ==
:tla-lus &tla-lus-action [%submit ~.counter req]
.^((unit job) %gx /=tla-lus=/job/counter/noun)
```

## Documentation (`desk/doc/`)

- [users-guide.md](desk/doc/users-guide.md) — install, workflows, model
  checking, simulation, limits, traces, troubleshooting.
- [api.md](desk/doc/api.md) — marks, molds, actions, subscriptions, scries,
  updates, results, and Dojo examples.
- [architecture.md](desk/doc/architecture.md) — the pure pipeline, the Gall
  scheduler, persistence/recovery, and trust boundaries.
- [tla-bnf.md](desk/doc/tla-bnf.md) — the complete checked TLA+ grammar.
- [compatibility.md](desk/doc/compatibility.md) — pinned upstream commit,
  supported features, and deliberate differences.
- [testing.md](desk/doc/testing.md) — the differential validation tiers.
- [port-map.md](desk/doc/port-map.md) — Java-to-Hoon traceability and test
  ownership, unit by unit.

## Testing

```
python3 tools/validate.py --check      ::  regenerate + verify goldens vs the pinned oracle
-test /=tla-lus=/tests ~               ::  the Hoon differential + property suite (on the ship)
```

## Status

The parity ledger was **closed at R3 — 134 rows, none owed (2026-09-05)**, when
`tools/release-gate.sh` passed every clause and `tools/r3-acceptance.py
--suite-log` reported **R3 ACCEPTED** on 5/5. **R4** (the tlaplus-Examples
corpus, PlusCal excluded) re-opened three rows on measurement and closed
them again; the ledger stands at **140 rows, none owed**, and R4's clauses
are measured clause by clause in
[testing.md](desk/doc/testing.md) (§*Examples coverage at R4*), pending the
acceptance run (R4.5.2–R4.5.3). See
[parity-manifest.md](desk/doc/parity-manifest.md) for the ledger and
[port-map.md](desk/doc/port-map.md) for which units own what. Everything
unsupported is unsupported by decision and is a **typed rejection naming what
is missing** — never a silent fallback or a crash; PlusCal translation is the
headline case (`excluded`). See
[compatibility.md](desk/doc/compatibility.md).

## License

The Java TLA+ sources used to generate test fixtures are MIT-licensed
(`tlaplus`, `tlaplus-Examples`, `vscode-tlaplus`); their notices are retained
with the vendored `StandardModules` and oracle fixtures.

The other upstreams the Examples work uses are tlapm's library
(BSD-2-Clause), tlauc (MIT), CommunityModules (MIT) and Apalache
(Apache-2.0, with its `NOTICE`). Their license texts, verbatim from each
pinned commit, are in [`licenses/`](licenses/), and a copy goes beside every
library staged onto the `%tla-ex` desk.
