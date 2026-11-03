# R4.2aa: constant definitions that draw (2026-10-13)

**Status: code done; mc 138, job 131, safety-gen 10 green; census below.**

## The pin (measured, `-workers 1 -fp 0`)

tlc2's `SpecProcessor.processConstantDefns` runs on the main thread before
the checker exists, so `RandomEnumerableValues` hands it a
`DefaultRandom(seed)`. Every arity-0 constant-level definition is evaluated
once, the drawing ones included, and the stream they leave is the one the
ASSUMEs and then the initial-state solve continue.

Probes (scratch specs, seeds 0, 1, 7, 12345, against a Python
`java.util.Random`):

| probe | pin |
|---|---|
| `B == RE(0..99)` declared before `A == RE(0..99)`; `Init == x = RE(0..99)` | B = 1st draw, A = 2nd, init = 3rd |
| `ASSUME RE(0..99) >= 0` after the definitions | the ASSUME takes the draw after the definitions'; Init the next |
| `EXTENDS Lib` (`L == RE(..)`), then `E`, `B`, `D == B + 1000 * RE(..)` | L, E, B, D's own draw (B reused), then Init |
| `CONSTANT C <- R`, `R == RE(0..99)`, `Next == x' = C` | R drawn once at startup (`processConstantDefns` evaluates the substitution's body); `C` re-evaluates R's body per reference: 6 distinct states (tlc2's own comment, issue #648) |
| the same spec under `-simulate` and `-dfid` | Init continues the startup stream in both |
| `-simulate`, Next draws | the walk does NOT continue it: a worker thread starts its own `DefaultRandom(seed)` (`next` draws identical with and without a startup draw) |

Order: the module table (dependency first, so an EXTENDed module's
definitions come first); per module, the constant substitutions
(`getConstantDecls`), then `getOpDefs()` in declaration order. A definition
is evaluated by the first module that reaches it. A parametrized instance's
definitions are skipped (`processConstantDefns()` is false for it).

## Port

- `+startup-draws:node-eval`: walks an ordered definition list, evaluates
  each qualifying definition (`+with-cdefs`'s test) with the threaded RNG,
  and keeps the ones that DREW as values in `vals` (the slot a config value
  for a definition uses, R4.2u). A definition that draws and then fails
  stays lazy, its draws spent. Instance members (`I!R`) and names the
  config already valued are skipped.
- `+startup-order:check`: `imports` (dependency-first), the root's
  `C <- R` substitutions in CONSTANT order, then the root's definitions.
- `+assume-es:check` advances the stream over the ASSUMEs (first false or
  failing one ends it). `+check-assumes` takes the start state (`ses` on
  `sctx`), so its verdicts use the same draws.
- Both entry points (`+search-ctx-seed`, the kernel's `+do-config` half)
  start the initial-state solve from that state. `+may-draw` (a drawing
  operator named in a definition or an ASSUME) gates the two pre-passes;
  with no draw the solve starts from the seed as before.
- The simulate walk and the per-state BFS reseed are unchanged.

Residue: a substitution for a constant that an EXTENDed module declares is
ordered with the root's; tlc2 orders it with its module. It differs only
when that module also draws at startup.

## Found on SpanTreeRandom: draws inside set maps and set constructors

SpanTreeRandom (`Edges == UNION { {{n, m} : m \in RandomElement(SUBSET
(Nodes \ {n}))} : n \in Nodes }`) ran to 1 state where the pin finds
79,550: `Edges` came out EMPTY. The binders are below the carrier boundary
(R2.7.4.1b): `+eval-setofall`'s streaming gate evaluates each element with a
fresh run state, so every element drew from the same RNG state, and
`UNION`'s operand went through `+eval-domain`, which never threads it.
Measured at the pin: `{RandomElement(SUBSET ({1,2,3} \ {n})) : n \in
{1, 2}}` is `{{}, {3}}` at seed 0; the port gave `{{}}`.

- `+body-draws` / `+sem-draws`: does a node name a drawing operator,
  directly or through the definitions it reaches (`+reach-names`)?
- `+eval-image-rs`: a one-binder set map or function constructor that
  draws is evaluated eagerly (as tlc2's OPCODE_soa / fcn constructor are),
  the domain first, then the body per element in enumeration order, with
  the run state threaded. Below the boundary otherwise (unchanged).
- `+ctor-args-rs`: a set constructor (`UNION`, `SUBSET`, `\cup`, `\cap`,
  `\`, `\X`, `[S -> T]`) whose operands draw evaluates them on the stream,
  in order, then builds the descriptor from their values.

With integer nodes `Edges` now equals the pin's exactly (11 edges).
With model values (`n1`..`n6`) the drawn subsets also match.

Then the run still had 1 state: `\A e \in Edges : e \in Edges` was FALSE.
Structural membership (`+memb-node`, R4.2m) expands a zero-arity
definition's BODY, and it consulted `cdefs` but not `vals`, so `m \in
Nbrs(n)` re-drew `Edges`. It now answers from `vals` too. SpanTreeRandom
over 4 nodes (safety only) is 584 / 119 / 4, equal to the pin: mc
`rnd-spantree4`.


- mc `rnd-startup-order` (seed 12345): B, A, D's draw, the ASSUME's draw,
  then Init; the trace shows `x = 23`, `y = <<93, 36, 83036, 129>>`.
- mc `rnd-const-subst`: `C <- R` over ONE variable (`Init == x = 100 + R`,
  `Next == x' = IF C = R THEN 200 ELSE C`): 4 distinct states, x = 103, 7,
  6, 5 (R drawn once; C redraws per state). A first version with two
  variables differed from the pin through the per-state reseed, which
  reads FP64's byte order: that is the approved `tlc-var-order` difference
  (R4.2t), so the case keeps one variable.
- mc `rnd-setmap-draws` (`{{}, {3}}`, `<<6, 5, 6>>` at seed 0) and
  `rnd-union-draws` (SpanTreeRandom's `Edges` over `1..6`).
- Every other mc golden regenerated byte-identical.
