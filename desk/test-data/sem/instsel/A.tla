---- MODULE A ----
Foo == INSTANCE B WITH D <- 42
Ref == Foo!Thm2!:
Ref2 == Foo!Thm2!<<
Ref3 == Foo!Op(7)!>>
====
