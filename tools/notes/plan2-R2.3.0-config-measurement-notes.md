# P2-R2.3.0 — what the config capabilities actually cost

Measurement only; no code. R2.3.0 gates R2.3 (`.1` VIEW, `.2` ALIAS, `.3` cfg
source override, `.4` INVARIANT+PROPERTY, `.5` `cfg-runspec`'s three). Two
sub-units get smaller, one gets *different*, two are confirmed as written.

## `.1` VIEW — the primitives already exist; the risk is elsewhere

The plan sized this **M / high** and called it "the highest-risk unit in R2".
The risk rating is right. The size is not, and the reason matters.

Java (`TLCStateMutExt.fingerPrint`, the `viewMap != null` branch):

```java
IValue val = tool.eval(viewMap, Context.Empty, state);   // state == minVals
fp = val.fingerPrint(fp);
```

Two things the port already has:

- **`+fp-value`** (`lib/fingerprint.hoon:69`) fingerprints a *single* `value` —
  which is exactly the shape a view produces. No new fingerprint primitive.
- **`+orbit-fp`** already returns `[fp canon]`: it canonicalizes under the
  symmetry group *first*, then fingerprints. That is Java's ordering exactly —
  `minVals` is the symmetry representative, and the view is evaluated on it.
  The composition question I expected to have to answer is already answered.

So VIEW has **one insertion point**: where `+orbit-fp` computes
`(state-fp order canon)`, a view instead computes
`(fp-value (eval view canon))`. `check.hoon:368` is the only caller.

**The risk is behavioural, not structural.** A VIEW changes which states are
distinct, so it changes `distinct` counts, the shape of the state graph, and
whether a run terminates at all. That is why it keeps a unit to itself — not
because the code is large.

## `.2` ALIAS — one chokepoint, and one place that must be left alone

Both renderers funnel through **`+state-pairs`**:

- the console report, via `+render-state` (six call sites in `check.hoon`);
- the typed wire trace, via `job.hoon:1633`, which calls `+state-pairs`
  directly.

So ALIAS also has one insertion point rather than two.

**But there is a third consumer that must NOT get alias treatment**, and it is
the kind of thing that would be found the hard way: R1.1.R1 gave
`gen-stream-tests` its **own** `+binds` built from `+state-pairs`, deliberately,
because `StreamDump.java:45` strips the `/\ ` prefix — that differential
compares successor *order*, not console rendering. An alias applied there would
corrupt a projection that has nothing to do with traces. Recorded here so `.2`
does not rediscover it by breaking the stream shard.

## `.4` INVARIANT + PROPERTY — the plan's premise is wrong

The plan says: *"currently a typed rejection at `%config`. tlc2 runs both; the
port must too"* — implying the engine can already do it and only the kernel
refuses. **It cannot.**

The rejection is indeed only in the kernel (`job.hoon:1155`, nothing in
`check.hoon`). But measuring what the console path actually does:

- the **liveness** branch builds its graph with `~` for invariants
  (`check.hoon:1984`) — invariants are simply not checked;
- the **box-state** branch *substitutes* the property for them
  (`~[[u.pp.c u.binner]]`, `check.hoon:1959`) — the config's own invariants are
  dropped.

So **neither path checks invariants alongside a temporal property.** `.4` is not
"lift a kernel rejection"; it is "make the liveness path carry and check the
invariant list", which is engine work in `build-graph`'s options and its
per-state check. Size **M stands**, but the content is different from what the
row describes, and a unit that started by trying to delete the rejection would
have produced a confidently wrong answer.

This is the same kernel-vs-console asymmetry R1.8.3 found for SPECIFICATION-form
configs — except there the console path *was* correct and only the kernel
refused. Here the refusal is honest.

## `.3` and `.5` — confirmed as written

**`.3` cfg source override.** `check-opts.cfg` is `(unit source-name)`; the
resolved config text lands in `srcs.cfg=(unit @t)`. For an `%inline` bundle the
natural resolution is a key of the `modules` map; for `%clay`, a path. This is a
resolution step at submit plus one in `+srcs-of` — **S / low**, as planned.

**`.5` `cfg-runspec`'s three.** Still deferred at the arm, in
`+decompose-spec`'s own comment: INSTANCE substitution, LazyValue parameter
inlining, and the subscript-coverage warning. Unchanged, **M / med**.

## Net effect on R2.3

| sub | plan | measured |
|---|---|---|
| `.1` VIEW | M / high | **S–M** / high — one insertion point; `fp-value` and `orbit-fp`'s `canon` already exist. Risk is behavioural |
| `.2` ALIAS | M / med | **S–M** / med — one chokepoint (`+state-pairs`), plus one consumer that must be excluded |
| `.3` cfg override | S / low | confirmed |
| `.4` INV+PROP | M / med | **M / med, different work** — the engine cannot do it either; the liveness path must carry invariants |
| `.5` runspec ×3 | M / med | confirmed |

Sequencing note: `.2` and `.4` both touch what a run reports, and `.1` changes
what a run *counts*. Taking `.1` first means `.2` and `.4` are tested against a
fingerprint path that has already settled.
