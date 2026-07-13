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
--
