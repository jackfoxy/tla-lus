# R4.0a: Stage-0 decisions, the pins and the acceptance sentence

```text
Sub-unit: R4.0a (human checkpoint)
Rows: none (docs + tools only; no desk change, no ship run)
Planned: agree the acceptance sentence; pin CommunityModules, the tlapm library
  and Apalache.tla at the Examples pin's date; record them where a script can
  check them; re-verify the Examples checkout.
Found: the pins are straightforward. The things around them are not.
  (1) The RELEASE artifact is the oracle, not the repo tree.
  (2) The module search has a shadowing order that R4.1a must reproduce.
  (3) CI runs TLC with -lncheck final.
  (4) Two of the three trees are not MIT.
  (5) Unicode is affordable, so it became clause 8.
```

## 1. Decisions (user, 2026-10-08)

- The acceptance sentence is agreed as written, clauses 1–7.
- **Clause 8 is added: Unicode, parse-only plus structural identity.** Every
  converted module must get the same verdict from the port as from the pinned
  Java SANY on the same converted text. In addition, the port's semantic graph
  of each converted module must be identical to the graph of its ASCII
  original. Graph identity carries clauses 2–3 over, so the models do not need
  a second multi-hour pass. Two options were rejected:
  - (a) reported only, with no clause;
  - (c) a full re-run of clauses 1–3 on the converted corpus. It doubles the
    census wall clock for no extra evidence, given graph identity.
- Plan revisions get numbered files. This revision is
  `~/FoxyLabs/tla-lus/R4-examples-work-breakdown-r2.md`; r1 is kept unchanged.

## 2. The pins: what CI would have fetched on 2026-05-24

`tlaplus-Examples/.github/scripts/linux-setup.sh` downloads these artifacts.
Each pin is the newest one on or before 2026-05-24.

| what | CI fetches | pin |
|---|---|---|
| CommunityModules | `releases/latest/download/CommunityModules-deps.jar` | release `202604221529`, commit `a20cc8eb2`, 2026-04-22 |
| tlapm library | `archive/main.tar.gz` | `main` at `fd3988fc4`, 2026-04-14 |
| Apalache | `releases/latest/download/apalache.tgz` (v0.52.2 fallback) | `v0.57.1`, commit `a9d9f8267`, 2026-05-22 |
| tlauc | `releases/latest/download/tlauc-linux.tar.gz` | `1.1.0`, commit `a4f21b9fc`, 2025-07-22 |

Checking the Apalache tag against `main` on the pin date: the tag is
`a9d9f8267`, while `main` on that date was `a71cf583e`. CI takes the release,
so the pin is the tag.

The pins live in one place, `tools/r4-deps.sh`. With `--fetch` it downloads
the artifacts into `/mnt/mars/gitrepos/r4-deps/` and clones the source repos.
It always checks:
- each artifact's sha256;
- each tag against its commit;
- that the jar's 29 `.tla` files are exactly the tag's `modules/`;
- that the 14 Apalache jar StandardModules that also exist in `src/tla` are
  byte-identical to the tag's copies.

That proves each cited commit is the one its artifact was built from.

`check-portmap.py` check (7) asserts that port-map §1 quotes every commit in
full and that `testing.md` and `compatibility.md` quote them as `@<9 hex>`.
**It bites**: changing `tlapm@fd3988fc4` to `…fc5` in testing.md fails it.

## 3. Finding: the repo tree is not the oracle

The CommunityModules repo has `Quorum.tla`, `QuorumTheorems*` and
`GraphTheorems*`. The `202604221529` release jar does not ship them. A port
that loaded the repo's `modules/` would therefore resolve modules that CI
cannot see, and a missing-module error would agree by accident or diverge for
the wrong reason. **The jar's `.tla` set is the module surface.**

## 4. Finding: the resolution order, and what it shadows

`util/SimpleFilenameToStream` at the oracle pin searches in this order:
1. the user directory or CWD;
2. the `-DTLA-Library` paths;
3. `ClasspathResourceLocator(cl, "tla2sany/StandardModules/")`;
4. `ClasspathResourceLocator(cl, "")`.

Steps 3–4 use one class loader, so within each step the search follows
classpath order. `parse_modules.py` sets the classpath to
`tla2tools.jar : apalache.jar : dirname(path) : CommunityModules-deps.jar : tlapm/library`.
`check_model` uses the same classpath minus the spec directory.

Measured consequences:
- `tla2tools.jar`'s StandardModules (20 files, including `Json.tla`) win
  everything, so **CommunityModules' `Json.tla` is never parsed**.
- `tla2tools.jar`'s `Bags.tla` and `FiniteSets.tla` shadow tlapm library's
  copies.
- `apalache.jar` adds 14 StandardModules that nothing earlier provides
  (`Apalache`, `Variants`, `Option`, `__rewire_*`, `__apalache_*`,
  `DummyForIntegrationTests`). Its own copies of the standard modules are
  shadowed by `tla2tools`.
- Within step 4, the spec directory comes before CommunityModules, which
  comes before tlapm.

R4.1a has to reproduce this whole order, not just "add a search root".
**Open for R4.2f:** the CommunityModules jar's Java `Json` overrides may bind
against the shadowed `Json.tla`, and that needs measuring before it is assumed.

## 5. Finding: TLC flags in CI

`tla_utils.check_model` passes `-workers auto -lncheck final -cleanup`, plus
`-Dtlc2.TLC.ide=Github` and the manifest's feature flags. Two consequences:
- Oracle capture (R4.0c) keeps `-workers 1`, which is the plan and determinism.
- R4.0c must measure whether `-lncheck final` moves any verdict, count or
  lasso on the 88 liveness models before deciding whether goldens mirror it.
  The manifest's recorded counts were produced with it.

## 6. Finding: licensing

- CommunityModules and tlauc are MIT.
- tlapm (`library/`) is BSD-2-Clause.
- Apalache is Apache-2.0 and ships a `NOTICE`.

Scaffold-gate clause (4) checks MIT provenance only. **R4.1a must choose**:
- vendor the trees into `%tla-lus`, which needs the gate and attribution
  extended to BSD-2 and Apache-2.0 with the `NOTICE`; or
- serve them only from the Examples desk as a search root, so nothing is
  vendored and the gate is untouched.

The plan's own wording (search root, not `stdmods`) leans towards the second.

## 7. Unicode probe (decides clause 8)

`specifications/Paxos` (6 modules) was converted with pinned `tlauc` and
parsed with the pinned SANY on CI's classpath:
- With `--skip numsets` (CI's flag in `unicode_conversion.py`), **6/6 rc=0**.
- Without it, `Voting` fails: `Unknown operator: 'ℕ'`. The pinned SANY does
  not know `ℕ`.

So the oracle exists for clause 8, and the converter flags are part of the pin.

## 8. Examples checkout

`git status` in `/mnt/mars/gitrepos/tlaplus-Examples` is clean at
`47b0e2cc0`. The local `TeachingConcurrency/Simple.cfg` modification recorded
on 2026-07-12 is gone, so port-map §1's caveat is updated.

## Ran

- `tools/r4-deps.sh`: clean.
- `tools/check-portmap.py`: clean with the new check (7), and the bite was
  proved and reverted.

No desk file changed, so no ship run was needed.
