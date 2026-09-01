---- MODULE A ----
\* R2.7.13 measured the residue R2.7.2 left on `tlc-eval-node` (the FUNCTION
\* representation class) and found it larger than recorded. tlc2's rule is in
\* Tool.java's OPCODE_fc/nrfs/rfs: a function constructor evaluates every
\* domain, and `isFcnRcd` is true iff EVERY domain value `instanceof
\* Reducible`. `Reducible` has exactly TWO implementors -- IntervalValue and
\* SetEnumValue -- so any other domain class leaves a FcnLambdaValue.
\*
\* The same predicate governs the BINARY set operators: `\cup`/`\cap`/`\`
\* compute eagerly only when both operands are Reducible, else they build a
\* lazy SetCupValue / SetCapValue / SetDiffValue. R2.7.2 recorded them as
\* unconditionally SetEnumValue, which was true of every golden it had.
EXTENDS Integers
Rng  == 1..3
Prod == (1..2) \X (1..2)
Sub  == SUBSET (1..2)
Pred == {x \in Prod : TRUE}
Fns  == [(1..2) -> (1..2)]
Rcds == [a: 1..2]
\* binary operators: Reducible operands force, lazy operands do not
CupR == Rng \cup {4}
CupL == Prod \cup {<<9, 9>>}
CapL == Prod \cap Prod
DifL == Prod \ {<<1, 1>>}
UniL == UNION {Prod}
\* function classes, by domain class
FRng  == [i \in Rng |-> i * 10]
FEnum == [x \in {1, 2, 3} |-> x]
FPred == [x \in Pred |-> 1]
FProd == [<<i, j>> \in Prod |-> i * 10 + j]
FSub  == [x \in Sub |-> 1]
FFns  == [x \in Fns |-> 1]
FRcds == [x \in Rcds |-> 1]
FCupR == [x \in CupR |-> x]
FCupL == [x \in CupL |-> 1]
====
