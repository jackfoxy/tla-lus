::  the %hoon mark (base's, minus its html view): a Clay-built desk needs
::  it to cast every `.hoon` file it holds. The desk lacked it and worked
::  only on a desk created from %base
|_  own=@t
++  grow
  |%
  ++  mime  `^mime`[/text/x-hoon (as-octs:mimes:html own)]
  ++  txt   (to-wain:format own)
  --
++  grab
  |%
  ++  mime  |=([p=mite q=octs] q.q)
  ++  noun  @t
  ++  txt   of-wain:format
  --
++  grad  %txt
--
