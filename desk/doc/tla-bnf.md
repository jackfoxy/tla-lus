# TLA+ Grammar (`%tla-lus` native parser)

The grammar accepted by `lib/tla/syntax.hoon`, traceable production by
production to `javacc/tla+.jj` at the pinned upstream commit
(doc/port-map.md §1). Validated by the full upstream syntax-conformance
corpus (261 accept/reject cases) against the SANY parse tree.

Drift protection: every `### G-...` heading below must match an entry in
`grammar-manifest:syntax` (lib/tla/syntax.hoon); the generated test
`tests/lib/tla/bnf.hoon` (tools/gen-bnf-manifest.py) fails on any
mismatch in either direction.

## Lexical conventions

Tokens come from `lib/tla/lexer.hoon` (unit 3; tla+.jj lexical states,
lines 939-1402): identifiers (CASE0-CASEN incl. `@`, `W_`-style names,
number sets `ℕ ℤ ℝ`), `\b/\o/\h` and decimal numbers, strings with
`\n \t \r \f \\ \"` escapes, nested `(* *)` and `\*` comments, module
delimiter runs (`----+`, `====+`), proof-step lexemes
(`<digits|+|*>label[.dots]`), junction tokens, and every ASCII/Unicode
operator spelling. CRLF/LF never changes reported positions; tabs
advance columns to the next multiple of eight.

Binder positions retag `\in` to `t-in`; `EXCEPT` assignments retag `=`
to `t-equal`; record-field keywords may be retagged to identifiers;
step numbers are canonicalized (`<*>/<+>` to their level, leading zeros
dropped) exactly as SANY's `correctedStepNum`.

## Operator table

Canonical operators (Operators.java:130-234): low/high precedence,
associativity, fixity. `succ(L,R) = L.lo > R.hi` reduces; `prec(L,R) =
L.hi < R.lo` shifts; neither (without matching associativity) is a
precedence conflict.

| lexeme | lo | hi | assoc | fix |
|---|---|---|---|---|
| `$$_void` | 0 | 0 | none | infix |
| `[` | 160 | 160 | left | postfix |
| `[` | 160 | 160 | left | postfix |
| `.` | 170 | 170 | left | infix |
| `'` | 150 | 150 | none | postfix |
| `^` | 140 | 140 | none | infix |
| `/` | 130 | 130 | none | infix |
| `*` | 130 | 130 | left | infix |
| `-` | 110 | 110 | left | infix |
| `-.` | 120 | 120 | none | prefix |
| `+` | 100 | 100 | left | infix |
| `=` | 50 | 50 | none | infix |
| `\lnot` | 40 | 40 | left | prefix |
| `\land` | 30 | 30 | left | infix |
| `\lor` | 30 | 30 | left | infix |
| `~>` | 20 | 20 | none | infix |
| `=>` | 10 | 10 | none | infix |
| `[]` | 40 | 150 | none | prefix |
| `<>` | 40 | 150 | none | prefix |
| `ENABLED` | 40 | 150 | none | prefix |
| `UNCHANGED` | 40 | 150 | none | prefix |
| `SUBSET` | 100 | 130 | none | prefix |
| `UNION` | 100 | 130 | none | prefix |
| `DOMAIN` | 100 | 130 | none | prefix |
| `^+` | 150 | 150 | none | postfix |
| `^*` | 150 | 150 | none | postfix |
| `^#` | 150 | 150 | none | postfix |
| `\cdot` | 50 | 140 | left | infix |
| `\equiv` | 20 | 20 | none | infix |
| `-+->` | 20 | 20 | none | infix |
| `/=` | 50 | 50 | none | infix |
| `\subseteq` | 50 | 50 | none | infix |
| `\in` | 50 | 50 | none | infix |
| `\notin` | 50 | 50 | none | infix |
| `<` | 50 | 50 | none | infix |
| `\leq` | 50 | 50 | none | infix |
| `>` | 50 | 50 | none | infix |
| `\geq` | 50 | 50 | none | infix |
| `\times` | 100 | 130 | left | nfix |
| `\` | 80 | 80 | none | infix |
| `\intersect` | 80 | 80 | left | infix |
| `\union` | 80 | 80 | left | infix |
| `...` | 90 | 90 | none | infix |
| `..` | 90 | 90 | none | infix |
| `|` | 100 | 110 | left | infix |
| `||` | 100 | 110 | left | infix |
| `&&` | 130 | 130 | left | infix |
| `&` | 130 | 130 | left | infix |
| `$$` | 90 | 130 | left | infix |
| `$` | 90 | 130 | left | infix |
| `??` | 90 | 130 | left | infix |
| `%%` | 100 | 110 | left | infix |
| `%` | 100 | 110 | none | infix |
| `##` | 90 | 130 | left | infix |
| `++` | 100 | 100 | left | infix |
| `--` | 110 | 110 | left | infix |
| `**` | 130 | 130 | left | infix |
| `//` | 130 | 130 | none | infix |
| `^^` | 140 | 140 | none | infix |
| `@@` | 60 | 60 | left | infix |
| `!!` | 90 | 130 | none | infix |
| `|-` | 50 | 50 | none | infix |
| `|=` | 50 | 50 | none | infix |
| `-|` | 50 | 50 | none | infix |
| `=|` | 50 | 50 | none | infix |
| `<:` | 70 | 70 | none | infix |
| `:>` | 70 | 70 | none | infix |
| `:=` | 50 | 50 | none | infix |
| `::=` | 50 | 50 | none | infix |
| `\oplus` | 100 | 100 | left | infix |
| `\ominus` | 110 | 110 | left | infix |
| `\odot` | 130 | 130 | left | infix |
| `\oslash` | 130 | 130 | none | infix |
| `\otimes` | 130 | 130 | left | infix |
| `\uplus` | 90 | 130 | left | infix |
| `\sqcap` | 90 | 130 | left | infix |
| `\sqcup` | 90 | 130 | left | infix |
| `\div` | 130 | 130 | none | infix |
| `\wr` | 90 | 140 | none | infix |
| `\star` | 130 | 130 | left | infix |
| `\o` | 130 | 130 | left | infix |
| `\bigcirc` | 130 | 130 | left | infix |
| `\bullet` | 130 | 130 | left | infix |
| `\prec` | 50 | 50 | none | infix |
| `\succ` | 50 | 50 | none | infix |
| `\preceq` | 50 | 50 | none | infix |
| `\succeq` | 50 | 50 | none | infix |
| `\sim` | 50 | 50 | none | infix |
| `\simeq` | 50 | 50 | none | infix |
| `\ll` | 50 | 50 | none | infix |
| `\gg` | 50 | 50 | none | infix |
| `\asymp` | 50 | 50 | none | infix |
| `\subset` | 50 | 50 | none | infix |
| `\supset` | 50 | 50 | none | infix |
| `\supseteq` | 50 | 50 | none | infix |
| `\approx` | 50 | 50 | none | infix |
| `\cong` | 50 | 50 | none | infix |
| `\sqsubset` | 50 | 50 | none | infix |
| `\sqsubseteq` | 50 | 50 | none | infix |
| `\sqsupset` | 50 | 50 | none | infix |
| `\sqsupseteq` | 50 | 50 | none | infix |
| `\doteq` | 50 | 50 | none | infix |
| `\propto` | 50 | 50 | none | infix |
Synonyms (Operators.java:240-308; alternate spelling -> canonical):

| alternate | canonical |
|---|---|
| `~` | `\lnot` |
| `\neg` | `\lnot` |
| `¬` | `\lnot` |
| `□` | `[]` |
| `◇` | `<>` |
| `/\` | `\land` |
| `∧` | `\land` |
| `\/` | `\lor` |
| `∨` | `\lor` |
| `<=>` | `\equiv` |
| `≡` | `\equiv` |
| `⇔` | `\equiv` |
| `#` | `/=` |
| `≠` | `/=` |
| `<=` | `\leq` |
| `=<` | `\leq` |
| `≤` | `\leq` |
| `>=` | `\geq` |
| `≥` | `\geq` |
| `\X` | `\times` |
| `×` | `\times` |
| `\cap` | `\intersect` |
| `∩` | `\intersect` |
| `\cup` | `\union` |
| `∪` | `\union` |
| `\circ` | `\o` |
| `∘` | `\o` |
| `(+)` | `\oplus` |
| `⊕` | `\oplus` |
| `(-)` | `\ominus` |
| `⊖` | `\ominus` |
| `(.)` | `\odot` |
| `⊙` | `\odot` |
| `(/)` | `\oslash` |
| `⊘` | `\oslash` |
| `(\X)` | `\otimes` |
| `⊗` | `\otimes` |
| `≈` | `\approx` |
| `≔` | `:=` |
| `≍` | `\asymp` |
| `◯` | `\bigcirc` |
| `⩴` | `::=` |
| `●` | `\bullet` |
| `⋅` | `\cdot` |
| `≅` | `\cong` |
| `÷` | `\div` |
| `≐` | `\doteq` |
| `‥` | `..` |
| `…` | `...` |
| `‼` | `!!` |
| `≫` | `\gg` |
| `⇒` | `=>` |
| `∈` | `\in` |
| `⫤` | `=|` |
| `↝` | `~>` |
| `≪` | `\ll` |
| `⊣` | `-|` |
| `∉` | `\notin` |
| `⇸` | `-+->` |
| `≺` | `\prec` |
| `⪯` | `\preceq` |
| `∝` | `\propto` |
| `⁇` | `??` |
| `⊨` | `|=` |
| `⊢` | `|-` |
| `∼` | `\sim` |
| `≃` | `\simeq` |
| `⊓` | `\sqcap` |
| `⊔` | `\sqcup` |
| `⊏` | `\sqsubset` |
| `⊑` | `\sqsubseteq` |
| `⊐` | `\sqsupset` |
| `⊒` | `\sqsupseteq` |
| `⋆` | `\star` |
| `⊂` | `\subset` |
| `⊆` | `\subseteq` |
| `≻` | `\succ` |
| `⪰` | `\succeq` |
| `⊃` | `\supset` |
| `⊇` | `\supseteq` |
| `⊎` | `\uplus` |
| `‖` | `||` |
| `≀` | `\wr` |
| `⁺` | `^+` |
## Productions

EBNF; terminal token kinds in lowercase, productions capitalized.
`Source:` gives the tla+.jj line of the corresponding production;
`Hoon:` the owning arm in lib/tla/syntax.hoon.

### G-module
`Module ::= BeginModule Extends Body EndModule`
Source: tla+.jj:1646. Hoon: +module-prod.

### G-begin-module
`BeginModule ::= (bm0|bm1|bm2) identifier separator`
Source: tla+.jj:1667. Hoon: +module-prod.

### G-extends
`Extends ::= [extends identifier (comma identifier)*]` (empty node when absent)
Source: tla+.jj:1696. Hoon: +decl-list.

### G-body
`Body ::= (Unit)*` where Unit is a separator line, nested Module,
VariableDeclaration, ParamDeclaration, Recursive, Instance, Assumption,
Theorem, UseOrHide, or Definition.
Ambiguity note (pinned bug parity): a *named* theorem or assumption
immediately following a nested module is rejected, as in SANY.
Source: tla+.jj:1720. Hoon: +body-unit, +module-prod.

### G-variable-declaration
`VariableDeclaration ::= variable identifier (comma identifier)*`
Source: tla+.jj:1746. Hoon: +decl-list.

### G-param-declaration
`ParamDeclaration ::= ConsDecl OpDecl (comma OpDecl)*`
`ConsDecl ::= constant` ; `OpDecl ::= IdentDecl | InfixDecl | PrefixDecl | PostfixDecl`
Source: tla+.jj:1765/1827. Hoon: +const-decl, +param-decl.

### G-ident-decl
`IdentDecl ::= identifier [lbr us (comma us)* rbr]`
Source: tla+.jj:1827. Hoon: +op-decl.

### G-op-decls
`InfixDecl ::= us InfixOp us` ; `PrefixDecl ::= NonExpPrefixOp us` ; `PostfixDecl ::= us PostfixOp`
Source: tla+.jj:1827. Hoon: +param-decl.

### G-recursive
`Recursive ::= recursive OpDecl (comma OpDecl)*`
Source: tla+.jj:1807. Hoon: +recursive-prod.

### G-operator-definition
`OperatorDefinition ::= [local] (IdentLHS | PrefixLHS | InfixLHS | PostfixLHS) def Expression`
`IdentLHS ::= identifier [lbr ParamDecl (comma ParamDecl)* rbr]`
`PrefixLHS ::= PrefixOp identifier` ; `InfixLHS ::= identifier InfixOp identifier` ; `PostfixLHS ::= identifier PostfixOp`
Source: tla+.jj:1893. Hoon: +op-or-fun-def, +finish-def, +finish-def2.

### G-function-definition
`FunctionDefinition ::= [local] identifier lsb QuantBound (comma QuantBound)* rsb def Expression`
Source: tla+.jj:1905. Hoon: +op-or-fun-def.

### G-module-definition
`ModuleDefinition ::= [local] IdentLHS def NonLocalInstance`
Source: tla+.jj:2000s. Hoon: +finish-def.

### G-instance
`Instance ::= [local] NonLocalInstance`
`NonLocalInstance ::= instance identifier [with Substitution (comma Substitution)*]`
`Substitution ::= (identifier | NonExpPrefixOp | InfixOp | PostfixOp) substitute Expression`
Source: tla+.jj:2126. Hoon: +instance-unit, +noninst, +substitution.

### G-assumption
`Assumption ::= (assume|assumption) [identifier def] Expression`
Source: tla+.jj:2440s. Hoon: +assumption-unit.

### G-theorem
`Theorem ::= (theorem|proposition) [identifier def] (Expression | AssumeProve) [Proof]`
Source: tla+.jj:2448. Hoon: +theorem-unit.

### G-use-or-hide
`UseOrHide ::= (use|hide) [Items] [df Items]` with
`Items ::= (module identifier | Expression) (comma (module identifier | Expression))*`
Source: tla+.jj:2596 (UseOrHideOrBy). Hoon: +use-hide-unit, +use-hide-by.

### G-expression
`Expression ::=` operator-precedence parse over PrefixOp*, operand,
postfix/`.`/`[`-application chains, and InfixOp continuations, driven by
the OperatorStack shift/reduce engine with junction-column gating.
Unary minus enters as infix `-` and reduces via its mixfix form `-.`;
`\X`/`\times` chains flatten into one N_Times node.
Source: tla+.jj:3908 (Expression), OperatorStack.java. Hoon:
+expression, +operand, +chain, +reduce-stack, +final-reduce.

### G-junctions
`Junctions ::= (and|or Item)+` — items begin at the same column with the
same bullet; every token of an item lies strictly right of the bullet
(checkIndentation), and nested lists reset the discipline.
Source: tla+.jj:3794-3906. Hoon: +junctions, +check-indent.

### G-general-id
`GeneralId ::= IdPrefix (identifier | Op | structop-final)` with
`IdPrefix ::= (IdPrefixElement)*`,
`IdPrefixElement ::= (identifier [OpArgs] | OpArgs | proof-step-lexeme | structop) bang`,
`structop ::= lab | rab | colon | Number` ; final `@` is a structop.
Source: tla+.jj:3088-3630. Hoon: +general-id-full.

### G-op-application
`OpApplication ::= GeneralId OpArgs`
`OpArgs ::= lbr OpArg (comma OpArg)* rbr` ; a bare operator argument
becomes GenPrefixOp/GenInfixOp/GenPostfixOp (nfix operators rejected).
Source: tla+.jj:3100s. Hoon: +ident-expr, +op-args-tail, +op-arg.

### G-atoms
`Number ::= number-literal` ; `Real ::= number-literal dot number-literal` ;
`String` (childless, cooked image) ; `ParenExpr ::= lbr Expression rbr` ;
`Tuple ::= lab [Expression (comma Expression)*] rab`
Source: tla+.jj literals + 2998. Hoon: +number-expr, +paren-expr, +tuple-expr.

### G-action-expr
`ActionExpr ::= lsb Expression arsb Subscript | lab Expression arab Subscript`
`Subscript ::= identifier-GeneralId | Tuple | ParenExpr`
Source: tla+.jj:3400s. Hoon: +sbracket-operand, +tuple-expr, +subscript-expr.

### G-if-then-else
`IfThenElse ::= if Expression then Expression else Expression`
Source: tla+.jj:3703. Hoon: +if-then-else.

### G-case
`Case ::= case CaseArm (casesep CaseArm)* [casesep OtherArm]`
`CaseArm ::= Expression arrow Expression` ; `OtherArm ::= other arrow Expression`
Source: tla+.jj:3719. Hoon: +case-expr, +case-arm.

### G-let-in
`LetIn ::= let (OperatorOrFunctionDefinition | Recursive)+ letin Expression`
Source: tla+.jj:3767. Hoon: +let-in.

### G-quantifiers
`BoundQuant ::= (exists|forall) QuantBound (comma QuantBound)* colon Expression`
`UnboundQuant ::= (exists|forall|t-exists|t-forall) identifier (comma identifier)* colon Expression`
`QuantBound ::= (identifier (comma identifier)* | IdentifierTuple) t-in Expression`
`Choose ::= choose (identifier | IdentifierTuple) MaybeBound colon Expression`
`MaybeBound ::= [t-in Expression]` (empty node when absent)
Source: tla+.jj:3860s. Hoon: +quant-expr, +bound-quant, +unbound-quant, +quant-bound2, +choose-expr.

### G-lambda
`Lambda ::= lambda identifier (comma identifier)* colon Expression`
Source: tla+.jj:3884. Hoon: +lambda-expr.

### G-fairness
`FairnessExpr ::= (wf|sf) Subject lbr Expression rbr`
Source: tla+.jj:3644. Hoon: +fairness-expr.

### G-sets
`SetEnumerate ::= lbc [Expression (comma Expression)*] rbc`
`SubsetOf ::= lbc (identifier | IdentifierTuple) t-in Expression colon Expression rbc`
`SetOfAll ::= lbc Expression colon QuantBound (comma QuantBound)* rbc`
Ambiguity note: `{x \in S}` (no colon) re-parses as a SetEnumerate whose
first element is an InfixExpr keeping the retagged t-in, as SANY does.
Source: tla+.jj:3409-3640. Hoon: +set-expr, +set-enum-tail.

### G-records-functions
`FcnConst ::= lsb QuantBound (comma QuantBound)* mapto Expression rsb`
`RcdConstructor ::= lsb FieldVal (comma FieldVal)* rsb` ; `FieldVal ::= identifier mapto Expression`
`SetOfRcds ::= lsb FieldSet (comma FieldSet)* rsb` ; `FieldSet ::= identifier colon Expression`
`SetOfFcns ::= lsb Expression arrow Expression rsb`
Source: tla+.jj:3409-3640. Hoon: +sbracket-operand, +record-fields.

### G-except
`Except ::= lsb Expression except ExceptSpec (comma ExceptSpec)* rsb`
`ExceptSpec ::= bang (ExceptComponent)+ t-equal Expression`
`ExceptComponent ::= lsb Expression (comma Expression)* rsb | dot identifier`
Source: tla+.jj:3500s. Hoon: +except-tail, +except-spec.

### G-label
`Label ::= (GeneralId | OpApplication) coloncolon Expression` — rejected
when the label would change the parse (labelDoesNotChangeParse).
Source: tla+.jj:2302. Hoon: +label-expr, +label-ok.

### G-proof
`Proof ::= UseOrHideOrBy | [proof] (obvious|omitted) | [proof] Step* QEDStep`
`UseOrHideOrBy ::= [proof] by [only] Items [df Items] | UseOrHide`
Source: tla+.jj:2538/2596. Hoon: +proof-prod, +use-hide-by.

### G-proof-step
`Step ::= StepStart StepBody [Proof]` where StepStart is any proof-step
lexeme with level checking and canonical renumbering; StepBody is
UseOrHideOrBy, NonLocalInstance, DefStep, HaveStep, TakeStep,
WitnessStep, PickStep, CaseStep, or AssertStep; only PICK/CASE/assert
steps take proofs. `QEDStep ::= StepStart qed [Proof]`.
`DefStep ::= [define] Definition+` (definitions detected by the
belchDEF-equivalent lookahead +def-ahead).
Source: tla+.jj:2724 (Step), 241 (belchDEF). Hoon: +step-prod,
+qed-step, +def-step, +def-ahead, +take-pick-step.

### G-assume-prove
`AssumeProve ::= [identifier coloncolon] (assume|boxassume) Item (comma Item)* (prove|boxprove) Expression`
`Item ::= AssumeProve | NewSymb | Expression`
`NewSymb ::= [new] [constant|variable|state|action|temporal] OpDecl [in Expression]`
Source: tla+.jj:2268. Hoon: +assume-prove, +ap-item, +new-symb.
