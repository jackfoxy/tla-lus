---- MODULE A ----
EXTENDS Naturals, DyadicRationals
AddH == Add(Half(One), Half(Half(One)))
AddZ == Add(Zero, Half(One))
AddOne == Add(Half(One), Half(One))
HalfOne == Half(One)
IsD == IsDyadicRational(Half(One))
====
