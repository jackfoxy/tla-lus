# R3.2a — a record IS a function

```text
Sub-unit: R3.2a
Row: tlc-value-composite -> back to `parity`
Planned: add `%rec` to `+fcn-like`/`+fcn-pairs` (the easy half), then measure
  `+fp-enc` and `+normalize` alongside `+equal-norm` because equal values must
  fingerprint equal or every `distinct` count moves.
Found: the risk that made this its own unit DOES NOT EXIST -- the fingerprint
  encoder was right from the start -- and the fix was four lines away from a
  helper that already had it right. Measuring first is what kept it small.
```

## 1. The fix, and where it already existed

`+fcn-like` was `?=(?(%fcn %seq) -.v)` — a tuple counts as a function, a record
does not — so `+equal-norm` never took the function path for a record and
`[a |-> 1] = ("a" :> 1)` was FALSE where the pin says TRUE.

`+fcn-like` now admits `%rec` and `+fcn-pairs` has a record case:
`(turn p.v |=(f=vfield [[%str k.f] v.f]))`.

**That is character-for-character what `+to-fcn-pairs` does — the arm defined
immediately below `+fcn-pairs`**, written for Bags in unit 6C, whose comment
says *"tlc2's Value.toFcnRcd: a function is one, and so are a tuple (domain
1..n) and a record (string domain)"*. Two nearly identical helpers, one
correct, and `+equal-norm` called the other one. Both now say the same thing
and the comment on `+to-fcn-pairs` records why they must.

## 2. The risk that made this a unit, measured and gone

The concern was state identity: two values that compare equal must fingerprint
equal, or the checker counts them as distinct states and every `distinct` count
in the corpus moves — R2.3.1's class of risk.

**It was already true.** `+fp-enc` encodes

* `%rec` as `k-fcn` + count + `(fp-str k)` + value, and
* `%fcn` as `k-fcn` + count + `(fp-enc d)` + value,

and `fp-enc` of a `%str` *is* `fp-str`. Identical bytes. The normalized orders
agree too: `%rec` sorts fields by `strlth` and `%fcn` sorts pairs by `vlth`,
which for `%str` domain points *is* `strlth`. So the two representations have
fingerprinted the same since the encoder was written; only the comparison
beside it disagreed. No re-pinning, no counts moved, and the unit is a
morning's work rather than a week's.

`+vlth` did need unifying, and for the reason the plan gave: an order used for
storage and dedup beside an equality must not put equal values in different
buckets. Any two fcn-like values now compare through their pairs, ahead of the
`kind-rank` test — which is left alone so nothing else reorders.

## 3. A second divergence, found while standing there

The port decided RECORD FORM in rendering by "every domain point is a string".
tlc2 decides it with `FcnRcdValue.isName`
(`value/impl/FcnRcdValue.java:861`), and that is **not** "is a legal TLA+
identifier":

> every character is `_` or a letter-or-digit; at least one is a LETTER; and a
> name of 4 or more characters may not start with `WF_` or `SF_`

Measured at the pin, which is how the shape of the predicate got pinned down
before it was written:

```
"1x"  :> 1   ->  [1x |-> 1]          a LEADING DIGIT is fine
"a b" :> 1   ->  ("a b" :> 1)        a space is not
""    :> 1   ->  ("" :> 1)           no letter, so not a name
```

The port printed `[a b |-> 1]` for the second. New `+is-name` and `+rcd-form`
decide it, and the `%rec` render now routes through `+render-fcn` as well — so
a record whose field name `isName` rejects falls back to the `:>` form exactly
as the equal function does, and the two representations agree in **both**
directions rather than just one.

## 4. What the corpus could not see, and now can

`tlc-value-composite`'s evidence is `ev-composites` / `ev-lookup` / `ev-sets` /
`ev-domain`, compared **byte-exact on RENDERING**. A rendering differential
cannot see an equality: both values render the same, and nothing ever asked
whether they ARE the same. Six cases now pin the cross-representation
questions directly — `rec-fcn-eq2`, `rec-fcn-set`, `tup-fcn-eq`,
`tup-fcn-set`, `name-render`, `name-render2` — and two of them (`tup-fcn-eq`,
`tup-fcn-set`) were already green, which is what made the diagnosis precise:
the tuple half worked, so it was never "cross-representation equality is
missing", it was "`%rec` is missing from one list".

Also settled by measurement rather than left as a worry: `Cardinality({[a |-> 1],
("a" :> 1)})` is **1** at the pin and now 1 here, so set dedup unifies the two
representations — and it did so for tuples and functions already, despite their
different `kind-rank`, because dedup goes through equality and not through the
order.

## 5. Evidence

* The frozen `mc` case `rec-fcn-eq` is **UNSKIPPED** — `SKIPS` is empty again.
* `BagsTest`'s `tlc-batch` census entry is **retired**; the batch is 15/15.
* Six cross-representation cases green in one probe.

Ledger: **134 rows, 133 terminal, 1 owed** (`check-mode-generate`, R3.0c).
