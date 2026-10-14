::  StandardModule override registry (unit 6C.1): module-qualified
::  resolution, override-beats-body, typed rejection of an unimplemented
::  standard operator, and evaluation of definitions imported via EXTENDS.
/+  *test
/=  ne  /lib/node-eval
/=  so  /lib/stdops
/=  v   /lib/value
|%
++  lines
  |=  ls=(list tape)
  ^-  tape
  %+  roll  (flop ls)
  |=([l=tape acc=tape] (weld (weld l "\0a") acc))
::
++  one
  ::  a single-module source: the EXTENDS line plus body lines
  |=  [ext=tape body=(list tape)]
  ^-  (map @t @t)
  =/  txt=@t
    %-  crip
    ;:  weld
      "---- MODULE A ----\0a"
      ?~(ext "" (weld ext "\0a"))
      (lines body)
      "====\0a"
    ==
  (malt ~[['A' txt]])
::
++  two
  ::  a root module A extending a user helper module H
  |=  [root=(list tape) helper=(list tape)]
  ^-  (map @t @t)
  =/  rt=@t
    (crip ;:(weld "---- MODULE A ----\0a" (lines root) "====\0a"))
  =/  hp=@t
    (crip ;:(weld "---- MODULE H ----\0a" (lines helper) "====\0a"))
  (malt ~[['A' rt] ['H' hp]])
::
++  bind
  |=  [src=(map @t @t) nm=@t ar=@ud want=?(%override %body %none %nograph)]
  ^-  tang
  (expect-eq !>(want) !>((binding-in:ne 'A' src nm ar)))
::
++  val
  ::  the rendered value of definition `nm`, or "ERR: <message>"
  |=  [src=(map @t @t) nm=@t want=tape]
  ^-  tang
  =/  r  (eval-module-def:ne 'A' src nm)
  =/  got  ?:(?=(%| -.r) (weld "ERR: " (trip msg.p.r)) (render:v p.r))
  (expect-eq !>(want) !>(got))
::
++  helper-src
  (two ~["EXTENDS H, Integers" "Expr == Twice(Lim)"] ~["EXTENDS Integers" "Lim == 4" "Twice(n) == 2 * n"])
::
::  +|  Module-Qualified Resolution
::
++  test-binding-plus
  ::  `+` binds to the Naturals override, not to a bare name
  (bind (one "EXTENDS Integers" ~["Expr == 1 + 2"]) '+' 2 %override)
::
++  test-binding-unary-minus
  ::  unary minus canonicalizes to `-.` (the pin's own name in Integers),
  ::  its own registry row, distinct from the binary `-` at arity 2 (R1.3.5.1)
  (bind (one "EXTENDS Integers" ~["Expr == -(1)"]) '-.' 1 %override)
::
++  test-binding-len
  (bind (one "EXTENDS Sequences" ~["Expr == Len(<<1>>)"]) 'Len' 1 %override)
::
++  test-binding-cardinality
  %-  bind
  ::  a double-quoted tape interpolates `{…}`, so the set literal is written
  ::  as an interval
  [(one "EXTENDS FiniteSets" ~["Expr == Cardinality(1..3)"]) 'Cardinality' 1 %override]
::
++  test-binding-unknown
  (bind (one "EXTENDS Integers" ~["Expr == 1"]) 'Zork' 0 %none)
::
::  +|  Override Beats Body; Unimplemented Standard Operators Are Typed
::
++  test-nat-is-not-its-dummy-body
  ::  Naturals.tla defines `Nat == { }` as a deliberate dummy for tools to
  ::  override. With no override in the registry the answer must be a typed
  ::  rejection naming the operator — never the empty set
  %-  val
  :+  (one "EXTENDS Naturals" ~["Expr == Nat"])
    'Expr'
  "ERR: unsupported StandardModule operator: Naturals!Nat/0"
::
++  test-nat-binding-override
  ::  C1.2 implements Nat as a set descriptor, so it binds to an override
  ::  (its value position is still a typed rejection — see tests/lib/arith)
  (bind (one "EXTENDS Naturals" ~["Expr == Nat"]) 'Nat' 0 %override)
::
++  test-plus-is-not-its-dummy-body
  ::  `a+b == {a, b}` in Naturals.tla; the override must win
  (val (one "EXTENDS Naturals" ~["Expr == 1 + 2"]) 'Expr' "3")
::
++  test-unimplemented-operator-names-itself
  ::  a declared-but-unimplemented StandardModule operator names itself
  ::  rather than evaluating its vendored body.
  ::
  ::  R2.7.6.0: this arm asserted RandomElement, which R2.7.4.4 IMPLEMENTED
  ::  -- the arm then read `1`, a drawn value, instead of the rejection.
  ::  JavaTime replaces it because it is excluded on WALL-CLOCK
  ::  NONDETERMINISM rather than on effort, so no later capability unit can
  ::  turn it green the way one turned RandomElement green.
  %-  val
  :+  (one "EXTENDS Integers, TLC" ~["Expr == JavaTime"])
    'Expr'
  "ERR: unsupported StandardModule operator: TLC!JavaTime/0"
::
::  +|  Body-Evaluable Standard Operators
::
++  test-subbag-binds-to-body
  ::  the pin does not override Bags!SubBag, so its vendored TLA+ definition
  ::  is the behavior (inventory.txt class `body`)
  (bind (one "EXTENDS Bags" ~["Expr == 1"]) 'SubBag' 1 %body)
::
++  test-bagin-binds-to-override
  ::  implemented in C1.4, so it binds to the registry rather than its body
  (bind (one "EXTENDS Bags" ~["Expr == 1"]) 'BagIn' 2 %override)
::
::  +|  User Definitions: Shadowing And EXTENDS Import
::
++  test-user-shadows-standard
  ::  a root definition of the same name is the root's own, so its body is
  ::  evaluated rather than the Sequences override
  %-  val
  :+  (one "EXTENDS Sequences" ~["Len(s) == 42" "Expr == Len(<<1, 2, 3>>)"])
    'Expr'
  "42"
::
++  test-user-shadow-binding
  %-  bind
  :^    (one "EXTENDS Sequences" ~["Len(s) == 42" "Expr == Len(<<1, 2>>)"])
      'Len'
    1
  %body
::
++  test-extends-imported-constant
  ::  the unit-7 finding: a definition imported through EXTENDS from a user
  ::  module was unreachable from the evaluator
  (val helper-src 'Expr' "8")
::
++  test-extends-imported-binding
  (bind helper-src 'Twice' 1 %body)
::
::  +|  Registry Shape
::
++  test-registry-rows-are-reachable
  ::  every table row is reachable through +lookup with its own key, so the
  ::  table and the resolution path cannot drift apart
  =/  s  make-senv:so
  =/  missing
    =/  ks  ~(tap in ~(key by registry:so))
    |-  ^-  (list op-key:so)
    ?~  ks  ~
    =/  hit  (lookup:so s i.ks)
    ?^  hit  $(ks t.ks)
    [i.ks $(ks t.ks)]
  (expect-eq !>(*(list op-key:so)) !>(missing))
::
++  test-registry-row-count
  ::  a drift alarm: the count changes only when a subunit adds operators
  ::  (C1.1 seeded 18, C1.3 added SubSeq, C1.4 added 11 Bags rows plus the
  ::  two TLC function constructors and moved Cardinality to a node-op,
  ::  C1.5 added the TLC value-shaped rows, C1.6 moved TLCGet to the
  ::  node-op table because the pin evaluates it lazily, R2.6.3 added
  ::  TLCExt!TLCNoOp -- its three siblings are node-ops, being `@Evaluation`
  ::  overrides, and AssertEq is a `body`).
  ::
  ::  R2.7.4.3 is the FIRST DECREMENT: TLCSet left the registry for the
  ::  node-op table, because writing the run-scoped register store needs the
  ::  carrier `rst` that a plain `(list value)` row cannot reach. 38 -> 37.
  ::  R2.7.10 adds TLCExt!TLCFP and TLCExt!TLCModelValue -- two of the three
  ::  surfaces the inventory carried as `later:`; the third,
  ::  TLCEvalDefinition, is an `@Evaluation` override and joins the node-op
  ::  table instead. 37 -> 39.
  ::  R4.2a: Print and PrintT leave for the node-op table -- they WRITE a line
  ::  on the carrier, as TLCSet writes a register. 39 -> 37.
  ::  R4.2f adds Json's three pure encoders (ToJson, ToJsonArray,
  ::  ToJsonObject); its two writers are node-ops. 37 -> 40. Its two readers
  ::  are typed refusals by name (approved difference). 40 -> 42.
  (expect-eq !>(42) !>(~(wyt by registry:so)))
--
