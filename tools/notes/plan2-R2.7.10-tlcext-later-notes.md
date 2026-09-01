# R2.7.10 — the three `later:` surfaces

The row could not reach a terminal status while `desk/test-data/stdops/inventory.txt`
carried `later:` verdicts, and `gen-stdops-tests.py` fails on any surface
without one — so the two records were already coupled and this unit only had
to decide. All three are ported; the `later:` bucket is **empty**.

## Measured first

| surface | pin |
|---|---|
| `TLCExt!TLCFP(v)` | `IntValue.gen(FP64.Hash(v.fingerPrint(FP64.New())))`, and `FP64.Hash(long fp)` is literally `(int) fp` — the LOW 32 BITS AS A SIGNED int |
| `TLCExt!TLCEvalDefinition("Foo")` | 42 for `Foo == 41 + 1` — the root module's `getOpDef(name)`, evaluated |
| `TLCExt!TLCModelValue("mv1")` | `mv1` — `ModelValue.add(name)` |

**`TLCFP` is not reproducible without `-fp`**, and that is the pin's property,
not a port limitation: `FP64.New()` takes its polynomial from the `-fp` index,
so two runs of the same jar on the same input gave `661005754` and then
`1287323929` for `TLCFP(3)`. Under `-fp 0` it is stable (`-244908333` twice).
The same precondition R2.7.4.4's RNG already carries.

## What shipped

- `TLCFP` and `TLCModelValue` as registry rows; `TLCEvalDefinition` on the
  node-op path, because it is an `@Evaluation` override that receives the node
  and the context.
- `TLCFP` reads the low 32 bits of the port's own `+fp-value` and converts to
  two's-complement signed — the same FP64 over the same canonical bytes.
- `TLCModelValue` returns the value itself: the port's model value IS its name
  (`tlc-value-model`'s standing approved difference), so there is nothing to
  intern. Worth stating rather than glossing — the pin interns, the port does
  not, and the observable answer is the same.
- `TLCEvalDefinition` resolves in `ops.e`, which IS tlc2's `getOpDef` table.
  A non-string argument and an unresolvable name are both the pin's
  one-argument error.

## Evidence

`tlcext-later`, a new `mc` case pinned to `-fp 0` via `opts.txt`, asserting all
three in one postcondition — byte-exact. `gen-stdops-tests.py` reclassifies the
three from `excluded`/`later:` to `required`/`in:`, and its R2-scope histogram
is now **in 63 · n/a 20 · out 48**, with `later:` gone.

`tests/lib/stdops`' registry-row drift alarm went 37 → **39** (two rows; the
third is a node-op) and was updated with the reason, as R2.7.4.3's decrement
was.

Five shards green: mc, stdops, stdops-diff, tlcmod, regprop.
