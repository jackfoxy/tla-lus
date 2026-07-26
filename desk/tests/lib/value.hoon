::  Smoke test for the canonical TLC value layer (unit 6.1).
::
::  Only a single value-typed expression: the zuse-408 mull has a very low
::  budget for the recursive `value` mold inside an external test core (more
::  than ~1-2 value constructions overflows it), so value.hoon is exercised
::  comprehensively two other ways instead — direct dojo evaluation, and the
::  differential EvalDump path once the semantic evaluator renders values to
::  text (unit 6.5). Production evaluation lives in a single core, so values
::  never cross a boundary there.
/+  *test
/=  v  /lib/value
|%
++  test-value-render-smoke
  (expect-eq !>("42") !>((render:v (vin:v 42))))
--
