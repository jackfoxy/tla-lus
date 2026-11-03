# TestGraphs: five evaluator defects behind one model (2026-10-13)

TLC/TestGraphs (`INSTANCE TLCMC WITH ...`, an unnamed instance of a
PlusCal-translated module) failed in turn on each of these. Each is general.

1. **A LAMBDA substituted for an operator constant** (`WITH Constraint <-
   LAMBDA s, l : TRUE`) was generated as a plain expression, so the constant
   stayed unbound (`undefined identifier: Constraint`). SANY builds an
   OpArgNode over a synthesized LAMBDA (SemDump `oparg LAMBDA`); `+g-instance`
   now does (`+lambda-of`). mc `inst-lambda-subst`, sem `inst-lambda`.
2. **Name capture by an INSTANCE substitution.** The port binds both an
   operator's parameters and an instance's substitutions BY NAME; tlc2
   resolves a name by its node. TLCMC declares `SuccessorsOf(state, SG)` and
   `SeqToSet(seq) == {seq[i] : i \in ...}` BEFORE `VARIABLES state, i`, and the
   unnamed instance substitutes `state <- state`, `i <- i`:
   - a bound variable `i` read the state variable (`variable is unassigned
     in the current state: i`) -> a binder (`+bind-group`, `+bind-names`) and a
     value parameter (`+bind-params`) now shadow a call-by-name entry;
   - the member's body is its `WITH` wrapper, bound AFTER the parameters, so
     `SuccessorsOf(8, G)` read the CURRENT `state` -> `+keep-params`
     re-asserts the operator's own parameters over its wrapper's bindings (in
     `+eval-user` and the solver's user-operator path).
   The search diverged silently before (1,794 vs 1,790 states on one
   action set); now equal. mc `inst-param-capture`.
3. **`UNCHANGED vars` through an instance wrapper** dropped every variable
   (`incomplete next state`) -> `+unchanged-vars` maps the wrapper's
   substitutions.
4. **`TLCGet("level")` in a CONSTRAINT read 0**, so such a constraint pruned
   nothing (found while bisecting with one). Constraints and action
   constraints now evaluate with the run (`level` = the checked state's
   level, measured: `TLCGet("level") < 4` keeps 3 states). mc
   `tlcget-level-constraint`.
5. **A definition reaching `TLCGet` was constant-cached** by `+with-cdefs`
   (SANY gives it level 0; tlc2's level bound takes the override's
   `minLevel` 1) -> `+reaches-run-op` excludes it.

Result: TestGraphs' safety part (`SPECIFICATION Spec` alone, single-file copy)
is 2,790 / 2,590 / 51 = the pin. With its PROPERTIES one job slice exhausted
the loom and took the ship down -> R4.2ap. Also found: a bound variable that
redeclares an earlier VARIABLE in an inner module is accepted where SANY
reports 4201 -> R4.2ar.

Debugging aid used: the R4.2a `Print` channel. `PrintT(ToString(<<vars>>))`
as an invariant dumps every reached state into the job's `%output`
artifact (tools: `tla-zod-tools/probe-out.py`), diffable against the pin's
output of the same spec.
