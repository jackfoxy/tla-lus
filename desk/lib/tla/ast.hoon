/-  *tla-lus
|%
  ::  SANY Concrete Syntax Tree
  ::
  ::  Mirrors tla2sany SyntaxTreeNode at the pinned commit: interior
  ::  nodes carry an N_* kind and heirs; leaves are lexer tokens. Node
  ::  locations are the lexicographic min-begin/max-end over heirs with
  ::  real locations; synthesized empty nodes have no location and dump
  ::  with their Java constant name as image, matching AstDump.java.
  ::
::  +|  Types
::
::  obelisk-style recursion: every type in the cycle is a named,
::  $+-annotated mold whose record uses the $:-with-%tag-head form.
::  Inline tagged tuples ([%tag ...]) in the cycle overflow the zuse-408
::  mold compiler in clay-built files; this exact shape compiles.
+$  syntax-leaf
  $+  syntax-leaf
  $:  %leaf
    =token
    ==
::  image: token text for token-derived childless nodes (N_String,
::  N_InfixOp, ...); Java constant name for synthesized empties;
::  unused when kids is nonempty
+$  syntax-interior
  $+  syntax-interior
  $:  %node
    kind=@tas
    at=(unit span)
    image=@t
    kids=(list syntax-node)
    ==
+$  syntax-node
  $+  syntax-node
  $%  syntax-interior
      syntax-leaf
  ==
::
::  +|  Kind Names (kebab kind -> Java constant, for empty-node images)
::
::
++  kind-names
  ^-  (map @tas @t)
  %-  malt
  ^-  (list [@tas @t])
  :~  [%n-actdecl 'N_ActDecl']
      [%n-actionexpr 'N_ActionExpr']
      [%n-assumedecl 'N_AssumeDecl']
      [%n-assumeprove 'N_AssumeProve']
      [%n-assumption 'N_Assumption']
      [%n-beginmodule 'N_BeginModule']
      [%n-body 'N_Body']
      [%n-boundquant 'N_BoundQuant']
      [%n-case 'N_Case']
      [%n-casearm 'N_CaseArm']
      [%n-conjitem 'N_ConjItem']
      [%n-conjlist 'N_ConjList']
      [%n-consdecl 'N_ConsDecl']
      [%n-disjitem 'N_DisjItem']
      [%n-disjlist 'N_DisjList']
      [%n-endmodule 'N_EndModule']
      [%n-except 'N_Except']
      [%n-exceptcomponent 'N_ExceptComponent']
      [%n-exceptspec 'N_ExceptSpec']
      [%n-times 'N_Times']
      [%n-extends 'N_Extends']
      [%n-fairnessexpr 'N_FairnessExpr']
      [%n-fcnappl 'N_FcnAppl']
      [%n-fcnconst 'N_FcnConst']
      [%n-fieldset 'N_FieldSet']
      [%n-fieldval 'N_FieldVal']
      [%n-functiondefinition 'N_FunctionDefinition']
      [%n-functionparam 'N_FunctionParam']
      [%n-generalid 'N_GeneralId']
      [%n-geninfixop 'N_GenInfixOp']
      [%n-gennonexpprefixop 'N_GenNonExpPrefixOp']
      [%n-genpostfixop 'N_GenPostfixOp']
      [%n-genprefixop 'N_GenPrefixOp']
      [%n-identdecl 'N_IdentDecl']
      [%n-real 'N_Real']
      [%n-identifier 'N_Identifier']
      [%n-identifiertuple 'N_IdentifierTuple']
      [%n-identlhs 'N_IdentLHS']
      [%n-idprefix 'N_IdPrefix']
      [%n-idprefixelement 'N_IdPrefixElement']
      [%n-ifthenelse 'N_IfThenElse']
      [%n-infixdecl 'N_InfixDecl']
      [%n-infixexpr 'N_InfixExpr']
      [%n-infixlhs 'N_InfixLHS']
      [%n-infixop 'N_InfixOp']
      [%n-innerproof 'N_InnerProof']
      [%n-instance 'N_Instance']
      [%n-nonlocalinstance 'N_NonLocalInstance']
      [%n-integer 'N_Integer']
      [%n-letdefinitions 'N_LetDefinitions']
      [%n-letin 'N_LetIn']
      [%n-maybebound 'N_MaybeBound']
      [%n-module 'N_Module']
      [%n-moduledefinition 'N_ModuleDefinition']
      [%n-nonexpprefixop 'N_NonExpPrefixOp']
      [%n-number 'N_Number']
      [%n-numberedassumeprove 'N_NumberedAssumeProve']
      [%n-opapplication 'N_OpApplication']
      [%n-opargs 'N_OpArgs']
      [%n-operatordefinition 'N_OperatorDefinition']
      [%n-otherarm 'N_OtherArm']
      [%n-paramdecl 'N_ParamDecl']
      [%n-paramdeclaration 'N_ParamDeclaration']
      [%n-parenexpr 'N_ParenExpr']
      [%n-postfixdecl 'N_PostfixDecl']
      [%n-postfixexpr 'N_PostfixExpr']
      [%n-postfixlhs 'N_PostfixLHS']
      [%n-postfixop 'N_PostfixOp']
      [%n-prefixdecl 'N_PrefixDecl']
      [%n-prefixexpr 'N_PrefixExpr']
      [%n-prefixlhs 'N_PrefixLHS']
      [%n-prefixop 'N_PrefixOp']
      [%n-proof 'N_Proof']
      [%n-proofstep 'N_ProofStep']
      [%n-qedstep 'N_QEDStep']
      [%n-quantbound 'N_QuantBound']
      [%n-rcdconstructor 'N_RcdConstructor']
      [%n-recordcomponent 'N_RecordComponent']
      [%n-setenumerate 'N_SetEnumerate']
      [%n-setexcept 'N_SetExcept']
      [%n-setofall 'N_SetOfAll']
      [%n-setoffcns 'N_SetOfFcns']
      [%n-setofrcds 'N_SetOfRcds']
      [%n-sexceptspec 'N_SExceptSpec']
      [%n-sfcndecl 'N_SFcnDecl']
      [%n-string 'N_String']
      [%n-subsetof 'N_SubsetOf']
      [%n-substitution 'N_Substitution']
      [%n-tempdecl 'N_TempDecl']
      [%n-theorem 'N_Theorem']
      [%n-tuple 'N_Tuple']
      [%n-unboundorboundchoose 'N_UnboundOrBoundChoose']
      [%n-unboundquant 'N_UnboundQuant']
      [%n-variabledeclaration 'N_VariableDeclaration']
      [%n-newsymb 'N_NewSymb']
      [%n-lambda 'N_Lambda']
      [%n-recursive 'N_Recursive']
      [%n-label 'N_Label']
      [%n-structop 'N_StructOp']
      [%n-numerablestep 'N_NumerableStep']
      [%n-terminalproof 'N_TerminalProof']
      [%n-useorhide 'N_UseOrHide']
      [%n-nonexprbody 'N_NonExprBody']
      [%n-defstep 'N_DefStep']
      [%n-havestep 'N_HaveStep']
      [%n-takestep 'N_TakeStep']
      [%n-witnessstep 'N_WitnessStep']
      [%n-pickstep 'N_PickStep']
      [%n-casestep 'N_CaseStep']
      [%n-assertstep 'N_AssertStep']
  ==
::
::  +|  Construction
::
::
++  leaf
  |=  tok=token
  ^-  syntax-node
  [%leaf tok]
::
++  span-of
  |=  n=syntax-node
  ^-  (unit span)
  ?-  -.n
    %leaf  `span.token.n
    %node  at.n
  ==
::
++  mk-node
  ::  interior node; location = lexicographic min/max over located kids
  |=  [kind=@tas kids=(list syntax-node)]
  ^-  syntax-node
  =/  spans  (murn kids span-of)
  =/  at=(unit span)
    ?~  spans  ~
    =/  first  i.spans
    :-  ~
    %+  roll  `(list span)`t.spans
    |=  [s=span acc=_first]
    ^-  span
    :-  ?:  (pos-lth from.s from.acc)  from.s
        from.acc
    ?:  (pos-gth to.s to.acc)  to.s
    to.acc
  [%node kind at (~(gut by kind-names) kind '?') kids]
::
++  tok-node
  ::  token-derived node (kind overridden, image = token text)
  |=  [kind=@tas tok=token]
  ^-  syntax-node
  [%node kind `span.tok text.tok ~]
::
++  pos-lth
  |=  [a=pos b=pos]
  ^-  ?
  ?:  =(line.a line.b)  (lth col.a col.b)
  (lth line.a line.b)
::
++  pos-gth
  |=  [a=pos b=pos]
  ^-  ?
  ?:  =(line.a line.b)  (gth col.a col.b)
  (gth line.a line.b)
::
::  +|  Differential Dump (AstDump.java format)
::
::
++  dec-tape
  |=  n=@ud
  ^-  tape
  ?:  =(0 n)  "0"
  =|  out=tape
  |-
  ?:  =(0 n)  out
  $(n (div n 10), out [(add '0' (mod n 10)) out])
::
++  esc-image
  |=  t=@t
  ^-  tape
  %-  zing
  %+  turn  (trip t)
  |=  c=@tD
  ^-  tape
  ?:  =('\\' c)   "\\\\"
  ?:  =('\0a' c)  "\\n"
  ?:  =('\0d' c)  "\\r"
  ?:  =('\09' c)  "\\t"
  ?:  =('\0c' c)  "\\f"
  [c ~]
::
++  span-tape
  |=  sp=span
  ^-  tape
  ;:  welp
    (dec-tape line.from.sp)  "."  (dec-tape col.from.sp)
    "-"
    (dec-tape line.to.sp)  "."  (dec-tape col.to.sp)
  ==
::
++  dump-node
  ::  preorder lines, two-space indent per depth
  |=  n=syntax-node
  ^-  wain
  =|  out=(list @t)
  =/  stack=(list [d=@ud n=syntax-node])  [0 n]~
  |-
  ?~  stack  (flop out)
  =/  [d=@ud x=syntax-node]  i.stack
  =/  indent  (reap (mul 2 d) ' ')
  =/  line
    ?-    -.x
        %leaf
      %-  crip
      ;:  welp
        indent
        (trip kind.token.x)
        " "
        (span-tape span.token.x)
        " "
        (esc-image text.token.x)
      ==
    ::
        %node
      %-  crip
      ;:  welp
        indent
        (trip kind.x)
        " "
        ?~(at.x "~" (span-tape u.at.x))
        ?.  =(~ kids.x)  ""
        (welp " " (esc-image image.x))
      ==
    ==
  =/  more
    ?-  -.x
      %leaf  ~
      %node  (turn kids.x |=(k=syntax-node [+(d) k]))
    ==
  $(stack (weld more t.stack), out [line out])
--
