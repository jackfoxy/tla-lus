# R4.2af — `processConfigProps` unrolling and argument inlining (2026-10-17)

Measured at the pin (`SPECIFICATION Spec`, `x` counts 0..3):

| PROPERTY | pin | port before |
|---|---|---|
| `\A i \in {1, 2} : [](x < i + 1)` | `Invariant line 7, col 24 to line 7, col 36 of module spec is violated.`, 3 states (safety stop) | `Temporal property P was violated.`, 4 states |
| `\A i \in {2, 5} : <>(x = i)` | `Temporal property Q was violated.` | same |
| `\A i \in {1, 2} : x # i - 1` | implied init, `Property line 9 ... is violated by the initial state` | (now covered) |
| `\A i \in {1, 2} : [][x' # i + 1]_x` | `Action property line 10, col 24 ... is violated.` | (now covered) |
| `Check(2, 3)`, `Check(k, m) == [](x < k) /\ <>(x = m)` | `Invariant line 7, col 16 to line 7, col 24 ...`, 3 states | whole property, temporal |
| `Prop == Live`, `Live == <>(x = 3)` | `Temporal property Prop was violated.` | `Temporal property Live` (a defect since R4.2n) |
| `Both == Live /\ <>(x = 7)` | `Temporal property Both was violated.` | `Temporal properties Live and line 9 ...` |

Port (`lib/check`):
- `+const-forall`/`+rebound`: a part `\A i \in S : P` over constant-level
  domains is binned on P's shape and rebuilt around the binned form, named by
  P's location. Every element part tlc2 creates carries that same name and
  bin, so one quantified part is observationally identical. A temporal one
  stays whole.
- `+prop-parts` inlines a NON-recursive operator applied to CONSTANT-level
  arguments outside any substitution, binding the formals through a
  substitution wrapper (`+bind-substs`, lazy as `getOpContext`). Not with a
  state-level argument: the body's levels assume constant formals, so a
  temporal leaf would look constant (`Check(x, 2)` stays whole -- residue).
- Temporal parts carry the configured PROPERTY name (`i.props`).
- parts carry their module (`mo`) for the location names.

Tests: mc `forall-unroll-{inv,temporal,init,action}`,
`param-inline-{inv,live}`, `temporal-name-{def,conj}` (pin goldens).
