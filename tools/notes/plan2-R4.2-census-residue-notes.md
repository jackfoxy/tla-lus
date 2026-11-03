# R4.2 census residue (2026-10-14 .. 16)

Rerun of the 47 models whose latest census row was an error (120 s wall,
`logs/census-r42-residue.txt`), then fixes, each probed on its model
(`logs/census-r42-fix*.txt`).

## Fixed

| model | cause | fix | now |
|---|---|---|---|
| echo/MCEcho | `trcl[n \in Nat]` (LET recursive fcn over Nat) enumerated | `+recfcn-infinite`/`+apply-recfcn`: fixpoint over 0..a | success 116/75/16 = manifest |
| Paxos/MCPaxos (+ TuringAward ×2) | `Ballot <-[Voting] MCBallot` missed `V!Ballot` | `+apply-overrides`: module-scoped override matches the unqualified name + origin | MCPaxos success 82/25/9 = manifest |
| Disruptor ×3 | `UNION {[D -> Int \cup {NULL}]}` membership forced `Int` | `+memb-node`: `UNION {S1..Sn}` lazily | runs (limited, 35 st/s → R4.3) |
| NanoBlockchain ×3 | (1) `N!Ledger` membership forced `[Hash -> SignedBlock \cup {NoBlock}]`; (2) LET `block` captured by `\E block` | (1) `+memb-node` looks through `$SubstIn`; (2) `+with-lets`: a LET def shadows `vals`/`psub` | NanoSmall reaches 3003 distinct = manifest (limited, 15 st/s → R4.3) |
| KeyValueStore/MCKVsnap | (1) `$OpArg` sibling `CT_SI` not qualified in `CC == INSTANCE`; (2) built-in `\intersect` as an operator argument | (1) `+qualify-siblings` rewrites the `$OpArg`'s ubound; (2) `+builtin-def` | runs (limited) |
| dag-consensus/TLCSailfish ×2 | `Max` via `INSTANCE Sailfish` → `INSTANCE BlockDag` → `EXTENDS Utils` | `+inst-ext-defs`: a nested instance's EXTENDS closure in `nds`, plain names (as R4.2o's `+nested-defs`) | runs (too slow → R4.3) |
| CheckpointCoordination ×2 | `Connected(Leader, p)` binds `src ↦ Leader` by name; inner `ConnectedOneWay(src, dst)` bound `src ↦` node `src` (self) | solver `bind-params`: bind the DEREFERENCED node; every binding shadows the other table | runs (limited, 3 st/s → R4.3) |
| ReadersWriters/MC | `CASE p -> Read(a) [] ...` in an action was filtered as a boolean (primed vars unassigned) | `+solve-case` (OPCODE_case in getInitStates/getNextStates) | safety 59674/21527/13 = manifest; liveness phase limited (R4.3) |
| RealTime/MCRealTimeHourClock | `[NowNext]_now /\ [HCnxt]_hr` as a next-state relation | solver: `[A]_e` is A's successors then UNCHANGED e (OPCODE_sa); eval: `+eval-act-sub` for `[A]_e`/`<<A>>_e` | liveness failure 696/216/2 = pin |
| ewd687a/MCEWD687a | `$Local:G!SeqOf`: a LET-instance's nested members were dropped | `+let-insts` carries `nds` | runs (limited, 1.3 st/s → R4.3) |
| LeastCircularSubstring ×2 | `Nat <- [ZSequences]ZSeqNat`: ZSequences INHERITS Nat | scoped override of an inherited lhs applies to its one definition (tlc2 sets it on the shared body) | Small 8681/8554/95 = manifest |
| braf | `RAF == INSTANCE RandomAccessFile WITH file_content <- LogicalFileContent`; the root's `LogicalFileContent` names the root's own `file_content`, which resolved through the substitution back to itself | `+outer-of`: a call-by-name entry's expression is evaluated without its own name's binding | no error; all PROPERTYs run (limited → R4.3) |
| CoffeeCan ×2 | `{c \in Can : ...}`, `Can` 1,002,001 records, forced | `+eval-domain` expands a zero-arity user definition and a `$SubstIn` lazily | no error; 501,500 initial states in one slice (R4.3) |

Also: `r.f` on a record without `f` now has tlc2's wording (`Attempted to
select nonexistent field "f" from the record\n<r>`, minus the location line
tlc2 appends); an unresolved operator argument names itself.

## Tests

mc (pin goldens): `memb-union-int`, `let-shadow-bound`, `oparg-builtin`,
`cbn-swap-var`, `recfcn-nat`, `case-action`, `square-act-next`,
`domain-lazy-def`. job: `test-mod-override-inherited` (6/3/1), `test-subst-names-own-var` (5/5/5), `test-instance-extends-chain` (2/1/1),
`test-mod-override-through-instance` (4/3/2),
`test-oparg-sibling-through-instance` (3/3/3), `test-memb-through-substin`
(385/64/7). 20 shards green (job 147, mc 158, sem 120, tier2 13, …).

## Still open (from the rerun)

- ALIAS with a temporal PROPERTY / in simulation (R4.2i): TokenRing, Huang,
  EWD687a_anim, EWD840_anim
- EWD998ChanTrace: approved refusal (Json readers)
- R4.3 (perf): every "limited" row above
