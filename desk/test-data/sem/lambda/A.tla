---- MODULE A ----
Apply(P(_)) == P(0)
Apply2(Q(_, _)) == Q(0, 1)
Foo == Apply(LAMBDA y : y = 1)
Bar == Apply2(LAMBDA a, b : a = b)
====
