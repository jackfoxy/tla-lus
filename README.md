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
=req  :*  [%check [| ~ [%exhaustive &]]]
          [%inline 'Counter' (malt ~[['Counter' spec]]) `'INIT Init\0aNEXT Next\0aINVARIANT Inv\0a']
          default-limits:job-lib
          |
      ==
:tla-lus &tla-lus-action [%submit ~.counter req]
.^((unit job) %gx /=tla-lus=/job/counter)
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

Built and validated incrementally against the pinned oracle. See
[port-map.md](desk/doc/port-map.md) for exactly which units and features are
live; deferred behaviors are documented in
[compatibility.md](desk/doc/compatibility.md) and reject or fall back rather
than crash.

## License

The Java TLA+ sources used to generate test fixtures are MIT-licensed
(`tlaplus`, `tlaplus-Examples`, `vscode-tlaplus`); their notices are retained
with the vendored `StandardModules` and oracle fixtures.
