# R2.7.8 — an instanced member referencing a sibling

R2.3.5 found this and refused it by name; R2.7.8 closes it.

## The gap

`+g-instance` imports each definition of an instanced module as `I!Name`, with
its body wrapped in `$SubstIn` over the WITH substitutions. The body is the
INNER module's, so

```tla
SpecI == InitI /\ [][NextI]_v
```

carries a **bare** `InitI` — while the root defs map holds only `I!InitI`. The
reference resolved to nothing, and `+decompose-spec` refused it rather than
dropping it (dropping produced *"the SPECIFICATION has no initial predicate"*,
true of nothing the caller wrote).

**tlc2 has no lookup to get wrong**: `SubstInNode`'s body LINKS to the
sibling's `OpDefNode`. The port's IR names its references, so the faithful
analogue is to name the entry that exists.

## The fix, and the sub-case that decided its shape

`+qualify-siblings` rewrites a member's body so a reference to a sibling names
its imported entry. Only names in the sibling map are rewritten: a formal
parameter, a substituted VARIABLE, a CONSTANT and a standard operator all keep
theirs. The map is built in a FIRST PASS, since a member may reference a
sibling defined later in the module.

Then the LOCAL case, measured at the pin before deciding: an inner
`LOCAL Bound == k` referenced by an imported member **runs fine** — a local
definition is local to the MODULE, visible to its siblings, and merely not
exported. The port skipped locals entirely, so those references still resolved
to nothing.

Importing them as `I!Bound` would have been wrong in the other direction: the
pin rejects `I!Bound` written by a caller. They are imported under a RESERVED
name instead — `$Local:I!Bound` — which no source can produce, since `$` cannot
begin a TLA+ identifier. That is the trick `$SubstIn:` and `$Sel` already use.
The def also stays `local`, so it exports nothing.

## Evidence

Two new `mc` cases, both **byte-exact** against the pin (verdict, 4 generated,
3 distinct, depth 3): `inst-sibling` (the shape R2.3.5 found) and
`inst-sibling-local` (the sub-case above). `tests/lib/spec-decomp`'s
`test-instance-sibling-reference-refused-by-name` became
`test-instance-sibling-reference-runs`, asserting the pin's output rather than
the refusal.

Five front-end shards green: mc, spec-decomp, sem, modres, lvl.

## What is left on `semantic-graph`

Nothing from this residue. The row's remaining text is R1's inventory of what
the typed IR covers, not owed work.
