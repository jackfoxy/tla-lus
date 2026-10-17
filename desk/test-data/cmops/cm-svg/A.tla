---- MODULE A ----
EXTENDS Naturals, Sequences, SVG
Ring0 == NodeOfRingNetwork(10, 10, 5, 0, 4)
Ring1 == NodeOfRingNetwork(10, 10, 5, 1, 4)
Ring3 == NodeOfRingNetwork(100, 100, 50, 3, 7)
POL == PointOnLine([x |-> 0, y |-> 0], [x |-> 10, y |-> 20], 2)
ElemStr == SVGElemToString(Rect(1, 2, 3, 4, [fill |-> "red"]))
GroupStr == SVGElemToString(Group(<<Circle(5, 5, 2, <<>>), Text(0, 0, "hi", <<>>)>>, <<>>))
====
