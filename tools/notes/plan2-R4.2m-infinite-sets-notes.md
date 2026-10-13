# R4.2m: `Nat`/`Int`/`Seq` as values, and config overrides (2026-10-12)

**Status: DONE** (census below). The 18 census-r2 rows refused with
"unsupported StandardModule operator: Naturals!Nat / Integers!Int /
Sequences!Seq", or "non-enumerable set Seq(...)", had three causes:

1. **`N \in Nat \ {0}`** (12 Examples ASSUMEs) and nested infinite operands
   (`[P -> [P -> Nat]]`, `[age : Int]`). The flat lazy `sexp` forces every
   operand of `\`, `\cup`, `[D -> R]` and so on to a value, and `Nat` has no
   value form.
2. **Config overrides were never applied.** `Nat <- NatOverride`,
   `Seq <- LimitedSeq`, `Acceptor <- MCAcceptor` and `NumActors <- n` (123
   `<-` lines in the Examples configs) were validated (EC 2223-2226) and
   then ignored.
3. **An INSTANCE substitution by an infinite set** (`Values <- Int`) was
   evaluated eagerly, and failed.

## Fixes

- `lib/node-eval` `+memb-node`: `x \in S` is decided on S's structure, as
  tlc2's lazy values decide it.
  - `\`, `\cup` and `\cap` delegate to their operands.
  - `[D -> R]` compares the domain, then checks each value against R.
  - `[f : S, …]` checks each field; `SUBSET S` checks each element.
  - `Seq(R)` (the StandardModule's) checks each element of a sequence.
  - Anything else takes the existing descriptor path, so finite membership
    is unchanged.
- `+bi-subseteq`: when B has no lazy descriptor, stream A and decide each
  element with `+memb-node` (tlc2 `isSubsetEq` → `member`).
- `lib/check` `+apply-overrides`, used by the job (`+config-run`), the
  console (`+search-ctx-seed`) and the raw liveness path.
  - `lhs <- rhs` rebinds `lhs` to `rhs`'s definition.
  - `lhs <-[M] rhs` does so for a definition module `M` supplies.
  - `+apply-const` falls back to that definition for a CONSTANT with no
    value. A constant-level one is evaluated once by R4.P3's
    `+with-cdefs`.
  - An overridden `Nat`/`Seq` is no longer a descriptor (its origin is the
    MC module), so it enumerates.
- `+bind-substs`: a substitution with no value is bound by name (`psub`).
  `+by-name` lets a CONSTANT/VARIABLE reference, `+eval-domain` and
  `+memb-node` read it.
- **`$Label`** (found in the census: EWD840, EWD998 ×2). A labeled
  expression is its body in `+eval-builtin-rs`, `+solve`, `+psolve` and the
  liveness converter.

## Tests (mc pin goldens; mc 121 → 126)

- `inf-member-shapes`: `Nat \ {0}`, `Int \ Nat`, `[1..2 -> [1..2 -> Nat]]`,
  `[a : Int, b : Nat \ {0}]`, `Seq(Nat)`.
- `cfg-override-nat`: `Nat <- NatOverride` with `\E k \in Nat`, and a
  CONSTANT overridden by a definition.
- `cfg-override-seq`: `Seq <- LimitedSeq` enumerated in Init.
- `label-expr`: labels in an action and an invariant.
- `inst-subst-infinite`: `Values <- Int` through an INSTANCE, with
  membership and lazy `\subseteq`.
- `+memb-node` also expands a zero-arity user definition into its body
  (`Message == TokenMsg \cup BasicMsg`, EWD998Chan). A constant definition
  R4.P3 already evaluated answers from its cached value instead, so
  `x \in BigSetDef` is not recomputed per check.

## Census (the 18 rows plus 1 surfaced; `--wall 300`; `census-r42m.txt`)

| model | now | manifest |
|---|---|---|
| SyncTerminationDetection, EWD840 | success | agree (129, 302) |
| AsyncTerminationDetection | limited 300 s, all 4,097 states | 4097 |
| MCBakery, MCBoulanger, MCFindHighest, MCBinarySearch, MCLamportMutex, EWD998Chan | run, limited 300 s | |
| Chameneos, Disruptor ×3 | `$UnboundedChoose` | → R4.2u |
| YoYoAllGraphs, EWD998, EWD998Small | `MapThenFoldSet` (CommunityModules) | → R4.2b |
| TokenRing | ALIAS with a temporal PROPERTY | → R4.2i |
| EnvironmentController | `incomplete next state` | → R4.2p |
| MCQuicksort | `Attempted to apply function <<2>> to argument 2` where tlc2 succeeds: a NEW divergence | → R4.2ag |
