# R4.2au — ElevatorSafetySmall's transition graph (2026-11-03)

Found by R4.Q9. ElevatorSafetySmall had counts equal to the pin
(4,122 distinct / 14,296 generated) but depth 32 against the pin's 36. It
had been that way since at least R4.2v.

## Localizing

- tlc2's own state graph (`-dump dot`), with a BFS from its 64 initial
  states, gives depth 36. So the pin is right, and the port's graph has
  shorter paths.
- A ship-only generator (`tla-zod-tools/zgraph.hoon`) dumped the port's
  graph: every reachable state (`+render-states`) and its successor edges
  from `+next-states`, through the console path's `+search-ctx`. A Python
  differ (`scratchpad/gdiff.py`) parses both renderings into canonical
  values, with sets sorted and records and functions as sorted maps, so the
  approved string/model-value order difference cannot interfere. The result:
  the same 4,122 states, and successors that differ at **26 states**, always
  one extra port edge.
- Every one of them is the same shape. A call is pending, one car is
  approaching on that floor, and another is stationary there.
  `DispatchElevator`'s
  `CHOOSE closest \in stationary \cup approaching : (nearest)` ties at
  distance 0. tlc2 picks the approaching car, so nothing changes; the port
  picked the stationary one and dispatched it.

## Cause and fix

tlc2's CHOOSE normalizes its domain (`inVal.normalize()`, then
`elements(Ordering.NORMALIZED)`; Tool.java OPCODE_bc). The port's
`+choose-over` streamed the domain in construction order. That is already
normalized for a set, an interval, `SUBSET`, `\X`, `[S -> T]`, `\cap` and
`\` (first-operand order), but a `\cup` streams operand by operand. Pin vs
port on
`<<CHOOSE y \in {3} \cup {1} : TRUE, ..UNION.., ..\.., ..filter on \cup..,
CHOOSE y \in (2..3) \cup {1} : TRUE>>`: `<<1, 2, 6, 3, 1>>` vs
`<<3, 2, 6, 3, 2>>`.

- `+choose-over:v` forces and normalizes a `%cup` domain.
- `+eval-quant-rs` (the drawing/printing path) normalizes CHOOSE's
  drained domain too.

Record field order is not touched: tlc2 orders fields by intern order,
which is the approved `tlc-value-order` difference.

## Evidence

- The port's re-dumped graph equals the pin's at every state, BFS depth 36.
  ElevatorSafetySmall through the agent: success 14,296 / 4,122 / **36** = pin.
- Arms `test-choose-normalizes-cup` (node-eval, the five-case pin) and
  `test-choose-normalizes-cup-printing` (job, pin 2/1/1; bites with the
  drawing-path normalization removed).
- `compatibility.md`: a paragraph under the string-order difference saying
  that normalized-order CHOOSE is not part of it.
- Regression 65/65 (`logs/r42au-regress1.txt`); validate, scaffold-gate,
  test-examples PASS. Targeted census `logs/census-r42au.txt` (the 16
  standard rows and the four other MultiCarElevator rows): every count
  unchanged, except ElevatorLivenessMedium, whose depth is now 36 (= pin).
  It is still `limited time` in its liveness phase.
