# R4.2v + R4.2u: config scope (overrides, definition values) (2026-10-12)

**Status: DONE as below.** R4.2v ("identifiers not visible to the
evaluator", 29 rows) and R4.2u ("unbounded CHOOSE", 10 rows) shared one
root: the configuration's ways of rebinding a name were parsed and
validated but never reached the evaluator.

## Fixes

- **`lhs <- rhs` overrides** (R4.2m, `+apply-overrides`); **`lhs <- C`
  where C is a CONSTANT with a value** (`Leader <- L`, EWD687a):
  `+override-consts`.
- **A config value for a DEFINITION** (`Faded = Faded`, `None = None`,
  `NULL = NULL`). tlc2 replaces the definition with the value, which is
  exactly what keeps `Faded == CHOOSE c : c \notin Color`, an unbounded
  CHOOSE tlc2 refuses to evaluate, from ever being evaluated. The value was
  bound in `vals` and never read: `+eval-user` now reads it first for a
  zero-arity reference. This is R4.2u's cause: tlc2 refuses unbounded
  CHOOSE too (`Tool.java` OPCODE_uc), and the Examples avoid it this way.
- **Module-scoped values** (`NoBlock = [Nano]NoBlockVal`, NanoBlockchain):
  `+mod-const-vals`. Every definition module M supplies under that name
  takes the value, including an instance member `N!NoBlock`.
- **Instance members keep their module as origin** (`lib/semantic`
  `g-instance`; `+stamp-origin` only fills a missing origin). The
  StandardModule override registry and descriptors are looked up by the
  operator's base name (`+bnm`).
  - Before this, any `INSTANCE` of a standard module evaluated its vendored
    dummy bodies: FiniteSets' `Cardinality` is
    `CS[T \ {CHOOSE x : x \in T}]`, an unbounded CHOOSE (Disruptor's
    RingBuffer, `LOCAL INSTANCE FiniteSets`).
  - Nested-instance members keep their own module.

## Tests (mc pin goldens; mc 126 → 128)

- `cfg-def-value`: `Faded = Faded` over an unbounded CHOOSE, and
  `Leader <- L`.
- `inst-std-local`: `Cardinality` through an instanced module's
  `LOCAL INSTANCE FiniteSets`.

## Census

R4.2v's 29 rows (`census-r42v.txt`):
- now agree: ElevatorSafetySmall, MCConsensus, kvstore, MCtcp;
- match their expected safety failure: MCDieHarder, MCDieHardest,
  MC_spanning;
- run, limited at 300 s: MultiPaxos_MC_small, MCVoting,
  SingleLaneBridge MC (3,605 = manifest);
- the rest moved on.

After the definition-value, origin and module-value fixes
(`census-r42u.txt`, `census-rerun3.txt`):
- Chameneos runs (34,358 of 34,534 at 300 s).
- NanoBlockchain → maxSetSize (R4.2i); MCPaxos → `nullODN`;
  MCPaxosSmall/Tiny → `Nat` in a value position; Disruptor ×3 → `Int` in
  a value position (both → R4.2m residue).
- EWD687a_anim → ALIAS in simulation (R4.2i); MCEWD687a →
  `$Local:G!SeqOf` (a LOCAL member of an instance inside a LET; R4.2v
  residue).
- LeastCircularSubstring ×2: `Nat <- [ZSequences]ZSeqNat` overrides `Nat`
  only INSIDE module ZSequences. The flat operator map cannot scope that
  (R4.2v residue).
- CommunityModules / Java-backed operators (`Xor`, `Max`, `And`,
  `Rational`, `MapThenFoldSet`) → R4.2b; `PrintT` → R4.2a;
  `$OpArg` → R4.2o.
