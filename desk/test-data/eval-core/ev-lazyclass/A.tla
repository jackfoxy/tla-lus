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
\* R2.7.16 measured the rest of the rule; every line below pins one branch
\* of it that the R2.7.13 set above could not distinguish.
Emp  == {}
EmpI == 1..0
Lazy == UNION (SUBSET (1..2))
\* `\cup` with an EMPTY Reducible operand returns the OTHER OPERAND ITSELF
\* (`if (size == 0) return set;`), so the result keeps that operand's class
CupEmpL  == Emp \cup Prod
CupEmpR  == Prod \cup Emp
CupEmpIL == EmpI \cup Prod
\* the three binary operators do NOT share one rule
CupOne == Lazy \cup Rng
CapOne == Lazy \cap Rng
CapTwo == Lazy \cap Lazy
DifRed == Rng \ Lazy
DifLaz == Lazy \ Rng
\* UNION combines only for a SetEnumValue OF SetEnumValues -- an INTERVAL
\* element is Reducible and still does not combine
UniEnum == UNION {{1, 2}, {3}}
UniIntv == UNION {1..2, 3..4}
\* a filter reads the same predicate off its base
PredLazy == {x \in Lazy : TRUE}
\* the lazy constructors are unconditional, over lazy operands too
SubLazy == SUBSET Lazy
FnsLazy == [Lazy -> {1}]
RcdLazy == [a: Lazy]
\* every domain, not the first; an empty domain is Reducible like any other.
\* The second domain is a SINGLETON on purpose: tlc2 prints a multi-binder
\* function first-index-fastest and the port prints it sorted by domain point,
\* which is the standing `tlc-value-order` approved difference (`ev-multibind`
\* G/H). A singleton second domain makes the two orders coincide, so these
\* pin the CLASS rule without re-testing that difference.
FMulti  == [i \in 1..2, j \in {5} |-> i]
FMixed  == [i \in 1..2, j \in SUBSET {} |-> i]
FMixFst == [i \in Prod, j \in {5} |-> j]
FEmpD   == [x \in Emp |-> 1]
====
