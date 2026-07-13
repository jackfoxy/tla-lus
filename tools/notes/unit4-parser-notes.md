# Unit 4 Working Notes: SANY Syntactic Analyzer Port

Working reference for implementing `lib/tla/syntax.hoon` + `lib/tla/ast.hoon`.
Source of truth: `javacc/tla+.jj` and `src/tla2sany/parser/*` at the pinned
commit (port-map §1). Read targeted slices of tla+.jj by the line numbers
below rather than the whole file.

## Oracle / differential harness

- `tools/oracle/AstDump.java` (compiled in tools/oracle/build): prints
  `ACCEPT` + preorder tree, 2-space indent per depth:
  `<kind> <bl>.<bc>-<el>.<ec>[ <image>]`
  - image printed only when heirs empty (real token leaves AND synthesized
    empty interior nodes like `n-extends` whose image is the Java constant
    name, e.g. `N_Extends`).
  - synthesized empty nodes have sentinel MAX_VALUE locations → printed `~`.
  - parse failure → single line `REJECT` (error-message parity deferred,
    documented in compatibility.md).
- Kind names: N_* from SyntaxTreeConstants kebab-cased (n-module,
  n-operatordefinition, ...); token kinds same names as unit-3 TokenDump.
- Plan: tools/gen-parser-tests.py mirroring gen-lexer-tests.py: corpus
  cases -> goldens -> generated shards tests/lib/tla/syntax/*.hoon
  comparing `(dump:syntax input)` wain vs golden.

## Hoon-side design

- `lib/tla/ast.hoon`: syntax tree mold (needs `$+` annotation, zuse-408):
  ```
  +$  syntax-node
    $+  syntax-node
    $%  [%leaf =token]                        :: token from lexer
        [%node kind=@tas at=(unit span) kids=(list syntax-node)]
    ==
  ```
  at=~ for synthesized empty nodes. Interior span = [from-of-first-kid
  to-of-last-kid] EXCEPT SANY computes location from heirs similarly —
  verify: SyntaxTreeNode location = union of heirs' locations (check
  SyntaxTreeNode.java constructors if mismatches appear).
  Kind->Java-name table needed for empty-node images (N_Extends etc).
- Parser consumes the unit-3 lexer's token stream (kind/text/span per
  token). Token kinds already match TLAplusParserConstants names.
- Parser state (functional): `[toks=(list token) errs=(list ..) jctx=(list [kind=?(%and %or) col=@ud])]`
  threaded through recursive-descent gates; each production returns
  `(unit [node state])`-ish or uses an abort/error monad. SANY throws
  ParseException and (mostly) stops; multiple ordered diagnostics come
  from PErrors pushes + the final catch. Start with fail-fast + single
  error; add recovery later.

## Operator table (Operators.java:130-308)

Complete list transcribed in Operators.java lines 130-234 (canonical:
name, lo, hi, assoc(none/left/right), fix(prefix/postfix/infix/nfix)) and
synonyms lines 240-308 (first = canonical). resolveSynonym maps any
spelling -> canonical Operator. getMixfix(op): if prefix -> itself; else
lookup name+"." (only "-" -> "-." exists). Special ops:
- "[" (160,160,left,postfix) = function-application dummy (fcnOp).
- Void operator: name "", (-1,-1? check Operator.java:24-29 —
  `assocNone, infix`) pushed by finalReduce to force total reduction.
- "." is infix (170,170,left) but record access is NOT stack-driven: DOT
  handled by reduceRecord in ExtendableExpr.

## prec/succ (Operator.java)

succ(L,R) = L.Low > R.High  → reduce L
prec(L,R) = L.High < R.Low  → shift
Neither & not (L==R && assoc) → precedence-conflict ParseException.

## OperatorStack (OperatorStack.java, full semantics)

Stack of stacks; newStack() per Expression() entry, popStack() on exit.
Elements: OSelement = [node op-or-null]; isOperator() = op != null.
- reduceInfix(op): top >= 4 elems: [.., left, opnode, right] ->
  [.., node]; if op nfix: if left is N_Times: flatten (append opnode,right
  to left's heirs) else new N_Times(left,opnode,right); else
  N_InfixExpr(left,opnode,right).
- reducePrefix: [.., opnode, operand] -> N_PrefixExpr(opnode, operand).
- reducePostfix: [.., operand, opnode]: if op == fcnOp("["):
  N_FcnAppl(operand :: opnode.heirs) else N_PostfixExpr(operand, opnode).
- reduceStack() loop (do..while top-index changes): look at top tm0
  (must be operator else break):
  - oR postfix: n==0 -> err; tm1 operator: infix/prefix -> err, postfix
    -> reducePostfix; tm1 expr: n>1: tm2 op: succ(oL,oR) -> reduce oL
    (infix?reduceInfix:reducePrefix); !prec -> conflict err; else break.
    tm2 not op -> "two expressions" err. n<=1 break.
  - oR prefix: n==0 break; tm1 op: postfix -> err else break; tm1 expr ->
    err ("prefix following expression").
  - oR infix: n==0: getMixfix(oR) null -> err else break ("-" unary).
    tm1 op (infix/prefix): mixR=getMixfix(oR): null -> err (Void -> 
    "missing expression" err); succ(oL,mixR) or (oL==mixR && assocLeft)
    -> conflict err; else break (shift as prefix later).
    tm1 op postfix -> reducePostfix.
    tm1 expr, n>1, tm2 op: oL=tm2.op; if getMixfix(oL)!=null and (n==2 or
    tm[n-3] is operator) -> oL = mixfix(oL) [prefix "-." case];
    succ(oL,oR) or (oL==oR && assocLeft) -> reduce oL (infix/prefix/else
    error incl. "You may have mistyped ==" hint when oR is "=" and lines
    differ; Void -> "missing operator"); elif !(prec(oL,oR) or (oL==oR &&
    assocRight)) -> conflict err; else break.
    tm1 expr, n<=1 -> break; tm2 expr -> "two expressions" err.
- finalReduce: push(null, Void); reduceStack; isWellReduced (size==2) ->
  elementAt(0).node else PErrors.push(incomplete-expression msg) ->
  return null (Expression throws).
- reduceRecord(dotNode, rhsIdent): top: if operator: if postfix-op with
  expr below: addElement(null); reducePostfix; remove humoring; else err
  "``.'' follows operator". Then left=top node; replace with
  N_RecordComponent(left, dotNode, rhsIdent).
- preInEmptyTop: empty or top elem is prefix/infix op (gates Junctions).

## Expression driver (tla+.jj:3908-4090ish)

```
Expression: newStack;
  ( LOOKAHEAD(PrefixOpToken|op_77("-"), isAboveCurrent(col1))
    (PrefixOp -> GenPrefixOp | InfixOp -> GenInfixOp)  :: "-" comes as InfixOp
      push [N_Gen*Op [empty-N_IdPrefix opleaf]] with lastOp; if size!=1 reduceStack
  )*
  ( LOOKAHEAD(OpenStart(), above) OpenExpression -> push(tn, null)
  | LOOKAHEAD(above) ExtendableExpr )
  finalReduce; popStack; return
ExtendableExpr:
  ( LOOKAHEAD(AND|OR, preInEmptyTop) Junctions -> push(tn,null)
  | ParenthesesExpression -> push
  | PrimitiveExp -> push )
  ( LOOKAHEAD(PostfixOp(), above) PostfixOp -> push GenPostfixOp+reduce
  | LOOKAHEAD(DOT, above) DOT (fieldname-token kind coerced to IDENTIFIER)
      Identifier -> reduceRecord
  | LOOKAHEAD(LSB, above) SBracketCases -> if isGenOp(tn) push(tn,lastOp)
      + reduce (tn is N_FcnAppl carrying args; op = fcnOp) else push(tn,null)
  )*
  ( LOOKAHEAD(InfixOp(), above) InfixOp -> push GenInfixOp + reduce
    ... then (PrefixOp* operand postfix*...) — the tail loops back:
    after infix, grammar repeats prefix*, operand, postfix-chain
  )*   :: read tla+.jj 4020-4090 for exact tail when implementing
```
GenInfixOp/GenPrefixOp/GenPostfixOp wrap [N_IdPrefix(empty) op-token-node];
with a nonempty IdPrefix (a!b!) they come via GeneralId paths — read
tla+.jj 3088-3630 (GeneralId, IdPrefix, OpApplication, SBracketCases,
ReducedExpression, PrimitiveExp) when implementing those.

lastOp: parser field set by PrefixOp()/InfixOp()/PostfixOp() productions =
Operators.getOperator(resolveSynonym(token-text)) (check exact code around
tla+.jj 1407-1626: PrefixOpToken/InfixOpToken/PostfixOpToken list the
token alternatives; PrefixOp/InfixOp/PostfixOp build leaf nodes and set
lastOp).

## Junction lists

JunctionListContext = stack of [type(CONJ|DISJ) column].
- Junctions() (tla+.jj:3794): startNewJunctionList(col-of-first-bullet,
  kind); parse DisjList/ConjList; terminate; wrap heirs in
  N_ConjList/N_DisjList.
- List: JuncItem(N_ConjItem/N_DisjItem) first, then while
  isNewBullet(col1,kind1) (same col+type): another item.
- isAboveCurrent(col) = stack empty or col > top.column — gates EVERY
  token continuation inside Expression/ExtendableExpr (LOOKAHEADs above).
- JuncItem: (read tla+.jj ~3819-3870) = bullet token + Expression;
  produces N_ConjItem/N_DisjItem [bullet expr].

## Production inventory (tla+.jj line numbers)

1407 PrefixOpToken, 1428 NEPrefixOpToken, 1447 InfixOpToken,
1617 PostfixOpToken, 1628 CompilationUnit (belchDEF first!), 1641 Prelude,
1646 Module, 1667 BeginModule, 1686 EndModule, 1696 Extends, 1720 Body,
1746 VariableDeclaration, 1765 ParamDeclaration, 1788 ParamSubDecl,
1807 Recursive, 1827 ConstantDeclarationItems, 1893
OperatorOrFunctionDefinition, ~2000-2300 definitions/Instance/
ModuleDefinition/TheoremAssump/labels, 2302 label handling, 2724 Step
(proofs), 2998 ParenthesesExpression, 3008 OpenExpression, 3088-3630
GeneralId/OpApplication/SBracketCases/ReducedExpression/IdPrefix,
3623 ReducedExpression, 3644 FairnessExpr, 3703 IfThenElse, 3719 Case,
3767 LetIn, 3781 LetDefinitions, 3794 Junctions/DisjList/ConjList,
3908 Expression, ~3960 ExtendableExpr, then PrimitiveExp & quantifiers/
set constructors/records/EXCEPT (SBracketCases area ~3400-3640) and
proof productions 2400-2990.

Parser-level token hacks in TLAplusParser.java top (hand-written):
- belchDEF() (tla+.jj:241-405 region): pre-scan rewriting ambiguous DEF
  tokens (BelchDefTests cover it).
- StepStartToken / beginsProof / proof-level machinery (pushProofLevel
  tla+.jj:831+).
- isFieldNameToken (442): keywords usable as record field names
  (kind >= ACTION && <= EXCEPT etc).
- matchFcnConst (542): semantic lookahead for [x \in S |-> e].
- caseSep (537): getToken(1).kind == CASESEP.

## Testing sequence (implement in this order, corpus files in brackets)

1. Module skeleton: header/extends/body/end [modules.txt]
2. Declarations: VARIABLE/CONSTANT/RECURSIVE [declarations? in unit.txt]
3. Simple op definitions + Expression engine + GeneralId atoms + numbers/
   strings/booleans [expressions.txt, operators.txt, infix-op.txt,
   prefix-op.txt, postfix-op.txt, precedence corpus]
4. Parens/tuples/sets/functions/records/EXCEPT [tuples.txt, sets.txt,
   functions.txt, except.txt, string.txt]
5. IF/CASE/LET/quantifiers/CHOOSE/fairness [if_then_else.txt, case.txt,
   let-in.txt, quantification?, fairness.txt]
6. Junction lists [conjlist.txt, disjlist.txt, jlist.txt]
7. INSTANCE/module defs/theorems/assumptions [instance?, use-or-hide.txt,
   assume.txt]
8. Proofs [proofs?, step-expressions.txt, assume-prove.txt]
9. Subexpression refs (a!b!c, labels) [subexpressions.txt, labels.txt]

## Status log (update as you go)

- [x] AstDump.java oracle built + sentinel-normalized.
- [x] ast.hoon (recursive mold via obelisk $+/$:-with-%tag recipe)
- [x] syntax.hoon: module frame, decls, defs (ident/infix/prefix/postfix
      LHS, function defs f[x \in S]==e, LOCAL, ModuleDefinition),
      param-decls (_+_ etc), CONSTANT/RECURSIVE/VARIABLE, INSTANCE+WITH,
      ASSUME/THEOREM (named), USE/HIDE (DEF, MODULE items), expression
      engine (operator stack), junction lists + checkIndentation,
      labels + labelDoesNotChangeParse, sets (incl {x \in S} recovery
      with retagged t-in), records/functions/EXCEPT (t-equal),
      quantifiers/CHOOSE/fairness/LAMBDA, subexpression !-prefixes
      (structops, opargs elements), nonfix op references, bare-op args
      (Gen*Op, nfix rejected), Real numbers.
- [x] 222/224 non-proof corpus cases green vs AstDump oracle.
- [ ] REMAINING: proofs.txt / step_expressions.txt / assume-prove.txt
      shards; belchDEF (modules-005 REJECT depends on it);
      proof-step-id GeneralIds (subexpressions-002); BNF doc + manifest.
- Key retag facts: t-in in binders (quantbound/subsetof/maybebound/
  fcnconst), t-equal in ExceptSpec; N_String image = cooked string;
  \f escaping in both dumpers; clean-screen tmux discipline:
  C-l + clear-history before every judged run.

## Node shape facts (from AstDump probe — authoritative)

- Childless-but-located nodes carry an IMAGE (printed by dump):
  `n-string 2.10-2.13 "ab"` (image = raw text incl quotes),
  `n-infixop 2.8-2.8 +` / n-prefixop / n-postfixop (image = spelling as
  written, NOT canonical). Token-derived nodes = SyntaxTreeNode(mn, token)
  with kind overridden: N_String childless; N_Number WRAPS a
  number-literal leaf child.
- ast mold needs image on %node: [%node kind at image kids] — image =
  token text for token-derived childless nodes; Java constant name for
  synthesized empty nodes; ignored when kids nonempty.
- Shapes: OperatorDefinition = [IdentLHS def-leaf expr];
  IdentLHS = [ident] or [ident lbr IdentDecl (comma IdentDecl)* rbr];
  IdentDecl = [ident]; GeneralId = [IdPrefix(empty) ident-leaf];
  Number = [number-lit leaf]; Tuple = [lab expr rab];
  InfixExpr = [left GenInfixOp right];
  GenInfixOp = [IdPrefix(empty) InfixOp-node(image=spelling)];
  PrefixExpr = [GenPrefixOp operand];
  FcnAppl = [operand lsb arg rsb] (SBracket heirs appended after operand);
  RecordComponent = [expr dot-leaf ident-leaf];
  Module = [BeginModule Extends Body EndModule];
  BeginModule = [bm-leaf ident-leaf separator-leaf];
  EndModule = [end-module-leaf]; Extends childless when absent.
- Void operator = ("$$_void", 0, 0, none, infix).
- probe fixture: scratchpad/probe.tla pattern; AstDump build:
  cd tools/oracle && java -m jdk.compiler/com.sun.tools.javac.Main -cp <jar> -d build AstDump.java

## Batch-3 golden shapes (verbatim oracle output)

### fairness-000
```
---- MODULE Test ----
op == WF_(vars)(x)
====
---
ACCEPT
n-module 1.1-3.4
  n-beginmodule 1.1-1.21
    bm1 1.1-1.11 ---- MODULE
    identifier 1.13-1.16 Test
    separator 1.18-1.21 ----
  n-extends ~ N_Extends
  n-body 2.1-2.18
    n-operatordefinition 2.1-2.18
      n-identlhs 2.1-2.2
        identifier 2.1-2.2 op
      def 2.4-2.5 ==
      n-fairnessexpr 2.7-2.18
        wf 2.7-2.9 WF_
        n-parenexpr 2.10-2.15
          lbr 2.10-2.10 (
          n-generalid 2.11-2.14
            n-idprefix ~ N_IdPrefix
            identifier 2.11-2.14 vars
          rbr 2.15-2.15 )
        lbr 2.16-2.16 (
        n-generalid 2.17-2.17
          n-idprefix ~ N_IdPrefix
          identifier 2.17-2.17 x
        rbr 2.18-2.18 )
  n-endmodule 3.1-3.4
    end-module 3.1-3.4 ====
```

### quantification-000
```
---- MODULE Test ----
op == \A x, y \in Nat, z \in Int, a, b, c \in Real : FALSE
op == \E x, y \in Nat, a, b \in Int : TRUE
====
---
ACCEPT
n-module 1.1-4.4
  n-beginmodule 1.1-1.21
    bm1 1.1-1.11 ---- MODULE
    identifier 1.13-1.16 Test
    separator 1.18-1.21 ----
  n-extends ~ N_Extends
  n-body 2.1-3.42
    n-operatordefinition 2.1-2.58
      n-identlhs 2.1-2.2
        identifier 2.1-2.2 op
      def 2.4-2.5 ==
      n-boundquant 2.7-2.58
        forall 2.7-2.8 \\A
        n-quantbound 2.10-2.21
          identifier 2.10-2.10 x
          comma 2.11-2.11 ,
          identifier 2.13-2.13 y
          t-in 2.15-2.17 \\in
          n-generalid 2.19-2.21
            n-idprefix ~ N_IdPrefix
            identifier 2.19-2.21 Nat
        comma 2.22-2.22 ,
        n-quantbound 2.24-2.32
          identifier 2.24-2.24 z
          t-in 2.26-2.28 \\in
          n-generalid 2.30-2.32
            n-idprefix ~ N_IdPrefix
            identifier 2.30-2.32 Int
        comma 2.33-2.33 ,
        n-quantbound 2.35-2.50
          identifier 2.35-2.35 a
          comma 2.36-2.36 ,
          identifier 2.38-2.38 b
          comma 2.39-2.39 ,
          identifier 2.41-2.41 c
          t-in 2.43-2.45 \\in
          n-generalid 2.47-2.50
            n-idprefix ~ N_IdPrefix
            identifier 2.47-2.50 Real
        colon 2.52-2.52 :
        n-generalid 2.54-2.58
          n-idprefix ~ N_IdPrefix
          identifier 2.54-2.58 FALSE
    n-operatordefinition 3.1-3.42
      n-identlhs 3.1-3.2
        identifier 3.1-3.2 op
      def 3.4-3.5 ==
      n-boundquant 3.7-3.42
        exists 3.7-3.8 \\E
        n-quantbound 3.10-3.21
          identifier 3.10-3.10 x
          comma 3.11-3.11 ,
          identifier 3.13-3.13 y
          t-in 3.15-3.17 \\in
          n-generalid 3.19-3.21
            n-idprefix ~ N_IdPrefix
            identifier 3.19-3.21 Nat
        comma 3.22-3.22 ,
        n-quantbound 3.24-3.35
          identifier 3.24-3.24 a
          comma 3.25-3.25 ,
          identifier 3.27-3.27 b
          t-in 3.29-3.31 \\in
          n-generalid 3.33-3.35
            n-idprefix ~ N_IdPrefix
            identifier 3.33-3.35 Int
        colon 3.37-3.37 :
        n-generalid 3.39-3.42
          n-idprefix ~ N_IdPrefix
          identifier 3.39-3.42 TRUE
  n-endmodule 4.1-4.4
    end-module 4.1-4.4 ====
```

### quantification-002
```
---- MODULE Test ----
op == \A <<x, y>> \in Nat, <<z>> \in Int, <<a, b, c>> \in Real : FALSE
op == \E <<x, y>> \in Nat, <<a, b>> \in Int : TRUE
====
---
ACCEPT
n-module 1.1-4.4
  n-beginmodule 1.1-1.21
    bm1 1.1-1.11 ---- MODULE
    identifier 1.13-1.16 Test
    separator 1.18-1.21 ----
  n-extends ~ N_Extends
  n-body 2.1-3.50
    n-operatordefinition 2.1-2.70
      n-identlhs 2.1-2.2
        identifier 2.1-2.2 op
      def 2.4-2.5 ==
      n-boundquant 2.7-2.70
        forall 2.7-2.8 \\A
        n-quantbound 2.10-2.25
          n-identifiertuple 2.10-2.17
            lab 2.10-2.11 <<
            identifier 2.12-2.12 x
            comma 2.13-2.13 ,
            identifier 2.15-2.15 y
            rab 2.16-2.17 >>
          t-in 2.19-2.21 \\in
          n-generalid 2.23-2.25
            n-idprefix ~ N_IdPrefix
            identifier 2.23-2.25 Nat
        comma 2.26-2.26 ,
        n-quantbound 2.28-2.40
          n-identifiertuple 2.28-2.32
            lab 2.28-2.29 <<
            identifier 2.30-2.30 z
            rab 2.31-2.32 >>
          t-in 2.34-2.36 \\in
          n-generalid 2.38-2.40
            n-idprefix ~ N_IdPrefix
            identifier 2.38-2.40 Int
        comma 2.41-2.41 ,
        n-quantbound 2.43-2.62
          n-identifiertuple 2.43-2.53
            lab 2.43-2.44 <<
            identifier 2.45-2.45 a
            comma 2.46-2.46 ,
            identifier 2.48-2.48 b
            comma 2.49-2.49 ,
            identifier 2.51-2.51 c
            rab 2.52-2.53 >>
          t-in 2.55-2.57 \\in
          n-generalid 2.59-2.62
            n-idprefix ~ N_IdPrefix
            identifier 2.59-2.62 Real
        colon 2.64-2.64 :
        n-generalid 2.66-2.70
          n-idprefix ~ N_IdPrefix
          identifier 2.66-2.70 FALSE
    n-operatordefinition 3.1-3.50
      n-identlhs 3.1-3.2
        identifier 3.1-3.2 op
      def 3.4-3.5 ==
      n-boundquant 3.7-3.50
        exists 3.7-3.8 \\E
        n-quantbound 3.10-3.25
          n-identifiertuple 3.10-3.17
            lab 3.10-3.11 <<
            identifier 3.12-3.12 x
            comma 3.13-3.13 ,
            identifier 3.15-3.15 y
            rab 3.16-3.17 >>
          t-in 3.19-3.21 \\in
          n-generalid 3.23-3.25
            n-idprefix ~ N_IdPrefix
            identifier 3.23-3.25 Nat
        comma 3.26-3.26 ,
        n-quantbound 3.28-3.43
          n-identifiertuple 3.28-3.35
            lab 3.28-3.29 <<
            identifier 3.30-3.30 a
            comma 3.31-3.31 ,
            identifier 3.33-3.33 b
            rab 3.34-3.35 >>
          t-in 3.37-3.39 \\in
          n-generalid 3.41-3.43
            n-idprefix ~ N_IdPrefix
            identifier 3.41-3.43 Int
        colon 3.45-3.45 :
        n-generalid 3.47-3.50
          n-idprefix ~ N_IdPrefix
          identifier 3.47-3.50 TRUE
  n-endmodule 4.1-4.4
    end-module 4.1-4.4 ====
```

### quantification-005
```
---- MODULE Test ----
op == \A x : TRUE
op == \E x, y : FALSE
op == \AA x, y, z : TRUE
op == \EE x, y, z, w : FALSE
====
---
ACCEPT
n-module 1.1-6.4
  n-beginmodule 1.1-1.21
    bm1 1.1-1.11 ---- MODULE
    identifier 1.13-1.16 Test
    separator 1.18-1.21 ----
  n-extends ~ N_Extends
  n-body 2.1-5.28
    n-operatordefinition 2.1-2.17
      n-identlhs 2.1-2.2
        identifier 2.1-2.2 op
      def 2.4-2.5 ==
      n-unboundquant 2.7-2.17
        forall 2.7-2.8 \\A
        identifier 2.10-2.10 x
        colon 2.12-2.12 :
        n-generalid 2.14-2.17
          n-idprefix ~ N_IdPrefix
          identifier 2.14-2.17 TRUE
    n-operatordefinition 3.1-3.21
      n-identlhs 3.1-3.2
        identifier 3.1-3.2 op
      def 3.4-3.5 ==
      n-unboundquant 3.7-3.21
        exists 3.7-3.8 \\E
        identifier 3.10-3.10 x
        comma 3.11-3.11 ,
        identifier 3.13-3.13 y
        colon 3.15-3.15 :
        n-generalid 3.17-3.21
          n-idprefix ~ N_IdPrefix
          identifier 3.17-3.21 FALSE
    n-operatordefinition 4.1-4.24
      n-identlhs 4.1-4.2
        identifier 4.1-4.2 op
      def 4.4-4.5 ==
      n-unboundquant 4.7-4.24
        t-forall 4.7-4.9 \\AA
        identifier 4.11-4.11 x
        comma 4.12-4.12 ,
        identifier 4.14-4.14 y
        comma 4.15-4.15 ,
        identifier 4.17-4.17 z
        colon 4.19-4.19 :
        n-generalid 4.21-4.24
          n-idprefix ~ N_IdPrefix
          identifier 4.21-4.24 TRUE
    n-operatordefinition 5.1-5.28
      n-identlhs 5.1-5.2
        identifier 5.1-5.2 op
      def 5.4-5.5 ==
      n-unboundquant 5.7-5.28
        t-exists 5.7-5.9 \\EE
        identifier 5.11-5.11 x
        comma 5.12-5.12 ,
        identifier 5.14-5.14 y
        comma 5.15-5.15 ,
        identifier 5.17-5.17 z
        comma 5.18-5.18 ,
        identifier 5.20-5.20 w
        colon 5.22-5.22 :
        n-generalid 5.24-5.28
          n-idprefix ~ N_IdPrefix
          identifier 5.24-5.28 FALSE
  n-endmodule 6.1-6.4
    end-module 6.1-6.4 ====
```

### quantification-006
```
---- MODULE Test ----
op == CHOOSE x \in Nat : TRUE
====
---
ACCEPT
n-module 1.1-3.4
  n-beginmodule 1.1-1.21
    bm1 1.1-1.11 ---- MODULE
    identifier 1.13-1.16 Test
    separator 1.18-1.21 ----
  n-extends ~ N_Extends
  n-body 2.1-2.29
    n-operatordefinition 2.1-2.29
      n-identlhs 2.1-2.2
        identifier 2.1-2.2 op
      def 2.4-2.5 ==
      n-unboundorboundchoose 2.7-2.29
        choose 2.7-2.12 CHOOSE
        identifier 2.14-2.14 x
        n-maybebound 2.16-2.22
          t-in 2.16-2.18 \\in
          n-generalid 2.20-2.22
            n-idprefix ~ N_IdPrefix
            identifier 2.20-2.22 Nat
        colon 2.24-2.24 :
        n-generalid 2.26-2.29
          n-idprefix ~ N_IdPrefix
          identifier 2.26-2.29 TRUE
  n-endmodule 3.1-3.4
    end-module 3.1-3.4 ====
```

### quantification-008
```
---- MODULE Test ----
op == CHOOSE x : TRUE
====
---
ACCEPT
n-module 1.1-3.4
  n-beginmodule 1.1-1.21
    bm1 1.1-1.11 ---- MODULE
    identifier 1.13-1.16 Test
    separator 1.18-1.21 ----
  n-extends ~ N_Extends
  n-body 2.1-2.21
    n-operatordefinition 2.1-2.21
      n-identlhs 2.1-2.2
        identifier 2.1-2.2 op
      def 2.4-2.5 ==
      n-unboundorboundchoose 2.7-2.21
        choose 2.7-2.12 CHOOSE
        identifier 2.14-2.14 x
        n-maybebound ~ N_MaybeBound
        colon 2.16-2.16 :
        n-generalid 2.18-2.21
          n-idprefix ~ N_IdPrefix
          identifier 2.18-2.21 TRUE
  n-endmodule 3.1-3.4
    end-module 3.1-3.4 ====
```

### except-002
```
---- MODULE Test ----
r == [a EXCEPT !.x.y.z = "b"]
====
---
ACCEPT
n-module 1.1-3.4
  n-beginmodule 1.1-1.21
    bm1 1.1-1.11 ---- MODULE
    identifier 1.13-1.16 Test
    separator 1.18-1.21 ----
  n-extends ~ N_Extends
  n-body 2.1-2.29
    n-operatordefinition 2.1-2.29
      n-identlhs 2.1-2.1
        identifier 2.1-2.1 r
      def 2.3-2.4 ==
      n-except 2.6-2.29
        lsb 2.6-2.6 [
        n-generalid 2.7-2.7
          n-idprefix ~ N_IdPrefix
          identifier 2.7-2.7 a
        except 2.9-2.14 EXCEPT
        n-exceptspec 2.16-2.28
          bang 2.16-2.16 !
          n-exceptcomponent 2.17-2.18
            dot 2.17-2.17 .
            identifier 2.18-2.18 x
          n-exceptcomponent 2.19-2.20
            dot 2.19-2.19 .
            identifier 2.20-2.20 y
          n-exceptcomponent 2.21-2.22
            dot 2.21-2.21 .
            identifier 2.22-2.22 z
          t-equal 2.24-2.24 =
          n-string 2.26-2.28 "b"
        rsb 2.29-2.29 ]
  n-endmodule 3.1-3.4
    end-module 3.1-3.4 ====
```

### recursive-004
```
---- MODULE Test ----
RECURSIVE f(_), g, h(_, _, _), _+_, -. _, _ ^+
====
---
ACCEPT
n-module 1.1-3.4
  n-beginmodule 1.1-1.21
    bm1 1.1-1.11 ---- MODULE
    identifier 1.13-1.16 Test
    separator 1.18-1.21 ----
  n-extends ~ N_Extends
  n-body 2.1-2.46
    n-recursive 2.1-2.46
      recursive 2.1-2.9 RECURSIVE
      n-identdecl 2.11-2.14
        identifier 2.11-2.11 f
        lbr 2.12-2.12 (
        us 2.13-2.13 _
        rbr 2.14-2.14 )
      comma 2.15-2.15 ,
      n-identdecl 2.17-2.17
        identifier 2.17-2.17 g
      comma 2.18-2.18 ,
      n-identdecl 2.20-2.29
        identifier 2.20-2.20 h
        lbr 2.21-2.21 (
        us 2.22-2.22 _
        comma 2.23-2.23 ,
        us 2.25-2.25 _
        comma 2.26-2.26 ,
        us 2.28-2.28 _
        rbr 2.29-2.29 )
      comma 2.30-2.30 ,
      n-infixdecl 2.32-2.34
        us 2.32-2.32 _
        n-infixop 2.33-2.33 +
        us 2.34-2.34 _
      comma 2.35-2.35 ,
      n-prefixdecl 2.37-2.40
        n-nonexpprefixop 2.37-2.38 -.
        us 2.40-2.40 _
      comma 2.41-2.41 ,
      n-postfixdecl 2.43-2.46
        us 2.43-2.43 _
        n-postfixop 2.45-2.46 ^+
  n-endmodule 3.1-3.4
    end-module 3.1-3.4 ====
```

### infix-op-000
```
---- MODULE Test ----
x \X y == 0
x \times y == 0
====
---
ACCEPT
n-module 1.1-4.4
  n-beginmodule 1.1-1.21
    bm1 1.1-1.11 ---- MODULE
    identifier 1.13-1.16 Test
    separator 1.18-1.21 ----
  n-extends ~ N_Extends
  n-body 2.1-3.15
    n-operatordefinition 2.1-2.11
      n-infixlhs 2.1-2.6
        identifier 2.1-2.1 x
        op-119 2.3-2.4 \\X
        identifier 2.6-2.6 y
      def 2.8-2.9 ==
      n-number 2.11-2.11
        number-literal 2.11-2.11 0
    n-operatordefinition 3.1-3.15
      n-infixlhs 3.1-3.10
        identifier 3.1-3.1 x
        op-118 3.3-3.8 \\times
        identifier 3.10-3.10 y
      def 3.12-3.13 ==
      n-number 3.15-3.15
        number-literal 3.15-3.15 0
  n-endmodule 4.1-4.4
    end-module 4.1-4.4 ====
```

### infix-op-002
```
---- MODULE Test ----
op(_ \X _, _ \times _) == TRUE
====
---
ACCEPT
n-module 1.1-3.4
  n-beginmodule 1.1-1.21
    bm1 1.1-1.11 ---- MODULE
    identifier 1.13-1.16 Test
    separator 1.18-1.21 ----
  n-extends ~ N_Extends
  n-body 2.1-2.30
    n-operatordefinition 2.1-2.30
      n-identlhs 2.1-2.22
        identifier 2.1-2.2 op
        lbr 2.3-2.3 (
        n-infixdecl 2.4-2.9
          us 2.4-2.4 _
          n-infixop 2.6-2.7 \\X
          us 2.9-2.9 _
        comma 2.10-2.10 ,
        n-infixdecl 2.12-2.21
          us 2.12-2.12 _
          n-infixop 2.14-2.19 \\times
          us 2.21-2.21 _
        rbr 2.22-2.22 )
      def 2.24-2.25 ==
      n-generalid 2.27-2.30
        n-idprefix ~ N_IdPrefix
        identifier 2.27-2.30 TRUE
  n-endmodule 3.1-3.4
    end-module 3.1-3.4 ====
```

### infix-op-008
```
---- MODULE Test ----
op == {
  A!B!&(x, y),
  A!B!&&(x, y),
  A!B!\approx(x, y),
  A!B!:=(x, y),
  A!B!\asymp(x, y),
  A!B!\bigcirc(x, y),
  A!B!::=(x, y),
  A!B!\bullet(x, y),
  A!B!\intersect(x, y),
  A!B!\cap(x, y),
  A!B!\cdot(x, y),
  A!B!\o(x, y),
  A!B!\circ(x, y),
  A!B!@@(x, y),
  A!B!\cong(x, y),
  A!B!\union(x, y),
  A!B!\cup(x, y),
  A!B!\div(x, y),
  A!B!$(x, y),
  A!B!$$(x, y),
  A!B!\doteq(x, y),
  A!B!..(x, y),
  A!B!...(x, y),
  A!B!=(x, y),
  A!B!\equiv(x, y),
  A!B!>=(x, y),
  A!B!\geq(x, y),
  A!B!\gg(x, y),
  A!B!>(x, y),
  A!B!##(x, y),
  A!B!<=>(x, y),
  A!B!=>(x, y),
  A!B!\in(x, y),
  A!B!\land(x, y),
  A!B!=|(x, y),
  A!B!~>(x, y),
  A!B!<=(x, y),
  A!B!=<(x, y),
  A!B!\leq(x, y),
  A!B!\ll(x, y),
  A!B!\lor(x, y),
  A!B!-|(x, y),
  A!B!<(x, y),
  A!B!<:(x, y),
  A!B!:>(x, y),
  A!B!-(x, y),
  A!B!--(x, y),
  A!B!%(x, y),
  A!B!%%(x, y),
  A!B!*(x, y),
  A!B!**(x, y),
  A!B!/=(x, y),
  A!B!#(x, y),
  A!B!\notin(x, y),
  A!B!(.)(x, y),
  A!B!\odot(x, y),
  A!B!(-)(x, y),
  A!B!\ominus(x, y),
  A!B!(+)(x, y),
  A!B!\oplus(x, y),
  A!B!(/)(x, y),
  A!B!\oslash(x, y),
  A!B!(\X)(x, y),
  A!B!\otimes(x, y),
  A!B!+(x, y),
  A!B!-+->(x, y),
  A!B!++(x, y),
  A!B!^(x, y),
  A!B!^^(x, y),
  A!B!\prec(x, y),
  A!B!\preceq(x, y),
  A!B!\propto(x, y),
  A!B!??(x, y),
  A!B!|=(x, y),
  A!B!|-(x, y),
  A!B!\(x, y),
  A!B!\sim(x, y),
  A!B!\simeq(x, y),
  A!B!/(x, y),
  A!B!//(x, y),
  A!B!\sqcap(x, y),
  A!B!\sqcup(x, y),
  A!B!\sqsubset(x, y),
  A!B!\sqsubseteq(x, y),
  A!B!\sqsupset(x, y),
  A!B!\sqsupseteq(x, y),
  A!B!\star(x, y),
  A!B!\subset(x, y),
  A!B!\subseteq(x, y),
  A!B!\succ(x, y),
  A!B!\succeq(x, y),
  A!B!\supset(x, y),
  A!B!\supseteq(x, y),
  A!B!\X(x, y),
  A!B!\times(x, y),
  A!B!\uplus(x, y),
  A!B!|(x, y),
  A!B!||(x, y),
  A!B!\wr(x, y)
}
====
---
ACCEPT
n-module 1.1-103.4
  n-beginmodule 1.1-1.21
    bm1 1.1-1.11 ---- MODULE
    identifier 1.13-1.16 Test
    separator 1.18-1.21 ----
  n-extends ~ N_Extends
  n-body 2.1-102.1
    n-operatordefinition 2.1-102.1
      n-identlhs 2.1-2.2
        identifier 2.1-2.2 op
      def 2.4-2.5 ==
      n-setenumerate 2.7-102.1
        lbc 2.7-2.7 {
        n-opapplication 3.3-3.13
          n-generalid 3.3-3.7
            n-idprefix 3.3-3.6
              n-idprefixelement 3.3-3.4
                identifier 3.3-3.3 A
                bang 3.4-3.4 !
              n-idprefixelement 3.5-3.6
                identifier 3.5-3.5 B
                bang 3.6-3.6 !
            n-infixop 3.7-3.7 &
          n-opargs 3.8-3.13
            lbr 3.8-3.8 (
            n-generalid 3.9-3.9
              n-idprefix ~ N_IdPrefix
              identifier 3.9-3.9 x
            comma 3.10-3.10 ,
            n-generalid 3.12-3.12
              n-idprefix ~ N_IdPrefix
              identifier 3.12-3.12 y
            rbr 3.13-3.13 )
        comma 3.14-3.14 ,
        n-opapplication 4.3-4.14
          n-generalid 4.3-4.8
            n-idprefix 4.3-4.6
              n-idprefixelement 4.3-4.4
                identifier 4.3-4.3 A
                bang 4.4-4.4 !
              n-idprefixelement 4.5-4.6
                identifier 4.5-4.5 B
                bang 4.6-4.6 !
            n-infixop 4.7-4.8 &&
          n-opargs 4.9-4.14
            lbr 4.9-4.9 (
            n-generalid 4.10-4.10
              n-idprefix ~ N_IdPrefix
              identifier 4.10-4.10 x
            comma 4.11-4.11 ,
            n-generalid 4.13-4.13
              n-idprefix ~ N_IdPrefix
              identifier 4.13-4.13 y
            rbr 4.14-4.14 )
        comma 4.15-4.15 ,
        n-opapplication 5.3-5.19
          n-generalid 5.3-5.13
            n-idprefix 5.3-5.6
              n-idprefixelement 5.3-5.4
                identifier 5.3-5.3 A
                bang 5.4-5.4 !
              n-idprefixelement 5.5-5.6
                identifier 5.5-5.5 B
                bang 5.6-5.6 !
            n-infixop 5.7-5.13 \\approx
          n-opargs 5.14-5.19
            lbr 5.14-5.14 (
            n-generalid 5.15-5.15
              n-idprefix ~ N_IdPrefix
              identifier 5.15-5.15 x
            comma 5.16-5.16 ,
            n-generalid 5.18-5.18
              n-idprefix ~ N_IdPrefix
              identifier 5.18-5.18 y
            rbr 5.19-5.19 )
        comma 5.20-5.20 ,
        n-opapplication 6.3-6.14
          n-generalid 6.3-6.8
            n-idprefix 6.3-6.6
              n-idprefixelement 6.3-6.4
                identifier 6.3-6.3 A
                bang 6.4-6.4 !
              n-idprefixelement 6.5-6.6
                identifier 6.5-6.5 B
                bang 6.6-6.6 !
            n-infixop 6.7-6.8 :=
          n-opargs 6.9-6.14
            lbr 6.9-6.9 (
            n-generalid 6.10-6.10
              n-idprefix ~ N_IdPrefix
              identifier 6.10-6.10 x
            comma 6.11-6.11 ,
            n-generalid 6.13-6.13
              n-idprefix ~ N_IdPrefix
              identifier 6.13-6.13 y
            rbr 6.14-6.14 )
        comma 6.15-6.15 ,
        n-opapplication 7.3-7.18
          n-generalid 7.3-7.12
            n-idprefix 7.3-7.6
              n-idprefixelement 7.3-7.4
                identifier 7.3-7.3 A
                bang 7.4-7.4 !
              n-idprefixelement 7.5-7.6
                identifier 7.5-7.5 B
                bang 7.6-7.6 !
            n-infixop 7.7-7.12 \\asymp
          n-opargs 7.13-7.18
            lbr 7.13-7.13 (
            n-generalid 7.14-7.14
              n-idprefix ~ N_IdPrefix
              identifier 7.14-7.14 x
            comma 7.15-7.15 ,
            n-generalid 7.17-7.17
              n-idprefix ~ N_IdPrefix
              identifier 7.17-7.17 y
            rbr 7.18-7.18 )
        comma 7.19-7.19 ,
        n-opapplication 8.3-8.20
          n-generalid 8.3-8.14
            n-idprefix 8.3-8.6
              n-idprefixelement 8.3-8.4
                identifier 8.3-8.3 A
                bang 8.4-8.4 !
              n-idprefixelement 8.5-8.6
                identifier 8.5-8.5 B
                bang 8.6-8.6 !
            n-infixop 8.7-8.14 \\bigcirc
          n-opargs 8.15-8.20
            lbr 8.15-8.15 (
            n-generalid 8.16-8.16
              n-idprefix ~ N_IdPrefix
              identifier 8.16-8.16 x
            comma 8.17-8.17 ,
            n-generalid 8.19-8.19
              n-idprefix ~ N_IdPrefix
              identifier 8.19-8.19 y
            rbr 8.20-8.20 )
        comma 8.21-8.21 ,
        n-opapplication 9.3-9.15
          n-generalid 9.3-9.9
            n-idprefix 9.3-9.6
              n-idprefixelement 9.3-9.4
                identifier 9.3-9.3 A
                bang 9.4-9.4 !
              n-idprefixelement 9.5-9.6
                identifier 9.5-9.5 B
                bang 9.6-9.6 !
            n-infixop 9.7-9.9 ::=
          n-opargs 9.10-9.15
            lbr 9.10-9.10 (
            n-generalid 9.11-9.11
              n-idprefix ~ N_IdPrefix
              identifier 9.11-9.11 x
            comma 9.12-9.12 ,
            n-generalid 9.14-9.14
              n-idprefix ~ N_IdPrefix
              identifier 9.14-9.14 y
            rbr 9.15-9.15 )
        comma 9.16-9.16 ,
        n-opapplication 10.3-10.19
          n-generalid 10.3-10.13
            n-idprefix 10.3-10.6
              n-idprefixelement 10.3-10.4
                identifier 10.3-10.3 A
                bang 10.4-10.4 !
              n-idprefixelement 10.5-10.6
                identifier 10.5-10.5 B
                bang 10.6-10.6 !
            n-infixop 10.7-10.13 \\bullet
          n-opargs 10.14-10.19
            lbr 10.14-10.14 (
            n-generalid 10.15-10.15
              n-idprefix ~ N_IdPrefix
              identifier 10.15-10.15 x
            comma 10.16-10.16 ,
            n-generalid 10.18-10.18
              n-idprefix ~ N_IdPrefix
              identifier 10.18-10.18 y
            rbr 10.19-10.19 )
        comma 10.20-10.20 ,
        n-opapplication 11.3-11.22
          n-generalid 11.3-11.16
            n-idprefix 11.3-11.6
              n-idprefixelement 11.3-11.4
                identifier 11.3-11.3 A
                bang 11.4-11.4 !
              n-idprefixelement 11.5-11.6
                identifier 11.5-11.5 B
                bang 11.6-11.6 !
            n-infixop 11.7-11.16 \\intersect
          n-opargs 11.17-11.22
            lbr 11.17-11.17 (
            n-generalid 11.18-11.18
              n-idprefix ~ N_IdPrefix
              identifier 11.18-11.18 x
            comma 11.19-11.19 ,
            n-generalid 11.21-11.21
              n-idprefix ~ N_IdPrefix
              identifier 11.21-11.21 y
            rbr 11.22-11.22 )
        comma 11.23-11.23 ,
        n-opapplication 12.3-12.16
          n-generalid 12.3-12.10
            n-idprefix 12.3-12.6
              n-idprefixelement 12.3-12.4
                identifier 12.3-12.3 A
                bang 12.4-12.4 !
              n-idprefixelement 12.5-12.6
                identifier 12.5-12.5 B
                bang 12.6-12.6 !
            n-infixop 12.7-12.10 \\cap
          n-opargs 12.11-12.16
            lbr 12.11-12.11 (
            n-generalid 12.12-12.12
              n-idprefix ~ N_IdPrefix
              identifier 12.12-12.12 x
            comma 12.13-12.13 ,
            n-generalid 12.15-12.15
              n-idprefix ~ N_IdPrefix
              identifier 12.15-12.15 y
            rbr 12.16-12.16 )
        comma 12.17-12.17 ,
        n-opapplication 13.3-13.17
          n-generalid 13.3-13.11
            n-idprefix 13.3-13.6
              n-idprefixelement 13.3-13.4
                identifier 13.3-13.3 A
                bang 13.4-13.4 !
              n-idprefixelement 13.5-13.6
                identifier 13.5-13.5 B
                bang 13.6-13.6 !
            n-infixop 13.7-13.11 \\cdot
          n-opargs 13.12-13.17
            lbr 13.12-13.12 (
            n-generalid 13.13-13.13
              n-idprefix ~ N_IdPrefix
              identifier 13.13-13.13 x
            comma 13.14-13.14 ,
            n-generalid 13.16-13.16
              n-idprefix ~ N_IdPrefix
              identifier 13.16-13.16 y
            rbr 13.17-13.17 )
        comma 13.18-13.18 ,
        n-opapplication 14.3-14.14
          n-generalid 14.3-14.8
            n-idprefix 14.3-14.6
              n-idprefixelement 14.3-14.4
                identifier 14.3-14.3 A
                bang 14.4-14.4 !
              n-idprefixelement 14.5-14.6
                identifier 14.5-14.5 B
                bang 14.6-14.6 !
            n-infixop 14.7-14.8 \\o
          n-opargs 14.9-14.14
            lbr 14.9-14.9 (
            n-generalid 14.10-14.10
              n-idprefix ~ N_IdPrefix
              identifier 14.10-14.10 x
            comma 14.11-14.11 ,
            n-generalid 14.13-14.13
              n-idprefix ~ N_IdPrefix
              identifier 14.13-14.13 y
            rbr 14.14-14.14 )
        comma 14.15-14.15 ,
        n-opapplication 15.3-15.17
          n-generalid 15.3-15.11
            n-idprefix 15.3-15.6
              n-idprefixelement 15.3-15.4
                identifier 15.3-15.3 A
                bang 15.4-15.4 !
              n-idprefixelement 15.5-15.6
                identifier 15.5-15.5 B
                bang 15.6-15.6 !
            n-infixop 15.7-15.11 \\circ
          n-opargs 15.12-15.17
            lbr 15.12-15.12 (
            n-generalid 15.13-15.13
              n-idprefix ~ N_IdPrefix
              identifier 15.13-15.13 x
            comma 15.14-15.14 ,
            n-generalid 15.16-15.16
              n-idprefix ~ N_IdPrefix
              identifier 15.16-15.16 y
            rbr 15.17-15.17 )
        comma 15.18-15.18 ,
        n-opapplication 16.3-16.14
          n-generalid 16.3-16.8
            n-idprefix 16.3-16.6
              n-idprefixelement 16.3-16.4
                identifier 16.3-16.3 A
                bang 16.4-16.4 !
              n-idprefixelement 16.5-16.6
                identifier 16.5-16.5 B
                bang 16.6-16.6 !
            n-infixop 16.7-16.8 @@
          n-opargs 16.9-16.14
            lbr 16.9-16.9 (
            n-generalid 16.10-16.10
              n-idprefix ~ N_IdPrefix
              identifier 16.10-16.10 x
            comma 16.11-16.11 ,
            n-generalid 16.13-16.13
              n-idprefix ~ N_IdPrefix
              identifier 16.13-16.13 y
            rbr 16.14-16.14 )
        comma 16.15-16.15 ,
        n-opapplication 17.3-17.17
          n-generalid 17.3-17.11
            n-idprefix 17.3-17.6
              n-idprefixelement 17.3-17.4
                identifier 17.3-17.3 A
                bang 17.4-17.4 !
              n-idprefixelement 17.5-17.6
                identifier 17.5-17.5 B
                bang 17.6-17.6 !
            n-infixop 17.7-17.11 \\cong
          n-opargs 17.12-17.17
            lbr 17.12-17.12 (
            n-generalid 17.13-17.13
              n-idprefix ~ N_IdPrefix
              identifier 17.13-17.13 x
            comma 17.14-17.14 ,
            n-generalid 17.16-17.16
              n-idprefix ~ N_IdPrefix
              identifier 17.16-17.16 y
            rbr 17.17-17.17 )
        comma 17.18-17.18 ,
        n-opapplication 18.3-18.18
          n-generalid 18.3-18.12
            n-idprefix 18.3-18.6
              n-idprefixelement 18.3-18.4
                identifier 18.3-18.3 A
                bang 18.4-18.4 !
              n-idprefixelement 18.5-18.6
                identifier 18.5-18.5 B
                bang 18.6-18.6 !
            n-infixop 18.7-18.12 \\union
          n-opargs 18.13-18.18
            lbr 18.13-18.13 (
            n-generalid 18.14-18.14
              n-idprefix ~ N_IdPrefix
              identifier 18.14-18.14 x
            comma 18.15-18.15 ,
            n-generalid 18.17-18.17
              n-idprefix ~ N_IdPrefix
              identifier 18.17-18.17 y
            rbr 18.18-18.18 )
        comma 18.19-18.19 ,
        n-opapplication 19.3-19.16
          n-generalid 19.3-19.10
            n-idprefix 19.3-19.6
              n-idprefixelement 19.3-19.4
                identifier 19.3-19.3 A
                bang 19.4-19.4 !
              n-idprefixelement 19.5-19.6
                identifier 19.5-19.5 B
                bang 19.6-19.6 !
            n-infixop 19.7-19.10 \\cup
          n-opargs 19.11-19.16
            lbr 19.11-19.11 (
            n-generalid 19.12-19.12
              n-idprefix ~ N_IdPrefix
              identifier 19.12-19.12 x
            comma 19.13-19.13 ,
            n-generalid 19.15-19.15
              n-idprefix ~ N_IdPrefix
              identifier 19.15-19.15 y
            rbr 19.16-19.16 )
        comma 19.17-19.17 ,
        n-opapplication 20.3-20.16
          n-generalid 20.3-20.10
            n-idprefix 20.3-20.6
              n-idprefixelement 20.3-20.4
                identifier 20.3-20.3 A
                bang 20.4-20.4 !
              n-idprefixelement 20.5-20.6
                identifier 20.5-20.5 B
                bang 20.6-20.6 !
            n-infixop 20.7-20.10 \\div
          n-opargs 20.11-20.16
            lbr 20.11-20.11 (
            n-generalid 20.12-20.12
              n-idprefix ~ N_IdPrefix
              identifier 20.12-20.12 x
            comma 20.13-20.13 ,
            n-generalid 20.15-20.15
              n-idprefix ~ N_IdPrefix
              identifier 20.15-20.15 y
            rbr 20.16-20.16 )
        comma 20.17-20.17 ,
        n-opapplication 21.3-21.13
          n-generalid 21.3-21.7
            n-idprefix 21.3-21.6
              n-idprefixelement 21.3-21.4
                identifier 21.3-21.3 A
                bang 21.4-21.4 !
              n-idprefixelement 21.5-21.6
                identifier 21.5-21.5 B
                bang 21.6-21.6 !
            n-infixop 21.7-21.7 $
          n-opargs 21.8-21.13
            lbr 21.8-21.8 (
            n-generalid 21.9-21.9
              n-idprefix ~ N_IdPrefix
              identifier 21.9-21.9 x
            comma 21.10-21.10 ,
            n-generalid 21.12-21.12
              n-idprefix ~ N_IdPrefix
              identifier 21.12-21.12 y
            rbr 21.13-21.13 )
        comma 21.14-21.14 ,
        n-opapplication 22.3-22.14
          n-generalid 22.3-22.8
            n-idprefix 22.3-22.6
              n-idprefixelement 22.3-22.4
                identifier 22.3-22.3 A
                bang 22.4-22.4 !
              n-idprefixelement 22.5-22.6
                identifier 22.5-22.5 B
                bang 22.6-22.6 !
            n-infixop 22.7-22.8 $$
          n-opargs 22.9-22.14
            lbr 22.9-22.9 (
            n-generalid 22.10-22.10
              n-idprefix ~ N_IdPrefix
              identifier 22.10-22.10 x
            comma 22.11-22.11 ,
            n-generalid 22.13-22.13
              n-idprefix ~ N_IdPrefix
              identifier 22.13-22.13 y
            rbr 22.14-22.14 )
        comma 22.15-22.15 ,
        n-opapplication 23.3-23.18
          n-generalid 23.3-23.12
            n-idprefix 23.3-23.6
              n-idprefixelement 23.3-23.4
                identifier 23.3-23.3 A
                bang 23.4-23.4 !
              n-idprefixelement 23.5-23.6
                identifier 23.5-23.5 B
                bang 23.6-23.6 !
            n-infixop 23.7-23.12 \\doteq
          n-opargs 23.13-23.18
            lbr 23.13-23.13 (
            n-generalid 23.14-23.14
              n-idprefix ~ N_IdPrefix
              identifier 23.14-23.14 x
            comma 23.15-23.15 ,
            n-generalid 23.17-23.17
              n-idprefix ~ N_IdPrefix
              identifier 23.17-23.17 y
            rbr 23.18-23.18 )
        comma 23.19-23.19 ,
        n-opapplication 24.3-24.14
          n-generalid 24.3-24.8
            n-idprefix 24.3-24.6
              n-idprefixelement 24.3-24.4
                identifier 24.3-24.3 A
                bang 24.4-24.4 !
              n-idprefixelement 24.5-24.6
                identifier 24.5-24.5 B
                bang 24.6-24.6 !
            n-infixop 24.7-24.8 ..
          n-opargs 24.9-24.14
            lbr 24.9-24.9 (
            n-generalid 24.10-24.10
              n-idprefix ~ N_IdPrefix
              identifier 24.10-24.10 x
            comma 24.11-24.11 ,
            n-generalid 24.13-24.13
              n-idprefix ~ N_IdPrefix
              identifier 24.13-24.13 y
            rbr 24.14-24.14 )
        comma 24.15-24.15 ,
        n-opapplication 25.3-25.15
          n-generalid 25.3-25.9
            n-idprefix 25.3-25.6
              n-idprefixelement 25.3-25.4
                identifier 25.3-25.3 A
                bang 25.4-25.4 !
              n-idprefixelement 25.5-25.6
                identifier 25.5-25.5 B
                bang 25.6-25.6 !
            n-infixop 25.7-25.9 ...
          n-opargs 25.10-25.15
            lbr 25.10-25.10 (
            n-generalid 25.11-25.11
              n-idprefix ~ N_IdPrefix
              identifier 25.11-25.11 x
            comma 25.12-25.12 ,
            n-generalid 25.14-25.14
              n-idprefix ~ N_IdPrefix
              identifier 25.14-25.14 y
            rbr 25.15-25.15 )
        comma 25.16-25.16 ,
        n-opapplication 26.3-26.13
          n-generalid 26.3-26.7
            n-idprefix 26.3-26.6
              n-idprefixelement 26.3-26.4
                identifier 26.3-26.3 A
                bang 26.4-26.4 !
              n-idprefixelement 26.5-26.6
                identifier 26.5-26.5 B
                bang 26.6-26.6 !
            n-infixop 26.7-26.7 =
          n-opargs 26.8-26.13
            lbr 26.8-26.8 (
            n-generalid 26.9-26.9
              n-idprefix ~ N_IdPrefix
              identifier 26.9-26.9 x
            comma 26.10-26.10 ,
            n-generalid 26.12-26.12
              n-idprefix ~ N_IdPrefix
              identifier 26.12-26.12 y
            rbr 26.13-26.13 )
        comma 26.14-26.14 ,
        n-opapplication 27.3-27.18
          n-generalid 27.3-27.12
            n-idprefix 27.3-27.6
              n-idprefixelement 27.3-27.4
                identifier 27.3-27.3 A
                bang 27.4-27.4 !
              n-idprefixelement 27.5-27.6
                identifier 27.5-27.5 B
                bang 27.6-27.6 !
            n-infixop 27.7-27.12 \\equiv
          n-opargs 27.13-27.18
            lbr 27.13-27.13 (
            n-generalid 27.14-27.14
              n-idprefix ~ N_IdPrefix
              identifier 27.14-27.14 x
            comma 27.15-27.15 ,
            n-generalid 27.17-27.17
              n-idprefix ~ N_IdPrefix
              identifier 27.17-27.17 y
            rbr 27.18-27.18 )
        comma 27.19-27.19 ,
        n-opapplication 28.3-28.14
          n-generalid 28.3-28.8
            n-idprefix 28.3-28.6
              n-idprefixelement 28.3-28.4
                identifier 28.3-28.3 A
                bang 28.4-28.4 !
              n-idprefixelement 28.5-28.6
                identifier 28.5-28.5 B
                bang 28.6-28.6 !
            n-infixop 28.7-28.8 >=
          n-opargs 28.9-28.14
            lbr 28.9-28.9 (
            n-generalid 28.10-28.10
              n-idprefix ~ N_IdPrefix
              identifier 28.10-28.10 x
            comma 28.11-28.11 ,
            n-generalid 28.13-28.13
              n-idprefix ~ N_IdPrefix
              identifier 28.13-28.13 y
            rbr 28.14-28.14 )
        comma 28.15-28.15 ,
        n-opapplication 29.3-29.16
          n-generalid 29.3-29.10
            n-idprefix 29.3-29.6
              n-idprefixelement 29.3-29.4
                identifier 29.3-29.3 A
                bang 29.4-29.4 !
              n-idprefixelement 29.5-29.6
                identifier 29.5-29.5 B
                bang 29.6-29.6 !
            n-infixop 29.7-29.10 \\geq
          n-opargs 29.11-29.16
            lbr 29.11-29.11 (
            n-generalid 29.12-29.12
              n-idprefix ~ N_IdPrefix
              identifier 29.12-29.12 x
            comma 29.13-29.13 ,
            n-generalid 29.15-29.15
              n-idprefix ~ N_IdPrefix
              identifier 29.15-29.15 y
            rbr 29.16-29.16 )
        comma 29.17-29.17 ,
        n-opapplication 30.3-30.15
          n-generalid 30.3-30.9
            n-idprefix 30.3-30.6
              n-idprefixelement 30.3-30.4
                identifier 30.3-30.3 A
                bang 30.4-30.4 !
              n-idprefixelement 30.5-30.6
                identifier 30.5-30.5 B
                bang 30.6-30.6 !
            n-infixop 30.7-30.9 \\gg
          n-opargs 30.10-30.15
            lbr 30.10-30.10 (
            n-generalid 30.11-30.11
              n-idprefix ~ N_IdPrefix
              identifier 30.11-30.11 x
            comma 30.12-30.12 ,
            n-generalid 30.14-30.14
              n-idprefix ~ N_IdPrefix
              identifier 30.14-30.14 y
            rbr 30.15-30.15 )
        comma 30.16-30.16 ,
        n-opapplication 31.3-31.13
          n-generalid 31.3-31.7
            n-idprefix 31.3-31.6
              n-idprefixelement 31.3-31.4
                identifier 31.3-31.3 A
                bang 31.4-31.4 !
              n-idprefixelement 31.5-31.6
                identifier 31.5-31.5 B
                bang 31.6-31.6 !
            n-infixop 31.7-31.7 >
          n-opargs 31.8-31.13
            lbr 31.8-31.8 (
            n-generalid 31.9-31.9
              n-idprefix ~ N_IdPrefix
              identifier 31.9-31.9 x
            comma 31.10-31.10 ,
            n-generalid 31.12-31.12
              n-idprefix ~ N_IdPrefix
              identifier 31.12-31.12 y
            rbr 31.13-31.13 )
        comma 31.14-31.14 ,
        n-opapplication 32.3-32.14
          n-generalid 32.3-32.8
            n-idprefix 32.3-32.6
              n-idprefixelement 32.3-32.4
                identifier 32.3-32.3 A
                bang 32.4-32.4 !
              n-idprefixelement 32.5-32.6
                identifier 32.5-32.5 B
                bang 32.6-32.6 !
            n-infixop 32.7-32.8 ##
          n-opargs 32.9-32.14
            lbr 32.9-32.9 (
            n-generalid 32.10-32.10
              n-idprefix ~ N_IdPrefix
              identifier 32.10-32.10 x
            comma 32.11-32.11 ,
            n-generalid 32.13-32.13
              n-idprefix ~ N_IdPrefix
              identifier 32.13-32.13 y
            rbr 32.14-32.14 )
        comma 32.15-32.15 ,
        n-opapplication 33.3-33.15
          n-generalid 33.3-33.9
            n-idprefix 33.3-33.6
              n-idprefixelement 33.3-33.4
                identifier 33.3-33.3 A
                bang 33.4-33.4 !
              n-idprefixelement 33.5-33.6
                identifier 33.5-33.5 B
                bang 33.6-33.6 !
            n-infixop 33.7-33.9 <=>
          n-opargs 33.10-33.15
            lbr 33.10-33.10 (
            n-generalid 33.11-33.11
              n-idprefix ~ N_IdPrefix
              identifier 33.11-33.11 x
            comma 33.12-33.12 ,
            n-generalid 33.14-33.14
              n-idprefix ~ N_IdPrefix
              identifier 33.14-33.14 y
            rbr 33.15-33.15 )
        comma 33.16-33.16 ,
        n-opapplication 34.3-34.14
          n-generalid 34.3-34.8
            n-idprefix 34.3-34.6
              n-idprefixelement 34.3-34.4
                identifier 34.3-34.3 A
                bang 34.4-34.4 !
              n-idprefixelement 34.5-34.6
                identifier 34.5-34.5 B
                bang 34.6-34.6 !
            n-infixop 34.7-34.8 =>
          n-opargs 34.9-34.14
            lbr 34.9-34.9 (
            n-generalid 34.10-34.10
              n-idprefix ~ N_IdPrefix
              identifier 34.10-34.10 x
            comma 34.11-34.11 ,
            n-generalid 34.13-34.13
              n-idprefix ~ N_IdPrefix
              identifier 34.13-34.13 y
            rbr 34.14-34.14 )
        comma 34.15-34.15 ,
        n-opapplication 35.3-35.15
          n-generalid 35.3-35.9
            n-idprefix 35.3-35.6
              n-idprefixelement 35.3-35.4
                identifier 35.3-35.3 A
                bang 35.4-35.4 !
              n-idprefixelement 35.5-35.6
                identifier 35.5-35.5 B
                bang 35.6-35.6 !
            n-infixop 35.7-35.9 \\in
          n-opargs 35.10-35.15
            lbr 35.10-35.10 (
            n-generalid 35.11-35.11
              n-idprefix ~ N_IdPrefix
              identifier 35.11-35.11 x
            comma 35.12-35.12 ,
            n-generalid 35.14-35.14
              n-idprefix ~ N_IdPrefix
              identifier 35.14-35.14 y
            rbr 35.15-35.15 )
        comma 35.16-35.16 ,
        n-opapplication 36.3-36.17
          n-generalid 36.3-36.11
            n-idprefix 36.3-36.6
              n-idprefixelement 36.3-36.4
                identifier 36.3-36.3 A
                bang 36.4-36.4 !
              n-idprefixelement 36.5-36.6
                identifier 36.5-36.5 B
                bang 36.6-36.6 !
            n-infixop 36.7-36.11 \\land
          n-opargs 36.12-36.17
            lbr 36.12-36.12 (
            n-generalid 36.13-36.13
              n-idprefix ~ N_IdPrefix
              identifier 36.13-36.13 x
            comma 36.14-36.14 ,
            n-generalid 36.16-36.16
              n-idprefix ~ N_IdPrefix
              identifier 36.16-36.16 y
            rbr 36.17-36.17 )
        comma 36.18-36.18 ,
        n-opapplication 37.3-37.14
          n-generalid 37.3-37.8
            n-idprefix 37.3-37.6
              n-idprefixelement 37.3-37.4
                identifier 37.3-37.3 A
                bang 37.4-37.4 !
              n-idprefixelement 37.5-37.6
                identifier 37.5-37.5 B
                bang 37.6-37.6 !
            n-infixop 37.7-37.8 =|
          n-opargs 37.9-37.14
            lbr 37.9-37.9 (
            n-generalid 37.10-37.10
              n-idprefix ~ N_IdPrefix
              identifier 37.10-37.10 x
            comma 37.11-37.11 ,
            n-generalid 37.13-37.13
              n-idprefix ~ N_IdPrefix
              identifier 37.13-37.13 y
            rbr 37.14-37.14 )
        comma 37.15-37.15 ,
        n-opapplication 38.3-38.14
          n-generalid 38.3-38.8
            n-idprefix 38.3-38.6
              n-idprefixelement 38.3-38.4
                identifier 38.3-38.3 A
                bang 38.4-38.4 !
              n-idprefixelement 38.5-38.6
                identifier 38.5-38.5 B
                bang 38.6-38.6 !
            n-infixop 38.7-38.8 ~>
          n-opargs 38.9-38.14
            lbr 38.9-38.9 (
            n-generalid 38.10-38.10
              n-idprefix ~ N_IdPrefix
              identifier 38.10-38.10 x
            comma 38.11-38.11 ,
            n-generalid 38.13-38.13
              n-idprefix ~ N_IdPrefix
              identifier 38.13-38.13 y
            rbr 38.14-38.14 )
        comma 38.15-38.15 ,
        n-opapplication 39.3-39.14
          n-generalid 39.3-39.8
            n-idprefix 39.3-39.6
              n-idprefixelement 39.3-39.4
                identifier 39.3-39.3 A
                bang 39.4-39.4 !
              n-idprefixelement 39.5-39.6
                identifier 39.5-39.5 B
                bang 39.6-39.6 !
            n-infixop 39.7-39.8 <=
          n-opargs 39.9-39.14
            lbr 39.9-39.9 (
            n-generalid 39.10-39.10
              n-idprefix ~ N_IdPrefix
              identifier 39.10-39.10 x
            comma 39.11-39.11 ,
            n-generalid 39.13-39.13
              n-idprefix ~ N_IdPrefix
              identifier 39.13-39.13 y
            rbr 39.14-39.14 )
        comma 39.15-39.15 ,
        n-opapplication 40.3-40.14
          n-generalid 40.3-40.8
            n-idprefix 40.3-40.6
              n-idprefixelement 40.3-40.4
                identifier 40.3-40.3 A
                bang 40.4-40.4 !
              n-idprefixelement 40.5-40.6
                identifier 40.5-40.5 B
                bang 40.6-40.6 !
            n-infixop 40.7-40.8 =<
          n-opargs 40.9-40.14
            lbr 40.9-40.9 (
            n-generalid 40.10-40.10
              n-idprefix ~ N_IdPrefix
              identifier 40.10-40.10 x
            comma 40.11-40.11 ,
            n-generalid 40.13-40.13
              n-idprefix ~ N_IdPrefix
              identifier 40.13-40.13 y
            rbr 40.14-40.14 )
        comma 40.15-40.15 ,
        n-opapplication 41.3-41.16
          n-generalid 41.3-41.10
            n-idprefix 41.3-41.6
              n-idprefixelement 41.3-41.4
                identifier 41.3-41.3 A
                bang 41.4-41.4 !
              n-idprefixelement 41.5-41.6
                identifier 41.5-41.5 B
                bang 41.6-41.6 !
            n-infixop 41.7-41.10 \\leq
          n-opargs 41.11-41.16
            lbr 41.11-41.11 (
            n-generalid 41.12-41.12
              n-idprefix ~ N_IdPrefix
              identifier 41.12-41.12 x
            comma 41.13-41.13 ,
            n-generalid 41.15-41.15
              n-idprefix ~ N_IdPrefix
              identifier 41.15-41.15 y
            rbr 41.16-41.16 )
        comma 41.17-41.17 ,
        n-opapplication 42.3-42.15
          n-generalid 42.3-42.9
            n-idprefix 42.3-42.6
              n-idprefixelement 42.3-42.4
                identifier 42.3-42.3 A
                bang 42.4-42.4 !
              n-idprefixelement 42.5-42.6
                identifier 42.5-42.5 B
                bang 42.6-42.6 !
            n-infixop 42.7-42.9 \\ll
          n-opargs 42.10-42.15
            lbr 42.10-42.10 (
            n-generalid 42.11-42.11
              n-idprefix ~ N_IdPrefix
              identifier 42.11-42.11 x
            comma 42.12-42.12 ,
            n-generalid 42.14-42.14
              n-idprefix ~ N_IdPrefix
              identifier 42.14-42.14 y
            rbr 42.15-42.15 )
        comma 42.16-42.16 ,
        n-opapplication 43.3-43.16
          n-generalid 43.3-43.10
            n-idprefix 43.3-43.6
              n-idprefixelement 43.3-43.4
                identifier 43.3-43.3 A
                bang 43.4-43.4 !
              n-idprefixelement 43.5-43.6
                identifier 43.5-43.5 B
                bang 43.6-43.6 !
            n-infixop 43.7-43.10 \\lor
          n-opargs 43.11-43.16
            lbr 43.11-43.11 (
            n-generalid 43.12-43.12
              n-idprefix ~ N_IdPrefix
              identifier 43.12-43.12 x
            comma 43.13-43.13 ,
            n-generalid 43.15-43.15
              n-idprefix ~ N_IdPrefix
              identifier 43.15-43.15 y
            rbr 43.16-43.16 )
        comma 43.17-43.17 ,
        n-opapplication 44.3-44.14
          n-generalid 44.3-44.8
            n-idprefix 44.3-44.6
              n-idprefixelement 44.3-44.4
                identifier 44.3-44.3 A
                bang 44.4-44.4 !
              n-idprefixelement 44.5-44.6
                identifier 44.5-44.5 B
                bang 44.6-44.6 !
            n-infixop 44.7-44.8 -|
          n-opargs 44.9-44.14
            lbr 44.9-44.9 (
            n-generalid 44.10-44.10
              n-idprefix ~ N_IdPrefix
              identifier 44.10-44.10 x
            comma 44.11-44.11 ,
            n-generalid 44.13-44.13
              n-idprefix ~ N_IdPrefix
              identifier 44.13-44.13 y
            rbr 44.14-44.14 )
        comma 44.15-44.15 ,
        n-opapplication 45.3-45.13
          n-generalid 45.3-45.7
            n-idprefix 45.3-45.6
              n-idprefixelement 45.3-45.4
                identifier 45.3-45.3 A
                bang 45.4-45.4 !
              n-idprefixelement 45.5-45.6
                identifier 45.5-45.5 B
                bang 45.6-45.6 !
            n-infixop 45.7-45.7 <
          n-opargs 45.8-45.13
            lbr 45.8-45.8 (
            n-generalid 45.9-45.9
              n-idprefix ~ N_IdPrefix
              identifier 45.9-45.9 x
            comma 45.10-45.10 ,
            n-generalid 45.12-45.12
              n-idprefix ~ N_IdPrefix
              identifier 45.12-45.12 y
            rbr 45.13-45.13 )
        comma 45.14-45.14 ,
        n-opapplication 46.3-46.14
          n-generalid 46.3-46.8
            n-idprefix 46.3-46.6
              n-idprefixelement 46.3-46.4
                identifier 46.3-46.3 A
                bang 46.4-46.4 !
              n-idprefixelement 46.5-46.6
                identifier 46.5-46.5 B
                bang 46.6-46.6 !
            n-infixop 46.7-46.8 <:
          n-opargs 46.9-46.14
            lbr 46.9-46.9 (
            n-generalid 46.10-46.10
              n-idprefix ~ N_IdPrefix
              identifier 46.10-46.10 x
            comma 46.11-46.11 ,
            n-generalid 46.13-46.13
              n-idprefix ~ N_IdPrefix
              identifier 46.13-46.13 y
            rbr 46.14-46.14 )
        comma 46.15-46.15 ,
        n-opapplication 47.3-47.14
          n-generalid 47.3-47.8
            n-idprefix 47.3-47.6
              n-idprefixelement 47.3-47.4
                identifier 47.3-47.3 A
                bang 47.4-47.4 !
              n-idprefixelement 47.5-47.6
                identifier 47.5-47.5 B
                bang 47.6-47.6 !
            n-infixop 47.7-47.8 :>
          n-opargs 47.9-47.14
            lbr 47.9-47.9 (
            n-generalid 47.10-47.10
              n-idprefix ~ N_IdPrefix
              identifier 47.10-47.10 x
            comma 47.11-47.11 ,
            n-generalid 47.13-47.13
              n-idprefix ~ N_IdPrefix
              identifier 47.13-47.13 y
            rbr 47.14-47.14 )
        comma 47.15-47.15 ,
        n-opapplication 48.3-48.13
          n-generalid 48.3-48.7
            n-idprefix 48.3-48.6
              n-idprefixelement 48.3-48.4
                identifier 48.3-48.3 A
                bang 48.4-48.4 !
              n-idprefixelement 48.5-48.6
                identifier 48.5-48.5 B
                bang 48.6-48.6 !
            n-infixop 48.7-48.7 -
          n-opargs 48.8-48.13
            lbr 48.8-48.8 (
            n-generalid 48.9-48.9
              n-idprefix ~ N_IdPrefix
              identifier 48.9-48.9 x
            comma 48.10-48.10 ,
            n-generalid 48.12-48.12
              n-idprefix ~ N_IdPrefix
              identifier 48.12-48.12 y
            rbr 48.13-48.13 )
        comma 48.14-48.14 ,
        n-opapplication 49.3-49.14
          n-generalid 49.3-49.8
            n-idprefix 49.3-49.6
              n-idprefixelement 49.3-49.4
                identifier 49.3-49.3 A
                bang 49.4-49.4 !
              n-idprefixelement 49.5-49.6
                identifier 49.5-49.5 B
                bang 49.6-49.6 !
            n-infixop 49.7-49.8 --
          n-opargs 49.9-49.14
            lbr 49.9-49.9 (
            n-generalid 49.10-49.10
              n-idprefix ~ N_IdPrefix
              identifier 49.10-49.10 x
            comma 49.11-49.11 ,
            n-generalid 49.13-49.13
              n-idprefix ~ N_IdPrefix
              identifier 49.13-49.13 y
            rbr 49.14-49.14 )
        comma 49.15-49.15 ,
        n-opapplication 50.3-50.13
          n-generalid 50.3-50.7
            n-idprefix 50.3-50.6
              n-idprefixelement 50.3-50.4
                identifier 50.3-50.3 A
                bang 50.4-50.4 !
              n-idprefixelement 50.5-50.6
                identifier 50.5-50.5 B
                bang 50.6-50.6 !
            n-infixop 50.7-50.7 %
          n-opargs 50.8-50.13
            lbr 50.8-50.8 (
            n-generalid 50.9-50.9
              n-idprefix ~ N_IdPrefix
              identifier 50.9-50.9 x
            comma 50.10-50.10 ,
            n-generalid 50.12-50.12
              n-idprefix ~ N_IdPrefix
              identifier 50.12-50.12 y
            rbr 50.13-50.13 )
        comma 50.14-50.14 ,
        n-opapplication 51.3-51.14
          n-generalid 51.3-51.8
            n-idprefix 51.3-51.6
              n-idprefixelement 51.3-51.4
                identifier 51.3-51.3 A
                bang 51.4-51.4 !
              n-idprefixelement 51.5-51.6
                identifier 51.5-51.5 B
                bang 51.6-51.6 !
            n-infixop 51.7-51.8 %%
          n-opargs 51.9-51.14
            lbr 51.9-51.9 (
            n-generalid 51.10-51.10
              n-idprefix ~ N_IdPrefix
              identifier 51.10-51.10 x
            comma 51.11-51.11 ,
            n-generalid 51.13-51.13
              n-idprefix ~ N_IdPrefix
              identifier 51.13-51.13 y
            rbr 51.14-51.14 )
        comma 51.15-51.15 ,
        n-opapplication 52.3-52.13
          n-generalid 52.3-52.7
            n-idprefix 52.3-52.6
              n-idprefixelement 52.3-52.4
                identifier 52.3-52.3 A
                bang 52.4-52.4 !
              n-idprefixelement 52.5-52.6
                identifier 52.5-52.5 B
                bang 52.6-52.6 !
            n-infixop 52.7-52.7 *
          n-opargs 52.8-52.13
            lbr 52.8-52.8 (
            n-generalid 52.9-52.9
              n-idprefix ~ N_IdPrefix
              identifier 52.9-52.9 x
            comma 52.10-52.10 ,
            n-generalid 52.12-52.12
              n-idprefix ~ N_IdPrefix
              identifier 52.12-52.12 y
            rbr 52.13-52.13 )
        comma 52.14-52.14 ,
        n-opapplication 53.3-53.14
          n-generalid 53.3-53.8
            n-idprefix 53.3-53.6
              n-idprefixelement 53.3-53.4
                identifier 53.3-53.3 A
                bang 53.4-53.4 !
              n-idprefixelement 53.5-53.6
                identifier 53.5-53.5 B
                bang 53.6-53.6 !
            n-infixop 53.7-53.8 **
          n-opargs 53.9-53.14
            lbr 53.9-53.9 (
            n-generalid 53.10-53.10
              n-idprefix ~ N_IdPrefix
              identifier 53.10-53.10 x
            comma 53.11-53.11 ,
            n-generalid 53.13-53.13
              n-idprefix ~ N_IdPrefix
              identifier 53.13-53.13 y
            rbr 53.14-53.14 )
        comma 53.15-53.15 ,
        n-opapplication 54.3-54.14
          n-generalid 54.3-54.8
            n-idprefix 54.3-54.6
              n-idprefixelement 54.3-54.4
                identifier 54.3-54.3 A
                bang 54.4-54.4 !
              n-idprefixelement 54.5-54.6
                identifier 54.5-54.5 B
                bang 54.6-54.6 !
            n-infixop 54.7-54.8 /=
          n-opargs 54.9-54.14
            lbr 54.9-54.9 (
            n-generalid 54.10-54.10
              n-idprefix ~ N_IdPrefix
              identifier 54.10-54.10 x
            comma 54.11-54.11 ,
            n-generalid 54.13-54.13
              n-idprefix ~ N_IdPrefix
              identifier 54.13-54.13 y
            rbr 54.14-54.14 )
        comma 54.15-54.15 ,
        n-opapplication 55.3-55.13
          n-generalid 55.3-55.7
            n-idprefix 55.3-55.6
              n-idprefixelement 55.3-55.4
                identifier 55.3-55.3 A
                bang 55.4-55.4 !
              n-idprefixelement 55.5-55.6
                identifier 55.5-55.5 B
                bang 55.6-55.6 !
            n-infixop 55.7-55.7 #
          n-opargs 55.8-55.13
            lbr 55.8-55.8 (
            n-generalid 55.9-55.9
              n-idprefix ~ N_IdPrefix
              identifier 55.9-55.9 x
            comma 55.10-55.10 ,
            n-generalid 55.12-55.12
              n-idprefix ~ N_IdPrefix
              identifier 55.12-55.12 y
            rbr 55.13-55.13 )
        comma 55.14-55.14 ,
        n-opapplication 56.3-56.18
          n-generalid 56.3-56.12
            n-idprefix 56.3-56.6
              n-idprefixelement 56.3-56.4
                identifier 56.3-56.3 A
                bang 56.4-56.4 !
              n-idprefixelement 56.5-56.6
                identifier 56.5-56.5 B
                bang 56.6-56.6 !
            n-infixop 56.7-56.12 \\notin
          n-opargs 56.13-56.18
            lbr 56.13-56.13 (
            n-generalid 56.14-56.14
              n-idprefix ~ N_IdPrefix
              identifier 56.14-56.14 x
            comma 56.15-56.15 ,
            n-generalid 56.17-56.17
              n-idprefix ~ N_IdPrefix
              identifier 56.17-56.17 y
            rbr 56.18-56.18 )
        comma 56.19-56.19 ,
        n-opapplication 57.3-57.15
          n-generalid 57.3-57.9
            n-idprefix 57.3-57.6
              n-idprefixelement 57.3-57.4
                identifier 57.3-57.3 A
                bang 57.4-57.4 !
              n-idprefixelement 57.5-57.6
                identifier 57.5-57.5 B
                bang 57.6-57.6 !
            n-infixop 57.7-57.9 (.)
          n-opargs 57.10-57.15
            lbr 57.10-57.10 (
            n-generalid 57.11-57.11
              n-idprefix ~ N_IdPrefix
              identifier 57.11-57.11 x
            comma 57.12-57.12 ,
            n-generalid 57.14-57.14
              n-idprefix ~ N_IdPrefix
              identifier 57.14-57.14 y
            rbr 57.15-57.15 )
        comma 57.16-57.16 ,
        n-opapplication 58.3-58.17
          n-generalid 58.3-58.11
            n-idprefix 58.3-58.6
              n-idprefixelement 58.3-58.4
                identifier 58.3-58.3 A
                bang 58.4-58.4 !
              n-idprefixelement 58.5-58.6
                identifier 58.5-58.5 B
                bang 58.6-58.6 !
            n-infixop 58.7-58.11 \\odot
          n-opargs 58.12-58.17
            lbr 58.12-58.12 (
            n-generalid 58.13-58.13
              n-idprefix ~ N_IdPrefix
              identifier 58.13-58.13 x
            comma 58.14-58.14 ,
            n-generalid 58.16-58.16
              n-idprefix ~ N_IdPrefix
              identifier 58.16-58.16 y
            rbr 58.17-58.17 )
        comma 58.18-58.18 ,
        n-opapplication 59.3-59.15
          n-generalid 59.3-59.9
            n-idprefix 59.3-59.6
              n-idprefixelement 59.3-59.4
                identifier 59.3-59.3 A
                bang 59.4-59.4 !
              n-idprefixelement 59.5-59.6
                identifier 59.5-59.5 B
                bang 59.6-59.6 !
            n-infixop 59.7-59.9 (-)
          n-opargs 59.10-59.15
            lbr 59.10-59.10 (
            n-generalid 59.11-59.11
              n-idprefix ~ N_IdPrefix
              identifier 59.11-59.11 x
            comma 59.12-59.12 ,
            n-generalid 59.14-59.14
              n-idprefix ~ N_IdPrefix
              identifier 59.14-59.14 y
            rbr 59.15-59.15 )
        comma 59.16-59.16 ,
        n-opapplication 60.3-60.19
          n-generalid 60.3-60.13
            n-idprefix 60.3-60.6
              n-idprefixelement 60.3-60.4
                identifier 60.3-60.3 A
                bang 60.4-60.4 !
              n-idprefixelement 60.5-60.6
                identifier 60.5-60.5 B
                bang 60.6-60.6 !
            n-infixop 60.7-60.13 \\ominus
          n-opargs 60.14-60.19
            lbr 60.14-60.14 (
            n-generalid 60.15-60.15
              n-idprefix ~ N_IdPrefix
              identifier 60.15-60.15 x
            comma 60.16-60.16 ,
            n-generalid 60.18-60.18
              n-idprefix ~ N_IdPrefix
              identifier 60.18-60.18 y
            rbr 60.19-60.19 )
        comma 60.20-60.20 ,
        n-opapplication 61.3-61.15
          n-generalid 61.3-61.9
            n-idprefix 61.3-61.6
              n-idprefixelement 61.3-61.4
                identifier 61.3-61.3 A
                bang 61.4-61.4 !
              n-idprefixelement 61.5-61.6
                identifier 61.5-61.5 B
                bang 61.6-61.6 !
            n-infixop 61.7-61.9 (+)
          n-opargs 61.10-61.15
            lbr 61.10-61.10 (
            n-generalid 61.11-61.11
              n-idprefix ~ N_IdPrefix
              identifier 61.11-61.11 x
            comma 61.12-61.12 ,
            n-generalid 61.14-61.14
              n-idprefix ~ N_IdPrefix
              identifier 61.14-61.14 y
            rbr 61.15-61.15 )
        comma 61.16-61.16 ,
        n-opapplication 62.3-62.18
          n-generalid 62.3-62.12
            n-idprefix 62.3-62.6
              n-idprefixelement 62.3-62.4
                identifier 62.3-62.3 A
                bang 62.4-62.4 !
              n-idprefixelement 62.5-62.6
                identifier 62.5-62.5 B
                bang 62.6-62.6 !
            n-infixop 62.7-62.12 \\oplus
          n-opargs 62.13-62.18
            lbr 62.13-62.13 (
            n-generalid 62.14-62.14
              n-idprefix ~ N_IdPrefix
              identifier 62.14-62.14 x
            comma 62.15-62.15 ,
            n-generalid 62.17-62.17
              n-idprefix ~ N_IdPrefix
              identifier 62.17-62.17 y
            rbr 62.18-62.18 )
        comma 62.19-62.19 ,
        n-opapplication 63.3-63.15
          n-generalid 63.3-63.9
            n-idprefix 63.3-63.6
              n-idprefixelement 63.3-63.4
                identifier 63.3-63.3 A
                bang 63.4-63.4 !
              n-idprefixelement 63.5-63.6
                identifier 63.5-63.5 B
                bang 63.6-63.6 !
            n-infixop 63.7-63.9 (/)
          n-opargs 63.10-63.15
            lbr 63.10-63.10 (
            n-generalid 63.11-63.11
              n-idprefix ~ N_IdPrefix
              identifier 63.11-63.11 x
            comma 63.12-63.12 ,
            n-generalid 63.14-63.14
              n-idprefix ~ N_IdPrefix
              identifier 63.14-63.14 y
            rbr 63.15-63.15 )
        comma 63.16-63.16 ,
        n-opapplication 64.3-64.19
          n-generalid 64.3-64.13
            n-idprefix 64.3-64.6
              n-idprefixelement 64.3-64.4
                identifier 64.3-64.3 A
                bang 64.4-64.4 !
              n-idprefixelement 64.5-64.6
                identifier 64.5-64.5 B
                bang 64.6-64.6 !
            n-infixop 64.7-64.13 \\oslash
          n-opargs 64.14-64.19
            lbr 64.14-64.14 (
            n-generalid 64.15-64.15
              n-idprefix ~ N_IdPrefix
              identifier 64.15-64.15 x
            comma 64.16-64.16 ,
            n-generalid 64.18-64.18
              n-idprefix ~ N_IdPrefix
              identifier 64.18-64.18 y
            rbr 64.19-64.19 )
        comma 64.20-64.20 ,
        n-opapplication 65.3-65.16
          n-generalid 65.3-65.10
            n-idprefix 65.3-65.6
              n-idprefixelement 65.3-65.4
                identifier 65.3-65.3 A
                bang 65.4-65.4 !
              n-idprefixelement 65.5-65.6
                identifier 65.5-65.5 B
                bang 65.6-65.6 !
            n-infixop 65.7-65.10 (\\X)
          n-opargs 65.11-65.16
            lbr 65.11-65.11 (
            n-generalid 65.12-65.12
              n-idprefix ~ N_IdPrefix
              identifier 65.12-65.12 x
            comma 65.13-65.13 ,
            n-generalid 65.15-65.15
              n-idprefix ~ N_IdPrefix
              identifier 65.15-65.15 y
            rbr 65.16-65.16 )
        comma 65.17-65.17 ,
        n-opapplication 66.3-66.19
          n-generalid 66.3-66.13
            n-idprefix 66.3-66.6
              n-idprefixelement 66.3-66.4
                identifier 66.3-66.3 A
                bang 66.4-66.4 !
              n-idprefixelement 66.5-66.6
                identifier 66.5-66.5 B
                bang 66.6-66.6 !
            n-infixop 66.7-66.13 \\otimes
          n-opargs 66.14-66.19
            lbr 66.14-66.14 (
            n-generalid 66.15-66.15
              n-idprefix ~ N_IdPrefix
              identifier 66.15-66.15 x
            comma 66.16-66.16 ,
            n-generalid 66.18-66.18
              n-idprefix ~ N_IdPrefix
              identifier 66.18-66.18 y
            rbr 66.19-66.19 )
        comma 66.20-66.20 ,
        n-opapplication 67.3-67.13
          n-generalid 67.3-67.7
            n-idprefix 67.3-67.6
              n-idprefixelement 67.3-67.4
                identifier 67.3-67.3 A
                bang 67.4-67.4 !
              n-idprefixelement 67.5-67.6
                identifier 67.5-67.5 B
                bang 67.6-67.6 !
            n-infixop 67.7-67.7 +
          n-opargs 67.8-67.13
            lbr 67.8-67.8 (
            n-generalid 67.9-67.9
              n-idprefix ~ N_IdPrefix
              identifier 67.9-67.9 x
            comma 67.10-67.10 ,
            n-generalid 67.12-67.12
              n-idprefix ~ N_IdPrefix
              identifier 67.12-67.12 y
            rbr 67.13-67.13 )
        comma 67.14-67.14 ,
        n-opapplication 68.3-68.16
          n-generalid 68.3-68.10
            n-idprefix 68.3-68.6
              n-idprefixelement 68.3-68.4
                identifier 68.3-68.3 A
                bang 68.4-68.4 !
              n-idprefixelement 68.5-68.6
                identifier 68.5-68.5 B
                bang 68.6-68.6 !
            n-infixop 68.7-68.10 -+->
          n-opargs 68.11-68.16
            lbr 68.11-68.11 (
            n-generalid 68.12-68.12
              n-idprefix ~ N_IdPrefix
              identifier 68.12-68.12 x
            comma 68.13-68.13 ,
            n-generalid 68.15-68.15
              n-idprefix ~ N_IdPrefix
              identifier 68.15-68.15 y
            rbr 68.16-68.16 )
        comma 68.17-68.17 ,
        n-opapplication 69.3-69.14
          n-generalid 69.3-69.8
            n-idprefix 69.3-69.6
              n-idprefixelement 69.3-69.4
                identifier 69.3-69.3 A
                bang 69.4-69.4 !
              n-idprefixelement 69.5-69.6
                identifier 69.5-69.5 B
                bang 69.6-69.6 !
            n-infixop 69.7-69.8 ++
          n-opargs 69.9-69.14
            lbr 69.9-69.9 (
            n-generalid 69.10-69.10
              n-idprefix ~ N_IdPrefix
              identifier 69.10-69.10 x
            comma 69.11-69.11 ,
            n-generalid 69.13-69.13
              n-idprefix ~ N_IdPrefix
              identifier 69.13-69.13 y
            rbr 69.14-69.14 )
        comma 69.15-69.15 ,
        n-opapplication 70.3-70.13
          n-generalid 70.3-70.7
            n-idprefix 70.3-70.6
              n-idprefixelement 70.3-70.4
                identifier 70.3-70.3 A
                bang 70.4-70.4 !
              n-idprefixelement 70.5-70.6
                identifier 70.5-70.5 B
                bang 70.6-70.6 !
            n-infixop 70.7-70.7 ^
          n-opargs 70.8-70.13
            lbr 70.8-70.8 (
            n-generalid 70.9-70.9
              n-idprefix ~ N_IdPrefix
              identifier 70.9-70.9 x
            comma 70.10-70.10 ,
            n-generalid 70.12-70.12
              n-idprefix ~ N_IdPrefix
              identifier 70.12-70.12 y
            rbr 70.13-70.13 )
        comma 70.14-70.14 ,
        n-opapplication 71.3-71.14
          n-generalid 71.3-71.8
            n-idprefix 71.3-71.6
              n-idprefixelement 71.3-71.4
                identifier 71.3-71.3 A
                bang 71.4-71.4 !
              n-idprefixelement 71.5-71.6
                identifier 71.5-71.5 B
                bang 71.6-71.6 !
            n-infixop 71.7-71.8 ^^
          n-opargs 71.9-71.14
            lbr 71.9-71.9 (
            n-generalid 71.10-71.10
              n-idprefix ~ N_IdPrefix
              identifier 71.10-71.10 x
            comma 71.11-71.11 ,
            n-generalid 71.13-71.13
              n-idprefix ~ N_IdPrefix
              identifier 71.13-71.13 y
            rbr 71.14-71.14 )
        comma 71.15-71.15 ,
        n-opapplication 72.3-72.17
          n-generalid 72.3-72.11
            n-idprefix 72.3-72.6
              n-idprefixelement 72.3-72.4
                identifier 72.3-72.3 A
                bang 72.4-72.4 !
              n-idprefixelement 72.5-72.6
                identifier 72.5-72.5 B
                bang 72.6-72.6 !
            n-infixop 72.7-72.11 \\prec
          n-opargs 72.12-72.17
            lbr 72.12-72.12 (
            n-generalid 72.13-72.13
              n-idprefix ~ N_IdPrefix
              identifier 72.13-72.13 x
            comma 72.14-72.14 ,
            n-generalid 72.16-72.16
              n-idprefix ~ N_IdPrefix
              identifier 72.16-72.16 y
            rbr 72.17-72.17 )
        comma 72.18-72.18 ,
        n-opapplication 73.3-73.19
          n-generalid 73.3-73.13
            n-idprefix 73.3-73.6
              n-idprefixelement 73.3-73.4
                identifier 73.3-73.3 A
                bang 73.4-73.4 !
              n-idprefixelement 73.5-73.6
                identifier 73.5-73.5 B
                bang 73.6-73.6 !
            n-infixop 73.7-73.13 \\preceq
          n-opargs 73.14-73.19
            lbr 73.14-73.14 (
            n-generalid 73.15-73.15
              n-idprefix ~ N_IdPrefix
              identifier 73.15-73.15 x
            comma 73.16-73.16 ,
            n-generalid 73.18-73.18
              n-idprefix ~ N_IdPrefix
              identifier 73.18-73.18 y
            rbr 73.19-73.19 )
        comma 73.20-73.20 ,
        n-opapplication 74.3-74.19
          n-generalid 74.3-74.13
            n-idprefix 74.3-74.6
              n-idprefixelement 74.3-74.4
                identifier 74.3-74.3 A
                bang 74.4-74.4 !
              n-idprefixelement 74.5-74.6
                identifier 74.5-74.5 B
                bang 74.6-74.6 !
            n-infixop 74.7-74.13 \\propto
          n-opargs 74.14-74.19
            lbr 74.14-74.14 (
            n-generalid 74.15-74.15
              n-idprefix ~ N_IdPrefix
              identifier 74.15-74.15 x
            comma 74.16-74.16 ,
            n-generalid 74.18-74.18
              n-idprefix ~ N_IdPrefix
              identifier 74.18-74.18 y
            rbr 74.19-74.19 )
        comma 74.20-74.20 ,
        n-opapplication 75.3-75.14
          n-generalid 75.3-75.8
            n-idprefix 75.3-75.6
              n-idprefixelement 75.3-75.4
                identifier 75.3-75.3 A
                bang 75.4-75.4 !
              n-idprefixelement 75.5-75.6
                identifier 75.5-75.5 B
                bang 75.6-75.6 !
            n-infixop 75.7-75.8 ??
          n-opargs 75.9-75.14
            lbr 75.9-75.9 (
            n-generalid 75.10-75.10
              n-idprefix ~ N_IdPrefix
              identifier 75.10-75.10 x
            comma 75.11-75.11 ,
            n-generalid 75.13-75.13
              n-idprefix ~ N_IdPrefix
              identifier 75.13-75.13 y
            rbr 75.14-75.14 )
        comma 75.15-75.15 ,
        n-opapplication 76.3-76.14
          n-generalid 76.3-76.8
            n-idprefix 76.3-76.6
              n-idprefixelement 76.3-76.4
                identifier 76.3-76.3 A
                bang 76.4-76.4 !
              n-idprefixelement 76.5-76.6
                identifier 76.5-76.5 B
                bang 76.6-76.6 !
            n-infixop 76.7-76.8 |=
          n-opargs 76.9-76.14
            lbr 76.9-76.9 (
            n-generalid 76.10-76.10
              n-idprefix ~ N_IdPrefix
              identifier 76.10-76.10 x
            comma 76.11-76.11 ,
            n-generalid 76.13-76.13
              n-idprefix ~ N_IdPrefix
              identifier 76.13-76.13 y
            rbr 76.14-76.14 )
        comma 76.15-76.15 ,
        n-opapplication 77.3-77.14
          n-generalid 77.3-77.8
            n-idprefix 77.3-77.6
              n-idprefixelement 77.3-77.4
                identifier 77.3-77.3 A
                bang 77.4-77.4 !
              n-idprefixelement 77.5-77.6
                identifier 77.5-77.5 B
                bang 77.6-77.6 !
            n-infixop 77.7-77.8 |-
          n-opargs 77.9-77.14
            lbr 77.9-77.9 (
            n-generalid 77.10-77.10
              n-idprefix ~ N_IdPrefix
              identifier 77.10-77.10 x
            comma 77.11-77.11 ,
            n-generalid 77.13-77.13
              n-idprefix ~ N_IdPrefix
              identifier 77.13-77.13 y
            rbr 77.14-77.14 )
        comma 77.15-77.15 ,
        n-opapplication 78.3-78.13
          n-generalid 78.3-78.7
            n-idprefix 78.3-78.6
              n-idprefixelement 78.3-78.4
                identifier 78.3-78.3 A
                bang 78.4-78.4 !
              n-idprefixelement 78.5-78.6
                identifier 78.5-78.5 B
                bang 78.6-78.6 !
            n-infixop 78.7-78.7 \\
          n-opargs 78.8-78.13
            lbr 78.8-78.8 (
            n-generalid 78.9-78.9
              n-idprefix ~ N_IdPrefix
              identifier 78.9-78.9 x
            comma 78.10-78.10 ,
            n-generalid 78.12-78.12
              n-idprefix ~ N_IdPrefix
              identifier 78.12-78.12 y
            rbr 78.13-78.13 )
        comma 78.14-78.14 ,
        n-opapplication 79.3-79.16
          n-generalid 79.3-79.10
            n-idprefix 79.3-79.6
              n-idprefixelement 79.3-79.4
                identifier 79.3-79.3 A
                bang 79.4-79.4 !
              n-idprefixelement 79.5-79.6
                identifier 79.5-79.5 B
                bang 79.6-79.6 !
            n-infixop 79.7-79.10 \\sim
          n-opargs 79.11-79.16
            lbr 79.11-79.11 (
            n-generalid 79.12-79.12
              n-idprefix ~ N_IdPrefix
              identifier 79.12-79.12 x
            comma 79.13-79.13 ,
            n-generalid 79.15-79.15
              n-idprefix ~ N_IdPrefix
              identifier 79.15-79.15 y
            rbr 79.16-79.16 )
        comma 79.17-79.17 ,
        n-opapplication 80.3-80.18
          n-generalid 80.3-80.12
            n-idprefix 80.3-80.6
              n-idprefixelement 80.3-80.4
                identifier 80.3-80.3 A
                bang 80.4-80.4 !
              n-idprefixelement 80.5-80.6
                identifier 80.5-80.5 B
                bang 80.6-80.6 !
            n-infixop 80.7-80.12 \\simeq
          n-opargs 80.13-80.18
            lbr 80.13-80.13 (
            n-generalid 80.14-80.14
              n-idprefix ~ N_IdPrefix
              identifier 80.14-80.14 x
            comma 80.15-80.15 ,
            n-generalid 80.17-80.17
              n-idprefix ~ N_IdPrefix
              identifier 80.17-80.17 y
            rbr 80.18-80.18 )
        comma 80.19-80.19 ,
        n-opapplication 81.3-81.13
          n-generalid 81.3-81.7
            n-idprefix 81.3-81.6
              n-idprefixelement 81.3-81.4
                identifier 81.3-81.3 A
                bang 81.4-81.4 !
              n-idprefixelement 81.5-81.6
                identifier 81.5-81.5 B
                bang 81.6-81.6 !
            n-infixop 81.7-81.7 /
          n-opargs 81.8-81.13
            lbr 81.8-81.8 (
            n-generalid 81.9-81.9
              n-idprefix ~ N_IdPrefix
              identifier 81.9-81.9 x
            comma 81.10-81.10 ,
            n-generalid 81.12-81.12
              n-idprefix ~ N_IdPrefix
              identifier 81.12-81.12 y
            rbr 81.13-81.13 )
        comma 81.14-81.14 ,
        n-opapplication 82.3-82.14
          n-generalid 82.3-82.8
            n-idprefix 82.3-82.6
              n-idprefixelement 82.3-82.4
                identifier 82.3-82.3 A
                bang 82.4-82.4 !
              n-idprefixelement 82.5-82.6
                identifier 82.5-82.5 B
                bang 82.6-82.6 !
            n-infixop 82.7-82.8 //
          n-opargs 82.9-82.14
            lbr 82.9-82.9 (
            n-generalid 82.10-82.10
              n-idprefix ~ N_IdPrefix
              identifier 82.10-82.10 x
            comma 82.11-82.11 ,
            n-generalid 82.13-82.13
              n-idprefix ~ N_IdPrefix
              identifier 82.13-82.13 y
            rbr 82.14-82.14 )
        comma 82.15-82.15 ,
        n-opapplication 83.3-83.18
          n-generalid 83.3-83.12
            n-idprefix 83.3-83.6
              n-idprefixelement 83.3-83.4
                identifier 83.3-83.3 A
                bang 83.4-83.4 !
              n-idprefixelement 83.5-83.6
                identifier 83.5-83.5 B
                bang 83.6-83.6 !
            n-infixop 83.7-83.12 \\sqcap
          n-opargs 83.13-83.18
            lbr 83.13-83.13 (
            n-generalid 83.14-83.14
              n-idprefix ~ N_IdPrefix
              identifier 83.14-83.14 x
            comma 83.15-83.15 ,
            n-generalid 83.17-83.17
              n-idprefix ~ N_IdPrefix
              identifier 83.17-83.17 y
            rbr 83.18-83.18 )
        comma 83.19-83.19 ,
        n-opapplication 84.3-84.18
          n-generalid 84.3-84.12
            n-idprefix 84.3-84.6
              n-idprefixelement 84.3-84.4
                identifier 84.3-84.3 A
                bang 84.4-84.4 !
              n-idprefixelement 84.5-84.6
                identifier 84.5-84.5 B
                bang 84.6-84.6 !
            n-infixop 84.7-84.12 \\sqcup
          n-opargs 84.13-84.18
            lbr 84.13-84.13 (
            n-generalid 84.14-84.14
              n-idprefix ~ N_IdPrefix
              identifier 84.14-84.14 x
            comma 84.15-84.15 ,
            n-generalid 84.17-84.17
              n-idprefix ~ N_IdPrefix
              identifier 84.17-84.17 y
            rbr 84.18-84.18 )
        comma 84.19-84.19 ,
        n-opapplication 85.3-85.21
          n-generalid 85.3-85.15
            n-idprefix 85.3-85.6
              n-idprefixelement 85.3-85.4
                identifier 85.3-85.3 A
                bang 85.4-85.4 !
              n-idprefixelement 85.5-85.6
                identifier 85.5-85.5 B
                bang 85.6-85.6 !
            n-infixop 85.7-85.15 \\sqsubset
          n-opargs 85.16-85.21
            lbr 85.16-85.16 (
            n-generalid 85.17-85.17
              n-idprefix ~ N_IdPrefix
              identifier 85.17-85.17 x
            comma 85.18-85.18 ,
            n-generalid 85.20-85.20
              n-idprefix ~ N_IdPrefix
              identifier 85.20-85.20 y
            rbr 85.21-85.21 )
        comma 85.22-85.22 ,
        n-opapplication 86.3-86.23
          n-generalid 86.3-86.17
            n-idprefix 86.3-86.6
              n-idprefixelement 86.3-86.4
                identifier 86.3-86.3 A
                bang 86.4-86.4 !
              n-idprefixelement 86.5-86.6
                identifier 86.5-86.5 B
                bang 86.6-86.6 !
            n-infixop 86.7-86.17 \\sqsubseteq
          n-opargs 86.18-86.23
            lbr 86.18-86.18 (
            n-generalid 86.19-86.19
              n-idprefix ~ N_IdPrefix
              identifier 86.19-86.19 x
            comma 86.20-86.20 ,
            n-generalid 86.22-86.22
              n-idprefix ~ N_IdPrefix
              identifier 86.22-86.22 y
            rbr 86.23-86.23 )
        comma 86.24-86.24 ,
        n-opapplication 87.3-87.21
          n-generalid 87.3-87.15
            n-idprefix 87.3-87.6
              n-idprefixelement 87.3-87.4
                identifier 87.3-87.3 A
                bang 87.4-87.4 !
              n-idprefixelement 87.5-87.6
                identifier 87.5-87.5 B
                bang 87.6-87.6 !
            n-infixop 87.7-87.15 \\sqsupset
          n-opargs 87.16-87.21
            lbr 87.16-87.16 (
            n-generalid 87.17-87.17
              n-idprefix ~ N_IdPrefix
              identifier 87.17-87.17 x
            comma 87.18-87.18 ,
            n-generalid 87.20-87.20
              n-idprefix ~ N_IdPrefix
              identifier 87.20-87.20 y
            rbr 87.21-87.21 )
        comma 87.22-87.22 ,
        n-opapplication 88.3-88.23
          n-generalid 88.3-88.17
            n-idprefix 88.3-88.6
              n-idprefixelement 88.3-88.4
                identifier 88.3-88.3 A
                bang 88.4-88.4 !
              n-idprefixelement 88.5-88.6
                identifier 88.5-88.5 B
                bang 88.6-88.6 !
            n-infixop 88.7-88.17 \\sqsupseteq
          n-opargs 88.18-88.23
            lbr 88.18-88.18 (
            n-generalid 88.19-88.19
              n-idprefix ~ N_IdPrefix
              identifier 88.19-88.19 x
            comma 88.20-88.20 ,
            n-generalid 88.22-88.22
              n-idprefix ~ N_IdPrefix
              identifier 88.22-88.22 y
            rbr 88.23-88.23 )
        comma 88.24-88.24 ,
        n-opapplication 89.3-89.17
          n-generalid 89.3-89.11
            n-idprefix 89.3-89.6
              n-idprefixelement 89.3-89.4
                identifier 89.3-89.3 A
                bang 89.4-89.4 !
              n-idprefixelement 89.5-89.6
                identifier 89.5-89.5 B
                bang 89.6-89.6 !
            n-infixop 89.7-89.11 \\star
          n-opargs 89.12-89.17
            lbr 89.12-89.12 (
            n-generalid 89.13-89.13
              n-idprefix ~ N_IdPrefix
              identifier 89.13-89.13 x
            comma 89.14-89.14 ,
            n-generalid 89.16-89.16
              n-idprefix ~ N_IdPrefix
              identifier 89.16-89.16 y
            rbr 89.17-89.17 )
        comma 89.18-89.18 ,
        n-opapplication 90.3-90.19
          n-generalid 90.3-90.13
            n-idprefix 90.3-90.6
              n-idprefixelement 90.3-90.4
                identifier 90.3-90.3 A
                bang 90.4-90.4 !
              n-idprefixelement 90.5-90.6
                identifier 90.5-90.5 B
                bang 90.6-90.6 !
            n-infixop 90.7-90.13 \\subset
          n-opargs 90.14-90.19
            lbr 90.14-90.14 (
            n-generalid 90.15-90.15
              n-idprefix ~ N_IdPrefix
              identifier 90.15-90.15 x
            comma 90.16-90.16 ,
            n-generalid 90.18-90.18
              n-idprefix ~ N_IdPrefix
              identifier 90.18-90.18 y
            rbr 90.19-90.19 )
        comma 90.20-90.20 ,
        n-opapplication 91.3-91.21
          n-generalid 91.3-91.15
            n-idprefix 91.3-91.6
              n-idprefixelement 91.3-91.4
                identifier 91.3-91.3 A
                bang 91.4-91.4 !
              n-idprefixelement 91.5-91.6
                identifier 91.5-91.5 B
                bang 91.6-91.6 !
            n-infixop 91.7-91.15 \\subseteq
          n-opargs 91.16-91.21
            lbr 91.16-91.16 (
            n-generalid 91.17-91.17
              n-idprefix ~ N_IdPrefix
              identifier 91.17-91.17 x
            comma 91.18-91.18 ,
            n-generalid 91.20-91.20
              n-idprefix ~ N_IdPrefix
              identifier 91.20-91.20 y
            rbr 91.21-91.21 )
        comma 91.22-91.22 ,
        n-opapplication 92.3-92.17
          n-generalid 92.3-92.11
            n-idprefix 92.3-92.6
              n-idprefixelement 92.3-92.4
                identifier 92.3-92.3 A
                bang 92.4-92.4 !
              n-idprefixelement 92.5-92.6
                identifier 92.5-92.5 B
                bang 92.6-92.6 !
            n-infixop 92.7-92.11 \\succ
          n-opargs 92.12-92.17
            lbr 92.12-92.12 (
            n-generalid 92.13-92.13
              n-idprefix ~ N_IdPrefix
              identifier 92.13-92.13 x
            comma 92.14-92.14 ,
            n-generalid 92.16-92.16
              n-idprefix ~ N_IdPrefix
              identifier 92.16-92.16 y
            rbr 92.17-92.17 )
        comma 92.18-92.18 ,
        n-opapplication 93.3-93.19
          n-generalid 93.3-93.13
            n-idprefix 93.3-93.6
              n-idprefixelement 93.3-93.4
                identifier 93.3-93.3 A
                bang 93.4-93.4 !
              n-idprefixelement 93.5-93.6
                identifier 93.5-93.5 B
                bang 93.6-93.6 !
            n-infixop 93.7-93.13 \\succeq
          n-opargs 93.14-93.19
            lbr 93.14-93.14 (
            n-generalid 93.15-93.15
              n-idprefix ~ N_IdPrefix
              identifier 93.15-93.15 x
            comma 93.16-93.16 ,
            n-generalid 93.18-93.18
              n-idprefix ~ N_IdPrefix
              identifier 93.18-93.18 y
            rbr 93.19-93.19 )
        comma 93.20-93.20 ,
        n-opapplication 94.3-94.19
          n-generalid 94.3-94.13
            n-idprefix 94.3-94.6
              n-idprefixelement 94.3-94.4
                identifier 94.3-94.3 A
                bang 94.4-94.4 !
              n-idprefixelement 94.5-94.6
                identifier 94.5-94.5 B
                bang 94.6-94.6 !
            n-infixop 94.7-94.13 \\supset
          n-opargs 94.14-94.19
            lbr 94.14-94.14 (
            n-generalid 94.15-94.15
              n-idprefix ~ N_IdPrefix
              identifier 94.15-94.15 x
            comma 94.16-94.16 ,
            n-generalid 94.18-94.18
              n-idprefix ~ N_IdPrefix
              identifier 94.18-94.18 y
            rbr 94.19-94.19 )
        comma 94.20-94.20 ,
        n-opapplication 95.3-95.21
          n-generalid 95.3-95.15
            n-idprefix 95.3-95.6
              n-idprefixelement 95.3-95.4
                identifier 95.3-95.3 A
                bang 95.4-95.4 !
              n-idprefixelement 95.5-95.6
                identifier 95.5-95.5 B
                bang 95.6-95.6 !
            n-infixop 95.7-95.15 \\supseteq
          n-opargs 95.16-95.21
            lbr 95.16-95.16 (
            n-generalid 95.17-95.17
              n-idprefix ~ N_IdPrefix
              identifier 95.17-95.17 x
            comma 95.18-95.18 ,
            n-generalid 95.20-95.20
              n-idprefix ~ N_IdPrefix
              identifier 95.20-95.20 y
            rbr 95.21-95.21 )
        comma 95.22-95.22 ,
        n-opapplication 96.3-96.14
          n-generalid 96.3-96.8
            n-idprefix 96.3-96.6
              n-idprefixelement 96.3-96.4
                identifier 96.3-96.3 A
                bang 96.4-96.4 !
              n-idprefixelement 96.5-96.6
                identifier 96.5-96.5 B
                bang 96.6-96.6 !
            n-infixop 96.7-96.8 \\X
          n-opargs 96.9-96.14
            lbr 96.9-96.9 (
            n-generalid 96.10-96.10
              n-idprefix ~ N_IdPrefix
              identifier 96.10-96.10 x
            comma 96.11-96.11 ,
            n-generalid 96.13-96.13
              n-idprefix ~ N_IdPrefix
              identifier 96.13-96.13 y
            rbr 96.14-96.14 )
        comma 96.15-96.15 ,
        n-opapplication 97.3-97.18
          n-generalid 97.3-97.12
            n-idprefix 97.3-97.6
              n-idprefixelement 97.3-97.4
                identifier 97.3-97.3 A
                bang 97.4-97.4 !
              n-idprefixelement 97.5-97.6
                identifier 97.5-97.5 B
                bang 97.6-97.6 !
            n-infixop 97.7-97.12 \\times
          n-opargs 97.13-97.18
            lbr 97.13-97.13 (
            n-generalid 97.14-97.14
              n-idprefix ~ N_IdPrefix
              identifier 97.14-97.14 x
            comma 97.15-97.15 ,
            n-generalid 97.17-97.17
              n-idprefix ~ N_IdPrefix
              identifier 97.17-97.17 y
            rbr 97.18-97.18 )
        comma 97.19-97.19 ,
        n-opapplication 98.3-98.18
          n-generalid 98.3-98.12
            n-idprefix 98.3-98.6
              n-idprefixelement 98.3-98.4
                identifier 98.3-98.3 A
                bang 98.4-98.4 !
              n-idprefixelement 98.5-98.6
                identifier 98.5-98.5 B
                bang 98.6-98.6 !
            n-infixop 98.7-98.12 \\uplus
          n-opargs 98.13-98.18
            lbr 98.13-98.13 (
            n-generalid 98.14-98.14
              n-idprefix ~ N_IdPrefix
              identifier 98.14-98.14 x
            comma 98.15-98.15 ,
            n-generalid 98.17-98.17
              n-idprefix ~ N_IdPrefix
              identifier 98.17-98.17 y
            rbr 98.18-98.18 )
        comma 98.19-98.19 ,
        n-opapplication 99.3-99.13
          n-generalid 99.3-99.7
            n-idprefix 99.3-99.6
              n-idprefixelement 99.3-99.4
                identifier 99.3-99.3 A
                bang 99.4-99.4 !
              n-idprefixelement 99.5-99.6
                identifier 99.5-99.5 B
                bang 99.6-99.6 !
            n-infixop 99.7-99.7 |
          n-opargs 99.8-99.13
            lbr 99.8-99.8 (
            n-generalid 99.9-99.9
              n-idprefix ~ N_IdPrefix
              identifier 99.9-99.9 x
            comma 99.10-99.10 ,
            n-generalid 99.12-99.12
              n-idprefix ~ N_IdPrefix
              identifier 99.12-99.12 y
            rbr 99.13-99.13 )
        comma 99.14-99.14 ,
        n-opapplication 100.3-100.14
          n-generalid 100.3-100.8
            n-idprefix 100.3-100.6
              n-idprefixelement 100.3-100.4
                identifier 100.3-100.3 A
                bang 100.4-100.4 !
              n-idprefixelement 100.5-100.6
                identifier 100.5-100.5 B
                bang 100.6-100.6 !
            n-infixop 100.7-100.8 ||
          n-opargs 100.9-100.14
            lbr 100.9-100.9 (
            n-generalid 100.10-100.10
              n-idprefix ~ N_IdPrefix
              identifier 100.10-100.10 x
            comma 100.11-100.11 ,
            n-generalid 100.13-100.13
              n-idprefix ~ N_IdPrefix
              identifier 100.13-100.13 y
            rbr 100.14-100.14 )
        comma 100.15-100.15 ,
        n-opapplication 101.3-101.15
          n-generalid 101.3-101.9
            n-idprefix 101.3-101.6
              n-idprefixelement 101.3-101.4
                identifier 101.3-101.3 A
                bang 101.4-101.4 !
              n-idprefixelement 101.5-101.6
                identifier 101.5-101.5 B
                bang 101.6-101.6 !
            n-infixop 101.7-101.9 \\wr
          n-opargs 101.10-101.15
            lbr 101.10-101.10 (
            n-generalid 101.11-101.11
              n-idprefix ~ N_IdPrefix
              identifier 101.11-101.11 x
            comma 101.12-101.12 ,
            n-generalid 101.14-101.14
              n-idprefix ~ N_IdPrefix
              identifier 101.14-101.14 y
            rbr 101.15-101.15 )
        rbc 102.1-102.1 }
  n-endmodule 103.1-103.4
    end-module 103.1-103.4 ====
```

### postfix-op-000
```
---- MODULE Test ----

x^+ == 1
x^* == 2
x^# == 3
x' == 4

====
---
ACCEPT
n-module 1.1-8.4
  n-beginmodule 1.1-1.21
    bm1 1.1-1.11 ---- MODULE
    identifier 1.13-1.16 Test
    separator 1.18-1.21 ----
  n-extends ~ N_Extends
  n-body 3.1-6.7
    n-operatordefinition 3.1-3.8
      n-postfixlhs 3.1-3.3
        identifier 3.1-3.1 x
        op-68 3.2-3.3 ^+
      def 3.5-3.6 ==
      n-number 3.8-3.8
        number-literal 3.8-3.8 1
    n-operatordefinition 4.1-4.8
      n-postfixlhs 4.1-4.3
        identifier 4.1-4.1 x
        op-69 4.2-4.3 ^*
      def 4.5-4.6 ==
      n-number 4.8-4.8
        number-literal 4.8-4.8 2
    n-operatordefinition 5.1-5.8
      n-postfixlhs 5.1-5.3
        identifier 5.1-5.1 x
        op-70 5.2-5.3 ^#
      def 5.5-5.6 ==
      n-number 5.8-5.8
        number-literal 5.8-5.8 3
    n-operatordefinition 6.1-6.7
      n-postfixlhs 6.1-6.2
        identifier 6.1-6.1 x
        op-57 6.2-6.2 '
      def 6.4-6.5 ==
      n-number 6.7-6.7
        number-literal 6.7-6.7 4
  n-endmodule 8.1-8.4
    end-module 8.1-8.4 ====
```

### prefix-op-000
```
---- MODULE Test ----

~x == 1
\lnot x == 2
\neg x == 3
UNION x == 4
SUBSET x == 5
DOMAIN x == 6
-. x == 7
ENABLED x == 8
UNCHANGED x == 9
[] x == 10
<> x == 11

====
---
ACCEPT
n-module 1.1-15.4
  n-beginmodule 1.1-1.21
    bm1 1.1-1.11 ---- MODULE
    identifier 1.13-1.16 Test
    separator 1.18-1.21 ----
  n-extends ~ N_Extends
  n-body 3.1-13.10
    n-operatordefinition 3.1-3.7
      n-prefixlhs 3.1-3.2
        op-58 3.1-3.1 ~
        identifier 3.2-3.2 x
      def 3.4-3.5 ==
      n-number 3.7-3.7
        number-literal 3.7-3.7 1
    n-operatordefinition 4.1-4.12
      n-prefixlhs 4.1-4.7
        op-26 4.1-4.5 \\lnot
        identifier 4.7-4.7 x
      def 4.9-4.10 ==
      n-number 4.12-4.12
        number-literal 4.12-4.12 2
    n-operatordefinition 5.1-5.11
      n-prefixlhs 5.1-5.6
        op-29 5.1-5.4 \\neg
        identifier 5.6-5.6 x
      def 5.8-5.9 ==
      n-number 5.11-5.11
        number-literal 5.11-5.11 3
    n-operatordefinition 6.1-6.12
      n-prefixlhs 6.1-6.7
        op-115 6.1-6.5 UNION
        identifier 6.7-6.7 x
      def 6.9-6.10 ==
      n-number 6.12-6.12
        number-literal 6.12-6.12 4
    n-operatordefinition 7.1-7.13
      n-prefixlhs 7.1-7.8
        op-114 7.1-7.6 SUBSET
        identifier 7.8-7.8 x
      def 7.10-7.11 ==
      n-number 7.13-7.13
        number-literal 7.13-7.13 5
    n-operatordefinition 8.1-8.13
      n-prefixlhs 8.1-8.8
        op-116 8.1-8.6 DOMAIN
        identifier 8.8-8.8 x
      def 8.10-8.11 ==
      n-number 8.13-8.13
        number-literal 8.13-8.13 6
    n-operatordefinition 9.1-9.9
      n-prefixlhs 9.1-9.4
        op-76 9.1-9.2 -.
        identifier 9.4-9.4 x
      def 9.6-9.7 ==
      n-number 9.9-9.9
        number-literal 9.9-9.9 7
    n-operatordefinition 10.1-10.14
      n-prefixlhs 10.1-10.9
        op-112 10.1-10.7 ENABLED
        identifier 10.9-10.9 x
      def 10.11-10.12 ==
      n-number 10.14-10.14
        number-literal 10.14-10.14 8
    n-operatordefinition 11.1-11.16
      n-prefixlhs 11.1-11.11
        op-113 11.1-11.9 UNCHANGED
        identifier 11.11-11.11 x
      def 11.13-11.14 ==
      n-number 11.16-11.16
        number-literal 11.16-11.16 9
    n-operatordefinition 12.1-12.10
      n-prefixlhs 12.1-12.4
        casesep 12.1-12.2 []
        identifier 12.4-12.4 x
      def 12.6-12.7 ==
      n-number 12.9-12.10
        number-literal 12.9-12.10 10
    n-operatordefinition 13.1-13.10
      n-prefixlhs 13.1-13.4
        op-61 13.1-13.2 <>
        identifier 13.4-13.4 x
      def 13.6-13.7 ==
      n-number 13.9-13.10
        number-literal 13.9-13.10 11
  n-endmodule 15.1-15.4
    end-module 15.1-15.4 ====
```

### operators-001
```
---- MODULE Test ----
op == -. (1)
op == - (1)
op == - 1 - 2
====
---
ACCEPT
n-module 1.1-5.4
  n-beginmodule 1.1-1.21
    bm1 1.1-1.11 ---- MODULE
    identifier 1.13-1.16 Test
    separator 1.18-1.21 ----
  n-extends ~ N_Extends
  n-body 2.1-4.13
    n-operatordefinition 2.1-2.12
      n-identlhs 2.1-2.2
        identifier 2.1-2.2 op
      def 2.4-2.5 ==
      n-opapplication 2.7-2.12
        n-generalid 2.7-2.8
          n-idprefix ~ N_IdPrefix
          n-nonexpprefixop 2.7-2.8 -.
        n-opargs 2.10-2.12
          lbr 2.10-2.10 (
          n-number 2.11-2.11
            number-literal 2.11-2.11 1
          rbr 2.12-2.12 )
    n-operatordefinition 3.1-3.11
      n-identlhs 3.1-3.2
        identifier 3.1-3.2 op
      def 3.4-3.5 ==
      n-prefixexpr 3.7-3.11
        n-geninfixop 3.7-3.7
          n-idprefix ~ N_IdPrefix
          n-infixop 3.7-3.7 -
        n-parenexpr 3.9-3.11
          lbr 3.9-3.9 (
          n-number 3.10-3.10
            number-literal 3.10-3.10 1
          rbr 3.11-3.11 )
    n-operatordefinition 4.1-4.13
      n-identlhs 4.1-4.2
        identifier 4.1-4.2 op
      def 4.4-4.5 ==
      n-infixexpr 4.7-4.13
        n-prefixexpr 4.7-4.9
          n-geninfixop 4.7-4.7
            n-idprefix ~ N_IdPrefix
            n-infixop 4.7-4.7 -
          n-number 4.9-4.9
            number-literal 4.9-4.9 1
        n-geninfixop 4.11-4.11
          n-idprefix ~ N_IdPrefix
          n-infixop 4.11-4.11 -
        n-number 4.13-4.13
          number-literal 4.13-4.13 2
  n-endmodule 5.1-5.4
    end-module 5.1-5.4 ====
```

### operators-002
```
---- MODULE Test ----
f(x, g(_, _), _+_, -._, _^+) == x
====
---
ACCEPT
n-module 1.1-3.4
  n-beginmodule 1.1-1.21
    bm1 1.1-1.11 ---- MODULE
    identifier 1.13-1.16 Test
    separator 1.18-1.21 ----
  n-extends ~ N_Extends
  n-body 2.1-2.33
    n-operatordefinition 2.1-2.33
      n-identlhs 2.1-2.28
        identifier 2.1-2.1 f
        lbr 2.2-2.2 (
        n-identdecl 2.3-2.3
          identifier 2.3-2.3 x
        comma 2.4-2.4 ,
        n-identdecl 2.6-2.12
          identifier 2.6-2.6 g
          lbr 2.7-2.7 (
          us 2.8-2.8 _
          comma 2.9-2.9 ,
          us 2.11-2.11 _
          rbr 2.12-2.12 )
        comma 2.13-2.13 ,
        n-infixdecl 2.15-2.17
          us 2.15-2.15 _
          n-infixop 2.16-2.16 +
          us 2.17-2.17 _
        comma 2.18-2.18 ,
        n-prefixdecl 2.20-2.22
          n-nonexpprefixop 2.20-2.21 -.
          us 2.22-2.22 _
        comma 2.23-2.23 ,
        n-postfixdecl 2.25-2.27
          us 2.25-2.25 _
          n-postfixop 2.26-2.27 ^+
        rbr 2.28-2.28 )
      def 2.30-2.31 ==
      n-generalid 2.33-2.33
        n-idprefix ~ N_IdPrefix
        identifier 2.33-2.33 x
  n-endmodule 3.1-3.4
    end-module 3.1-3.4 ====
```

### operators-003
```
---- MODULE Test ----
op == f(LAMBDA x, y : x + y, LAMBDA x : 0)
====
---
ACCEPT
n-module 1.1-3.4
  n-beginmodule 1.1-1.21
    bm1 1.1-1.11 ---- MODULE
    identifier 1.13-1.16 Test
    separator 1.18-1.21 ----
  n-extends ~ N_Extends
  n-body 2.1-2.42
    n-operatordefinition 2.1-2.42
      n-identlhs 2.1-2.2
        identifier 2.1-2.2 op
      def 2.4-2.5 ==
      n-opapplication 2.7-2.42
        n-generalid 2.7-2.7
          n-idprefix ~ N_IdPrefix
          identifier 2.7-2.7 f
        n-opargs 2.8-2.42
          lbr 2.8-2.8 (
          n-lambda 2.9-2.27
            lambda 2.9-2.14 LAMBDA
            identifier 2.16-2.16 x
            comma 2.17-2.17 ,
            identifier 2.19-2.19 y
            colon 2.21-2.21 :
            n-infixexpr 2.23-2.27
              n-generalid 2.23-2.23
                n-idprefix ~ N_IdPrefix
                identifier 2.23-2.23 x
              n-geninfixop 2.25-2.25
                n-idprefix ~ N_IdPrefix
                n-infixop 2.25-2.25 +
              n-generalid 2.27-2.27
                n-idprefix ~ N_IdPrefix
                identifier 2.27-2.27 y
          comma 2.28-2.28 ,
          n-lambda 2.30-2.41
            lambda 2.30-2.35 LAMBDA
            identifier 2.37-2.37 x
            colon 2.39-2.39 :
            n-number 2.41-2.41
              number-literal 2.41-2.41 0
          rbr 2.42-2.42 )
  n-endmodule 3.1-3.4
    end-module 3.1-3.4 ====
```

### number-000
```
---- MODULE Test ----
op == 12345
op == 12345.12345
====
---
ACCEPT
n-module 1.1-4.4
  n-beginmodule 1.1-1.21
    bm1 1.1-1.11 ---- MODULE
    identifier 1.13-1.16 Test
    separator 1.18-1.21 ----
  n-extends ~ N_Extends
  n-body 2.1-3.17
    n-operatordefinition 2.1-2.11
      n-identlhs 2.1-2.2
        identifier 2.1-2.2 op
      def 2.4-2.5 ==
      n-number 2.7-2.11
        number-literal 2.7-2.11 12345
    n-operatordefinition 3.1-3.17
      n-identlhs 3.1-3.2
        identifier 3.1-3.2 op
      def 3.4-3.5 ==
      n-real 3.7-3.17
        number-literal 3.7-3.11 12345
        dot 3.12-3.12 .
        number-literal 3.13-3.17 12345
  n-endmodule 4.1-4.4
    end-module 4.1-4.4 ====
```

### unit-001
```
---- MODULE Test ----
CONSTANT x, y, z
CONSTANTS f(_, _), _+_, -._, _^+
====
---
ACCEPT
n-module 1.1-4.4
  n-beginmodule 1.1-1.21
    bm1 1.1-1.11 ---- MODULE
    identifier 1.13-1.16 Test
    separator 1.18-1.21 ----
  n-extends ~ N_Extends
  n-body 2.1-3.32
    n-paramdeclaration 2.1-2.16
      n-consdecl 2.1-2.8
        constant 2.1-2.8 CONSTANT
      n-identdecl 2.10-2.10
        identifier 2.10-2.10 x
      comma 2.11-2.11 ,
      n-identdecl 2.13-2.13
        identifier 2.13-2.13 y
      comma 2.14-2.14 ,
      n-identdecl 2.16-2.16
        identifier 2.16-2.16 z
    n-paramdeclaration 3.1-3.32
      n-consdecl 3.1-3.9
        constant 3.1-3.9 CONSTANTS
      n-identdecl 3.11-3.17
        identifier 3.11-3.11 f
        lbr 3.12-3.12 (
        us 3.13-3.13 _
        comma 3.14-3.14 ,
        us 3.16-3.16 _
        rbr 3.17-3.17 )
      comma 3.18-3.18 ,
      n-infixdecl 3.20-3.22
        us 3.20-3.20 _
        n-infixop 3.21-3.21 +
        us 3.22-3.22 _
      comma 3.23-3.23 ,
      n-prefixdecl 3.25-3.27
        n-nonexpprefixop 3.25-3.26 -.
        us 3.27-3.27 _
      comma 3.28-3.28 ,
      n-postfixdecl 3.30-3.32
        us 3.30-3.30 _
        n-postfixop 3.31-3.32 ^+
  n-endmodule 4.1-4.4
    end-module 4.1-4.4 ====
```

### unit-004
```
---- MODULE Test ----
INSTANCE M WITH
  A <- a,
  SUBSET <- b,
  * <- c,
  ' <- d
====
---
ACCEPT
n-module 1.1-7.4
  n-beginmodule 1.1-1.21
    bm1 1.1-1.11 ---- MODULE
    identifier 1.13-1.16 Test
    separator 1.18-1.21 ----
  n-extends ~ N_Extends
  n-body 2.1-6.8
    n-instance 2.1-6.8
      n-nonlocalinstance 2.1-6.8
        instance 2.1-2.8 INSTANCE
        identifier 2.10-2.10 M
        with 2.12-2.15 WITH
        n-substitution 3.3-3.8
          identifier 3.3-3.3 A
          substitute 3.5-3.6 <-
          n-generalid 3.8-3.8
            n-idprefix ~ N_IdPrefix
            identifier 3.8-3.8 a
        comma 3.9-3.9 ,
        n-substitution 4.3-4.13
          n-nonexpprefixop 4.3-4.8 SUBSET
          substitute 4.10-4.11 <-
          n-generalid 4.13-4.13
            n-idprefix ~ N_IdPrefix
            identifier 4.13-4.13 b
        comma 4.14-4.14 ,
        n-substitution 5.3-5.8
          n-infixop 5.3-5.3 *
          substitute 5.5-5.6 <-
          n-generalid 5.8-5.8
            n-idprefix ~ N_IdPrefix
            identifier 5.8-5.8 c
        comma 5.9-5.9 ,
        n-substitution 6.3-6.8
          n-postfixop 6.3-6.3 '
          substitute 6.5-6.6 <-
          n-generalid 6.8-6.8
            n-idprefix ~ N_IdPrefix
            identifier 6.8-6.8 d
  n-endmodule 7.1-7.4
    end-module 7.1-7.4 ====
```

### unit-005
```
---- MODULE Test ----
LOCAL op == x
LOCAL f[x \in Nat] == x
LOCAL INSTANCE M
LOCAL M == INSTANCE M
====
---
ACCEPT
n-module 1.1-6.4
  n-beginmodule 1.1-1.21
    bm1 1.1-1.11 ---- MODULE
    identifier 1.13-1.16 Test
    separator 1.18-1.21 ----
  n-extends ~ N_Extends
  n-body 2.1-5.21
    n-operatordefinition 2.1-2.13
      local 2.1-2.5 LOCAL
      n-identlhs 2.7-2.8
        identifier 2.7-2.8 op
      def 2.10-2.11 ==
      n-generalid 2.13-2.13
        n-idprefix ~ N_IdPrefix
        identifier 2.13-2.13 x
    n-functiondefinition 3.1-3.23
      local 3.1-3.5 LOCAL
      identifier 3.7-3.7 f
      lsb 3.8-3.8 [
      n-quantbound 3.9-3.17
        identifier 3.9-3.9 x
        t-in 3.11-3.13 \\in
        n-generalid 3.15-3.17
          n-idprefix ~ N_IdPrefix
          identifier 3.15-3.17 Nat
      rsb 3.18-3.18 ]
      def 3.20-3.21 ==
      n-generalid 3.23-3.23
        n-idprefix ~ N_IdPrefix
        identifier 3.23-3.23 x
    n-instance 4.1-4.16
      local 4.1-4.5 LOCAL
      n-nonlocalinstance 4.7-4.16
        instance 4.7-4.14 INSTANCE
        identifier 4.16-4.16 M
    n-moduledefinition 5.1-5.21
      local 5.1-5.5 LOCAL
      n-identlhs 5.7-5.7
        identifier 5.7-5.7 M
      def 5.9-5.10 ==
      n-nonlocalinstance 5.12-5.21
        instance 5.12-5.19 INSTANCE
        identifier 5.21-5.21 M
  n-endmodule 6.1-6.4
    end-module 6.1-6.4 ====
```

### use-or-hide-000
```
---- MODULE Test ----
USE X, Y
HIDE X
HIDE Y
====
---
ACCEPT
n-module 1.1-5.4
  n-beginmodule 1.1-1.21
    bm1 1.1-1.11 ---- MODULE
    identifier 1.13-1.16 Test
    separator 1.18-1.21 ----
  n-extends ~ N_Extends
  n-body 2.1-4.6
    n-useorhide 2.1-2.8
      use 2.1-2.3 USE
      n-generalid 2.5-2.5
        n-idprefix ~ N_IdPrefix
        identifier 2.5-2.5 X
      comma 2.6-2.6 ,
      n-generalid 2.8-2.8
        n-idprefix ~ N_IdPrefix
        identifier 2.8-2.8 Y
    n-useorhide 3.1-3.6
      hide 3.1-3.4 HIDE
      n-generalid 3.6-3.6
        n-idprefix ~ N_IdPrefix
        identifier 3.6-3.6 X
    n-useorhide 4.1-4.6
      hide 4.1-4.4 HIDE
      n-generalid 4.6-4.6
        n-idprefix ~ N_IdPrefix
        identifier 4.6-4.6 Y
  n-endmodule 5.1-5.4
    end-module 5.1-5.4 ====
```

### subexpressions-000
```
---- MODULE Test ----
op == M!X!Y!Z
====
---
ACCEPT
n-module 1.1-3.4
  n-beginmodule 1.1-1.21
    bm1 1.1-1.11 ---- MODULE
    identifier 1.13-1.16 Test
    separator 1.18-1.21 ----
  n-extends ~ N_Extends
  n-body 2.1-2.13
    n-operatordefinition 2.1-2.13
      n-identlhs 2.1-2.2
        identifier 2.1-2.2 op
      def 2.4-2.5 ==
      n-generalid 2.7-2.13
        n-idprefix 2.7-2.12
          n-idprefixelement 2.7-2.8
            identifier 2.7-2.7 M
            bang 2.8-2.8 !
          n-idprefixelement 2.9-2.10
            identifier 2.9-2.9 X
            bang 2.10-2.10 !
          n-idprefixelement 2.11-2.12
            identifier 2.11-2.11 Y
            bang 2.12-2.12 !
        identifier 2.13-2.13 Z
  n-endmodule 3.1-3.4
    end-module 3.1-3.4 ====
```

### assume-001
```
---- MODULE Test ----
ASSUME a1 == TRUE
ASSUMPTION a2 == TRUE
AXIOM a3 == TRUE
====
---
ACCEPT
n-module 1.1-5.4
  n-beginmodule 1.1-1.21
    bm1 1.1-1.11 ---- MODULE
    identifier 1.13-1.16 Test
    separator 1.18-1.21 ----
  n-extends ~ N_Extends
  n-body 2.1-4.16
    n-assumption 2.1-2.17
      assume 2.1-2.6 ASSUME
      identifier 2.8-2.9 a1
      def 2.11-2.12 ==
      n-generalid 2.14-2.17
        n-idprefix ~ N_IdPrefix
        identifier 2.14-2.17 TRUE
    n-assumption 3.1-3.21
      assumption 3.1-3.10 ASSUMPTION
      identifier 3.12-3.13 a2
      def 3.15-3.16 ==
      n-generalid 3.18-3.21
        n-idprefix ~ N_IdPrefix
        identifier 3.18-3.21 TRUE
    n-assumption 4.1-4.16
      assumption 4.1-4.5 AXIOM
      identifier 4.7-4.8 a3
      def 4.10-4.11 ==
      n-generalid 4.13-4.16
        n-idprefix ~ N_IdPrefix
        identifier 4.13-4.16 TRUE
  n-endmodule 5.1-5.4
    end-module 5.1-5.4 ====
```

### labels-001
```
---- MODULE Test ----
op == \A a, b \in Nat : lbl(a, b) :: P(a, b)
====
---
ACCEPT
n-module 1.1-3.4
  n-beginmodule 1.1-1.21
    bm1 1.1-1.11 ---- MODULE
    identifier 1.13-1.16 Test
    separator 1.18-1.21 ----
  n-extends ~ N_Extends
  n-body 2.1-2.44
    n-operatordefinition 2.1-2.44
      n-identlhs 2.1-2.2
        identifier 2.1-2.2 op
      def 2.4-2.5 ==
      n-boundquant 2.7-2.44
        forall 2.7-2.8 \\A
        n-quantbound 2.10-2.21
          identifier 2.10-2.10 a
          comma 2.11-2.11 ,
          identifier 2.13-2.13 b
          t-in 2.15-2.17 \\in
          n-generalid 2.19-2.21
            n-idprefix ~ N_IdPrefix
            identifier 2.19-2.21 Nat
        colon 2.23-2.23 :
        n-label 2.25-2.44
          n-opapplication 2.25-2.33
            n-generalid 2.25-2.27
              n-idprefix ~ N_IdPrefix
              identifier 2.25-2.27 lbl
            n-opargs 2.28-2.33
              lbr 2.28-2.28 (
              n-generalid 2.29-2.29
                n-idprefix ~ N_IdPrefix
                identifier 2.29-2.29 a
              comma 2.30-2.30 ,
              n-generalid 2.32-2.32
                n-idprefix ~ N_IdPrefix
                identifier 2.32-2.32 b
              rbr 2.33-2.33 )
          coloncolon 2.35-2.36 ::
          n-opapplication 2.38-2.44
            n-generalid 2.38-2.38
              n-idprefix ~ N_IdPrefix
              identifier 2.38-2.38 P
            n-opargs 2.39-2.44
              lbr 2.39-2.39 (
              n-generalid 2.40-2.40
                n-idprefix ~ N_IdPrefix
                identifier 2.40-2.40 a
              comma 2.41-2.41 ,
              n-generalid 2.43-2.43
                n-idprefix ~ N_IdPrefix
                identifier 2.43-2.43 b
              rbr 2.44-2.44 )
  n-endmodule 3.1-3.4
    end-module 3.1-3.4 ====
```

### sets-001
```
---- MODULE Test ----

op == {x \in Nat}
op == {x \in BOOLEAN, y \in STRING}

====
---
ACCEPT
n-module 1.1-6.4
  n-beginmodule 1.1-1.21
    bm1 1.1-1.11 ---- MODULE
    identifier 1.13-1.16 Test
    separator 1.18-1.21 ----
  n-extends ~ N_Extends
  n-body 3.1-4.35
    n-operatordefinition 3.1-3.17
      n-identlhs 3.1-3.2
        identifier 3.1-3.2 op
      def 3.4-3.5 ==
      n-setenumerate 3.7-3.17
        lbc 3.7-3.7 {
        n-infixexpr 3.8-3.16
          n-generalid 3.8-3.8
            n-idprefix ~ N_IdPrefix
            identifier 3.8-3.8 x
          n-geninfixop 3.10-3.12
            n-idprefix ~ N_IdPrefix
            t-in 3.10-3.12 \\in
          n-generalid 3.14-3.16
            n-idprefix ~ N_IdPrefix
            identifier 3.14-3.16 Nat
        rbc 3.17-3.17 }
    n-operatordefinition 4.1-4.35
      n-identlhs 4.1-4.2
        identifier 4.1-4.2 op
      def 4.4-4.5 ==
      n-setenumerate 4.7-4.35
        lbc 4.7-4.7 {
        n-infixexpr 4.8-4.20
          n-generalid 4.8-4.8
            n-idprefix ~ N_IdPrefix
            identifier 4.8-4.8 x
          n-geninfixop 4.10-4.12
            n-idprefix ~ N_IdPrefix
            t-in 4.10-4.12 \\in
          n-generalid 4.14-4.20
            n-idprefix ~ N_IdPrefix
            identifier 4.14-4.20 BOOLEAN
        comma 4.21-4.21 ,
        n-infixexpr 4.23-4.34
          n-generalid 4.23-4.23
            n-idprefix ~ N_IdPrefix
            identifier 4.23-4.23 y
          n-geninfixop 4.25-4.27
            n-idprefix ~ N_IdPrefix
            n-infixop 4.25-4.27 \\in
          n-generalid 4.29-4.34
            n-idprefix ~ N_IdPrefix
            identifier 4.29-4.34 STRING
        rbc 4.35-4.35 }
  n-endmodule 6.1-6.4
    end-module 6.1-6.4 ====
```

### sets-006
```
---- MODULE Test ----
op == {f(x, y, z) : x \in Int, y, z \in Real}
====
---
ACCEPT
n-module 1.1-3.4
  n-beginmodule 1.1-1.21
    bm1 1.1-1.11 ---- MODULE
    identifier 1.13-1.16 Test
    separator 1.18-1.21 ----
  n-extends ~ N_Extends
  n-body 2.1-2.45
    n-operatordefinition 2.1-2.45
      n-identlhs 2.1-2.2
        identifier 2.1-2.2 op
      def 2.4-2.5 ==
      n-setofall 2.7-2.45
        lbc 2.7-2.7 {
        n-opapplication 2.8-2.17
          n-generalid 2.8-2.8
            n-idprefix ~ N_IdPrefix
            identifier 2.8-2.8 f
          n-opargs 2.9-2.17
            lbr 2.9-2.9 (
            n-generalid 2.10-2.10
              n-idprefix ~ N_IdPrefix
              identifier 2.10-2.10 x
            comma 2.11-2.11 ,
            n-generalid 2.13-2.13
              n-idprefix ~ N_IdPrefix
              identifier 2.13-2.13 y
            comma 2.14-2.14 ,
            n-generalid 2.16-2.16
              n-idprefix ~ N_IdPrefix
              identifier 2.16-2.16 z
            rbr 2.17-2.17 )
        colon 2.19-2.19 :
        n-quantbound 2.21-2.29
          identifier 2.21-2.21 x
          t-in 2.23-2.25 \\in
          n-generalid 2.27-2.29
            n-idprefix ~ N_IdPrefix
            identifier 2.27-2.29 Int
        comma 2.30-2.30 ,
        n-quantbound 2.32-2.44
          identifier 2.32-2.32 y
          comma 2.33-2.33 ,
          identifier 2.35-2.35 z
          t-in 2.37-2.39 \\in
          n-generalid 2.41-2.44
            n-idprefix ~ N_IdPrefix
            identifier 2.41-2.44 Real
        rbc 2.45-2.45 }
  n-endmodule 3.1-3.4
    end-module 3.1-3.4 ====
```
