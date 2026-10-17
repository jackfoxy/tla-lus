# R4.2b — CommunityModules operators (2026-10-17)

## Inventory

The Examples reach these CommunityModules modules (closure of every
manifest model): SequencesExt, Functions, FiniteSetsExt, Folds, BagsExt,
Bitwise, DyadicRationals, IOUtils, CSV, Json, SVG, Statistics, VectorClocks,
Graphs, UndirectedGraphs, Relation. The pin is tla2tools + the deps jar
(`/mnt/mars/gitrepos/r4-deps/CommunityModules-deps.jar`, built 2026-04-22),
whose override classes match CommunityModules commit `a20cc8eb2` (the repo
HEAD is newer: it adds Graphs/UndirectedGraphs overrides the jar lacks).

Jar overrides in reached modules (beyond IOUtils/CSV/Json, R4.2c/f/h):
SequencesExt ×17, Functions ×4, FiniteSetsExt ×3, BagsExt!FoldBag,
Bitwise ×5, DyadicRationals!Reduce, IOUtils!atoi, SVG ×4,
Statistics!ChiSquare, VectorClocks!CausalOrder.

## Measured (tools/gen-cm-tests.py)

`ModuleOpDump` with the deps jar on the classpath (BINDINGS confirm
`override:MethodValue`), 10 cases, 74 definitions. Against the port's TLA+
bodies the first run DIVERGED in 8 of 10 cases:

- fold order: FoldFunction/FoldSeq/FoldFunctionOnSet (body: CHOOSE-driven
  MapThenFoldSet, reverse order), FoldSet, FoldLeft/FoldLeftDomain (body
  failed on a domain lookup);
- value class: SetToSeq (FcnRcdValue vs TupleValue), kSubset (SetPredValue
  vs KSubsetValue/SubsetValue);
- IsInjective of a record: the override raises EC 2283;
- atoi: the body is an unbounded CHOOSE over Int;
- FoldBag: the body enumerates Nat;
- SVGElemToString, NodeOfRingNetwork, ChiSquare: dummy bodies;
- CausalOrder: CHOOSE over permutations (and FcnRcdValue).

Bitwise, DyadicRationals (up to record field order) and IOUtils already
agreed.

## Port

- `lib/stdops`: 14 pure registry rows (`cm-*`), 3 refused by name
  (`cm-refused`); `ordinal` gains "fourth".
- `lib/node-eval`: `+eval-cm-op` (16 operator-argument overrides, node-op
  tags), `+apply-op` (an operator argument with a Java override, e.g. a bare
  `+`, applies through it), `+cm-op`.
- `lib/check`: `%k-subset` renders `KSubsetValue`; `+project-defs-with`.

## Approved differences (ledger `tlc-module-community`)

Refused by name: SVG!NodeOfRingNetwork (Math.cos/sin doubles truncated to
int), SVG!NodesOfDirectedMultiGraph (jungrapht layout), Statistics!ChiSquare
(Apache Commons Math), VectorClocks!CausalOrder (HashMap iteration order).
SVGElemToString's attribute order and Reduce's record field order follow the
approved string order (`tlc-value-order`).

## Tests

`tests/lib/cmops` (generated, 63 compared definitions, 11 skipped with
reasons); `tests/lib/stdops` `test-cm-refusals`; registry 54 -> 71.
Census: MCDieHardest, MCDistributedReplicatedLog, MCReplicatedLog,
SDP_Attack_Spec, MCYoYoNoPruning, MCYoYoPruning, MCtcp, Hanoi_anim all
unchanged (= manifest where it has counts).
