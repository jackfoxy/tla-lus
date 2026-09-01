# R2.7.12 — the violated-property NAME, and what the row got wrong about it

```text
Sub-unit: R2.7.12
Row: tlc-live-diagnostics  (partial -> parity)
Row's claim: "the reported name comes from the FIRST PROPERTY rather than from
  the property that was actually violated ... because the `oos` carries no
  source-property name"
Measurement: the SYMPTOM is right and the CAUSE is wrong. tlc2's `oos` carries
  no source-property name either. The name is recomputed POST HOC from the
  finished counter-example, so nothing had to be threaded through the
  decomposition at all.
```

## What tlc2 actually does

`LiveWorker.printTrace` builds the whole lasso first. Then:

```java
final Set<String> violated = Liveness.findViolatedProperties(tool, states, cyclePos);
MP.printError(EC.TLC_TEMPORAL_PROPERTY_VIOLATED, violated.toArray(String[]::new));
```

`findViolatedProperties` loops over `tool.getImpliedTemporals()`, runs
`astToLive` on each one, and asks `LiveExprNode.evalOnLasso` whether THIS
behaviour satisfies it. The ones that do not are named. It is a direct
recursive evaluator over the trace — not the tableau, not the product.

Two consequences, and the row named only the first.

## Clause 1 — the name

Probe (`mc` case `prop-attrib`), first property HOLDS on the counter-example:

```tla
P1 == []<>(x < 9)     \* holds
P2 == <>(x = 3)       \* violated
```

pin: `Error: Temporal property P2 was violated.`
port: `Error: Temporal property P1 was violated.` — the head of the list.

The trace, the counts and the closer were already byte-identical. Only the
name differed.

## Clause 2 — the plural form, which the row did not name

Attribution returns a SET, and `MP.java`'s template has three branches:

```text
1 name : Temporal property P1 was violated.
2 names: Temporal properties P1 and P2 were violated.
3+     : Temporal properties P1, P2, and P3 were violated.
```

The three-name form is not a generalization of the two-name one — the
separator before the last name changes from `" and "` to `", and "`. Pinned as
`prop-plural` and `prop-plural3`: a spec whose only behaviour stutters at
`x = 0` with `P1 == <>(x = 1)`, `P2 == <>(x = 2)` (and `P3 == <>(x = 3)`)
fails every property on the same lasso.

The port had no plural branch at all.

## The change

`desk/lib/liveness.hoon`:

- `+eval-on-lasso` — the LN* evaluator over a finished trace. `%state` and
  `%enabled` at `sts[pos]`; `%act` and `%next` take `sts[cyc]` as the successor
  of the last state; `%all`/`%even` walk `min(pos, cyc)..len-1`. That last one
  is tlc2's two loops (`pos..cyc-1` then `cyc..len-1`) merged: their union is
  `pos..len-1` when `pos < cyc` and `cyc..len-1` otherwise, which is
  `min(pos, cyc)..len-1` in both cases. An unevaluable leaf BAILS, keeping
  R2.7.6.3's invariant.

`desk/lib/check.hoon`:

- `+implied-temporals` — `Tool.getImpliedTemporals()`: every PROPERTY that is
  not box-state, not level<=1, not `[][A]_v`, with its body, in declaration
  order. Carried on `sctx` as `props`.
- `+violated-props` — `findViolatedProperties`. `cyclePos` is `loop - 1`
  (0-based), for a stuttering closer and a back-to-state one alike. A property
  whose live-expression fails to build is SKIPPED, as tlc2's catch does.
- `+violated-header` — MP's three branches, falling back to `pname` when
  attribution comes back empty.

`desk/lib/job.hoon`: `props` on the `%live` kont, so the sliced kernel report
attributes the same way; the typed `%property` result takes the first
attributed name so the wire and the console agree.

## What the same probe found and this unit did NOT fix

The first probe was `P1 == [](x < 9)` (box-state) followed by
`P2 == <>(x = 3)`. The pin reports `P2`. **The port completes clean.**

`SpecProcessor.processConfigProps` routes EVERY property — box-state to the
invariant vector, level-1 to the implied inits, `[][A]_v` to the implied
actions, the rest to `impliedTemporals` — so one run can send different
properties down different engines. The port decides the route from `pp`, the
head of the list, in `+check`, in `+search-ctx` and in `job.hoon`'s
`do-config`. A box-state property first means the safety engine runs and the
temporal one is never checked.

That is a MISSED VIOLATION, and it belongs to `tlc-safety-assume`, which
claimed this routing at R1.8.1.1. That row is **demoted `parity` -> `partial`**
and the case is frozen as `prop-box-then-live` with its arm withheld.

**No corpus case could have caught it**: every multi-PROPERTY case in the
corpus has all its properties on the same route, so the head was always
representative. R1.3.8's `\X`, R2.7.5's closer, R2.7.11a's box-free split —
this is the fourth instance of the same shape.

## Evidence

- `mc`: 88 cases (four new, one withheld).
- `mc`, `liveness-lasso`, `liveness-message`, `liveness-verdict`, `job`,
  `trace`, `tier2`, `tier2-sub`, `sim-live`, `diagnostics`: `ok=%.y`.

## Two notes for the next unit

- **A dojo `=face -build-file` snapshot does not follow `|commit`.** Three
  probe runs in a row reported the OLD behaviour after the fix had already
  landed and compiled; the face was bound once, at an earlier revision.
  Rebind after every commit, or run the assertion through `-test`.
- The row's stated cause (*"the `oos` carries no source-property name"*) is
  the ninth plan claim measured wrong. It was not a guess about the port — it
  was a guess about tlc2, made without reading `printTrace` to the end.
