---------------------------- MODULE A ----------------------------
(* R4.4 fixture: the ASCII spellings tlauc rewrites, original text *)
EXTENDS Naturals, Sequences, FiniteSets
CONSTANT S
VARIABLES x, y

B ≜ INSTANCE B WITH c ← S

TypeOK ≜ ∧ x ∈ SUBSET S
         ∧ y ∈ Seq(S) × Nat
         ∧ ∀ e ∈ x : e ∉ {}

Sets ≜ (x ∪ {}) ∩ (S \ {}) ⊆ S ∧ ({} ⊆ S ∨ TRUE)

Logic(p, q) ≜ (p ⇒ q) ∧ (¬p ⇔ ¬¬p) ∧ (p ≡ p) ∧ (p ≠ q)

Cmp(a, b) ≜ ∧ a ≤ b
            ∧ b ≥ a
            ∧ a ≤ b
            ∧ a ≤ b ∨ a ≥ b
            ∧ ∨ a < b
              ∨ a > b
              ∨ a ≠ b

Tup ≜ ⟨ 1, ⟨2, 3⟩ ⟩ ∘ ⟨4⟩

F ≜ [e ∈ S ↦ e]

G ≜ [S → S]

H ≜ ∃ e ∈ S : ∀ f ∈ S : e = f

Init ≜ x = {} ∧ y = ⟨ ⟨⟩, 0 ⟩

Next ≜ ∧ x' = x
       ∧ UNCHANGED y

Spec ≜ Init ∧ □[Next]_⟨x, y⟩ ∧ WF_⟨x, y⟩(Next)

Live ≜ ◇□(x = {}) ∧ □◇(x = {}) ∧ ((x = {}) ↝ (x = {}))

Arrow ≜ (x = {}) ⇸ (x = {})

Range ≜ 1‥3

Lam ≜ LET Twice(a) ≜ a + a IN Twice(1)

THEOREM Thm ≜ TypeOK ⇒ TRUE
====================================================================
