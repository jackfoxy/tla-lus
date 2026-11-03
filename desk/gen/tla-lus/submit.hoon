::  :tla-lus|submit ~.job-1 %check
::
::  Submits a demo inline request with default limits; the op argument
::  selects translate, analyze, or check.
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
=/  demo-text  '---- MODULE Demo ----\0a====\0a'
:^    %submit
    id
  op
::  request tail is [src limits write promote env props]
[[%inline 'Demo' (malt ~[['Demo' demo-text]]) ~] default-limits:job-lib ~ ~ ~ ~]
