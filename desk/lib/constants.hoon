|%
::  Hoon port of util.TLAConstants (PORT-COMPLETION-PLAN-2 R1.3.5.7.1).
::
::  The authoritative, single-source mirror of the Java class's shared
::  literals, byte-exact at the pinned commit (tlaplus@4ba7d8811). Ports the
::  IN-SCOPE members (section/module keywords, built-in module + operator
::  names, base TLA syntax literals) that the ported tla2sany+tlc2-core
::  surface uses; consumers reference these arms rather than re-typing the
::  literal.
::
::  ACCOUNTING — TLAConstants members NOT ported (out of scope, no consumer
::  in the ported surface; the pcal/Toolbox/CLI-driver exclusion boundary):
::    - ANSI            terminal color codes (CLI pretty-printing)
::    - Files           MC.tla/MC.cfg/.err/.out generation (Toolbox driver)
::    - Schemes         Toolbox model-value naming schemes (spec/init/...)
::    - TraceExplore    trace-explorer module/variable naming (Toolbox)
::    - LoggingAtoms    "Parsing file" progress log atom (CLI driver)
::  plus the top-level Toolbox-only formatting atoms (BACK_TO_STATE,
::  GENERATION_TIMESTAMP_PREFIX, MODULE_*_REGEX, INDENTED_*, TRACE_NA, ...).
::  Every remaining TLAConstants member is ported below.
::
::  +|  KeyWords  (TLAConstants.KeyWords)
::
++  action-constraint  'ACTION_CONSTRAINT'
++  assume  'ASSUME'
++  constant  'CONSTANT'
++  constants  'CONSTANTS'
++  extends  'EXTENDS'
++  init  'INIT'
++  invariant  'INVARIANT'
++  module  'MODULE'
++  next  'NEXT'
++  property  'PROPERTY'
++  specification  'SPECIFICATION'
++  symmetry  'SYMMETRY'
++  variable  'VARIABLE'
++  enabled  'ENABLED'
++  view  'VIEW'
++  union  '\\union'
::
::  +|  BuiltInModules / BuiltInOperators
::
++  tlc  'TLC'
++  trace-expressions  'Toolbox'
++  permutations  'Permutations'
::
::  +|  Base literals  (TLAConstants top level)
::
++  space  ' '
++  indent  '    '
++  cr  '\0a'
++  sep  '----'
++  eq  ' = '
++  arrow  ' <- '
++  record-arrow  ' |-> '
++  defines  ' == '
++  comment-ns  '\\*'
++  comment  '\\* '
++  attribute  '@'
++  colon  ':'
++  empty-string  ''
++  comma  ','
++  begin-tuple  '<<'
++  end-tuple  '>>'
++  prime  '\''
++  quote  '"'
++  tla-and  '/\\'
++  tla-or  '\\/'
++  tla-not  '~'
++  tla-eventually-always  '<>[]'
++  tla-inf-often  '[]<>'
++  l-paren  '('
++  r-paren  ')'
++  l-square-bracket  '['
++  r-square-bracket  ']'
++  true  'TRUE'
++  false  'FALSE'
++  line  'line '
++  stuttering  ' Stuttering'
--
