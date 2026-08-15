/-  *tla-lus
|%
  ::  Deterministic Ordering For Public Nouns
  ::
  ::  Owns the ordering contracts declared in /sur/tla-lus. Every place
  ::  the agent or a differential test emits a collection with no
  ::  inherent order must sort with these gates.
  ::
::  +|  Position Order
::
::
++  pos-lte
  |=  [a=pos b=pos]
  ^-  ?
  ?:  =(line.a line.b)  (lte col.a col.b)
  (lth line.a line.b)
::
++  span-lte
  |=  [a=span b=span]
  ^-  ?
  ?:  =(from.a from.b)  (pos-lte to.a to.b)
  (pos-lte from.a from.b)
::
++  loc-lte
  ::  source name alphabetically, then span
  |=  [a=loc b=loc]
  ^-  ?
  ?:  =(src.a src.b)  (span-lte span.a span.b)
  (aor src.a src.b)
::
::  +|  Diagnostic Order
::
::
++  family-rank
  |=  f=code-family
  ^-  @ud
  ?-  f
    %sany  0
    %pcal  1
    %tlc   2
    %lus   3
  ==
::
++  diag-lte
  ::  global diagnostics (at=~) first; then location, family, number,
  ::  message
  |=  [a=diagnostic b=diagnostic]
  ^-  ?
  ?:  &(?=(~ at.a) ?=(^ at.b))  &
  ?:  &(?=(^ at.a) ?=(~ at.b))  |
  ?:  ?&  ?=(^ at.a)  ?=(^ at.b)
          !=(u.at.a u.at.b)
      ==
    (loc-lte u.at.a u.at.b)
  ?.  =((family-rank family.code.a) (family-rank family.code.b))
    (lth (family-rank family.code.a) (family-rank family.code.b))
  ?.  =(num.code.a num.code.b)
    (lth num.code.a num.code.b)
  (aor message.a message.b)
::
++  sort-diags
  |=  ds=(list diagnostic)
  ^-  (list diagnostic)
  (sort ds diag-lte)
::
::  +|  Trace Binding Order
::
::
++  sort-bindings
  ::  alphabetical by variable name
  |=  bs=(list binding)
  ^-  (list binding)
  %+  sort  bs
  |=([a=binding b=binding] (aor var.a var.b))
::
::  +|  TLC Output Rendering (tlc2.output.MP.getMessage, R1.3.5.7.2)
::
::    Byte-exact port of MP.getMessage(class, code, params, tool) over the
::    reachable EC set (see parity-manifest `tlc-output-ec`). Message classes:
::    NONE=0 ERROR=1 TLCBUG=2 WARNING=3.
::
++  mp-replace
  ::  replace every occurrence of `nee` in `hay` with `rep`
  |=  [hay=tape nee=tape rep=tape]
  ^-  tape
  =/  nl  (lent nee)
  |-  ^-  tape
  =/  ix  (find nee hay)
  ?~  ix  hay
  ;:  weld
    (scag u.ix hay)  rep  $(hay (slag (add u.ix nl) hay))
  ==
::
++  mp-subst
  ::  MP.replaceString: replace %<i>% (all occurrences) with the i-th param,
  ::  i ascending
  |=  [tmpl=@t params=(list @t)]
  ^-  @t
  =/  i=@ud  1
  =/  t=tape  (trip tmpl)
  |-  ^-  @t
  ?~  params  (crip t)
  =/  ph=tape  :(weld "%" (a-co:co i) "%")
  $(t (mp-replace t ph (trip i.params)), params t.params, i +(i))
::
++  temporal-many
  ::  MP TLC_TEMPORAL_PROPERTY_VIOLATED with >1 property: builds the
  ::  "Temporal properties %1%, %2%, and %3% were violated.\n" template
  |=  n=@ud
  ^-  @t
  =/  i=@ud  1
  =/  parts=tape  ""
  |-  ^-  @t
  ?:  (gth i n)
    (crip :(weld "Temporal properties " parts " were violated.\0a"))
  =/  sep=tape
    ?:  =(i 1)  ""
    ?:  (lth i n)  ", "
    ?:(=(n 2) " and " ", and ")
  $(parts :(weld parts sep "%" (a-co:co i) "%"), i +(i))
::
++  ec-body
  ::  getMessage0(code, params) with %N% substitution; arity-dependent codes
  ::  branch on the param count
  |=  [code=@ud params=(list @t)]
  ^-  @t
  =/  n  (lent params)
  ?+    code  ~|([%unmapped-ec code] !!)
      %2.104  (mp-subst 'Assumption %1% is false.' params)
      %2.105  (mp-subst 'Evaluating assumption %1% failed.\0a%2%' params)
      %2.107  (mp-subst 'Invariant %1% is violated by the initial state:\0a%2%' params)
      %2.110  (mp-subst 'Invariant %1% is violated.' params)
      %2.116
    ?:  =(n 1)  (mp-subst 'Temporal property %1% was violated.\0a' params)
    ?:  =(n 0)  'Temporal properties were violated.\0a'
    (mp-subst (temporal-many n) params)
      %2.222  (mp-subst 'The constant parameter %1% is not assigned a value by the configuration file.' params)
      %2.227  'The configuration file cannot specify both INIT/NEXT and SPECIFICATION fields.'
      %2.228
    ?:  =(n 2)  (mp-subst 'TLC requires %1% not to take any argument, but one was given: %2%' params)
    (mp-subst 'TLC requires %1% not to take any argument.' params)
      %2.229  (mp-subst 'The %1% %2% specified in the configuration file\0ais not defined in the specification.' params)
      %2.230  (mp-subst 'The %1% of %2% is equal to %3%' params)
      %2.231  'The configuration file did not specify the initial state predicate.'
      %2.232  'The configuration file did not specify the next state predicate.'
      %2.233  (mp-subst 'The %1% %2% cannot be a constant.' params)
      %2.237  (mp-subst 'The spec is trivially false because %1% is false.' params)
      %2.257  'The stuttering counterexample above may be caused by the absence of a behavior specification (SPECIFICATION). Only INIT and NEXT have been provided, so TLC permits infinite stuttering. To rule out such counterexamples, use SPECIFICATION Spec, with Spec asserting a suitable fairness constraint (compare Chapter 8, page 87ff of Specifying Systems at https://lamport.azurewebsites.net/tla/book.html).'
      %2.259  (mp-subst 'The stuttering counterexample above may be caused by the absence of a fairness constraint in the behavior specification %1% defined at %2%. To rule out such counterexamples, conjoin a suitable fairness constraint to %1% (compare Chapter 8, page 87ff of Specifying Systems at https://lamport.azurewebsites.net/tla/book.html).' params)
      %2.272  (mp-subst 'The formula %1% at %2% is an action-level formula (i.e., it contains no temporal operators). Only temporal-level (or state-level) formulas are allowed under PROPERTY or PROPERTIES. To check that action %1% holds in *every* step of the behavior, define a temporal property: Let A be the formula at %2%; rewrite A as [][A]_v, where v is a state function (typically the tuple of variables) (compare page 90 of Specifying Systems at https://lamport.azurewebsites.net/tla/book.html).' params)
      %2.279  'Declaring symmetry during liveness checking is dangerous. It might cause TLC to miss violations of the stated liveness properties. Please check liveness without symmetry defined.'
      %2.281  (mp-subst 'The configuration file substitutes constant %1% with non-constant %2%%3%' params)
      %5.001  (mp-subst 'TLC encountered the following error when trying to read the configuration file %1%:\0a%2%' params)
      %5.002  (mp-subst 'TLC found an error in the configuration file at line %1%\0a' params)
      %5.003  (mp-subst 'TLC found an error in the configuration file at line %1%\0aThe keyword %2% was not followed by an identifier.' params)
      %5.004  (mp-subst 'TLC found an error in the configuration file at line %1%\0aThe keyword %2% appeared twice.' params)
      %5.005  (mp-subst 'TLC found an error in the configuration file at line %1%\0aExpected an identifier after %2%.' params)
      %5.006  (mp-subst 'TLC found an error in the configuration file at line %1%\0aIt was expecting %2%, but did not find it.' params)
  ==
::
++  mp-class-prefix
  |=  class=@ud
  ^-  @t
  ?+  class  ''
    %1  'Error: '
    %2  'TLC Bug: '
    %3  'Warning: '
  ==
::
++  severity-class
  ::  MP message class for a diagnostic severity (NONE=0 ERROR=1 WARNING=3)
  |=  s=severity
  ^-  @ud
  ?-  s
    %error    1
    %warning  3
    %info     0
  ==
::
++  diag-render
  ::  serialize a typed `diagnostic` to its MP.getMessage line (R1.3.5.7.3):
  ::  `message` already holds the getMessage0 body, so plain adds the class
  ::  prefix (+ a WARNING -nowarning hint) and tool wraps it in the
  ::  @!@!@STARTMSG/ENDMSG frame with the code:class.  The structured noun is
  ::  the port's primary machine contract; this is the on-demand text form.
  |=  [d=diagnostic tool=?]
  ^-  @t
  =/  cls   (severity-class severity.d)
  =/  code  num.code.d
  ?.  tool
    =/  hint=@t
      ?:  =(cls 3)  '\0a(Use the -nowarning option to disable this warning.)'
      ''
    (rap 3 ~[(mp-class-prefix cls) message.d hint])
  %-  crip
  ;:  weld
    "@!@!@STARTMSG "  (a-co:co code)  ":"  (a-co:co cls)  " @!@!@\0a"
    (trip message.d)
    "\0a@!@!@ENDMSG "  (a-co:co code)  " @!@!@"
  ==
::
++  mp-message
  ::  MP.getMessage: tool=%.y renders the @!@!@STARTMSG/ENDMSG machine
  ::  wrapper, %.n the class prefix + body
  |=  [class=@ud code=@ud params=(list @t) tool=?]
  ^-  @t
  =/  body  (ec-body code params)
  ?.  tool
    ::  non-tool post-processing: a WARNING appends the -nowarning hint
    ::  (MP warningHistory.isEmpty, always true for a standalone render)
    =/  hint=@t
      ?:  =(class 3)
        '\0a(Use the -nowarning option to disable this warning.)'
      ''
    (rap 3 ~[(mp-class-prefix class) body hint])
  %-  crip
  ;:  weld
    "@!@!@STARTMSG "  (a-co:co code)  ":"  (a-co:co class)  " @!@!@\0a"
    (trip body)
    "\0a@!@!@ENDMSG "  (a-co:co code)  " @!@!@"
  ==
--
