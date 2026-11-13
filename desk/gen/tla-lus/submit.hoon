::  :tla-lus|submit ~.job-1 %check     (from the %tla-lus desk: =dir /=tla-lus=)
::
::  Submits a demo inline request with default limits; the op argument
::  selects translate, analyze, or check. The demo is a four-state counter
::  with its config, so %check runs to `%ok` (5 generated, 4 distinct,
::  depth 4); read it with +tla-lus/status ~.job-1
::
/-  *tla-lus
/=  job-lib  /lib/job
:-  %say
|=  [* [id=@ta kind=?(%translate %analyze %check) ~] ~]
:-  %tla-lus-action
^-  action
=/  =op
  ?-  kind
    %translate  [%translate [%none | &]]
    %analyze    [%analyze [& & & &]]
    ::  check-opts is [translate view difftrace continue cfg coverage
    ::  postconditions mode]; translate=& is a typed rejection at submit
    %check      [%check [| | | | ~ | ~ [%exhaustive & 0]]]
  ==
=/  demo-text=@t
  %-  crip
  ;:  weld
    "---- MODULE Demo ----\0aEXTENDS Naturals\0aVARIABLE x\0a"
    "Init == x = 0\0aNext == x' = (x + 1) % 4\0aInv == x < 4\0a====\0a"
  ==
=/  demo-cfg=@t  'INIT Init\0aNEXT Next\0aINVARIANT Inv\0a'
:^    %submit
    id
  op
::  request tail is [src limits write promote env props]
:-  [%inline 'Demo' (malt ~[['Demo' demo-text]]) `demo-cfg]
[default-limits:job-lib ~ ~ ~ ~]
