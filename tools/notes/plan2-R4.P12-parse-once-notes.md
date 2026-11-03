# R4.P12: a `%clay` job parses each module once (2026-10-12)

**Status: DONE.** Approved at the R4.P close (plan r14).

R4.P10 found a `%clay` job parsing every loaded module three times: in the
loader (for its references), in `%parse`, and again in `+resolve` under
`+analyze-graph` / `+generate` (empty parse cache).

## Change

- `lib/job`: the loader cursor (`lcur.pc`) and the source set (`srcs.pc`)
  carry a `pcache:mod` (tree by `shax` of the text). The loader parses
  through `+parse-cached`; `close-load` hands the cache on with the sources.
  `%parse` (both the `%check` root and every `%analyze` module) and
  `+def-node` go through `+parse-typed-cached` (a hit has no diagnostics: a
  cached tree parsed cleanly); `%semantic`, its resolution-failure path and
  `%config` resolve with the cache.
- `lib/semantic`: `+generate-with`, `+analyze-graph-with` take the cache;
  `+generate` / `+analyze-graph` call them with `~` (console, tests, tier 2
  unchanged).
- An inline bundle carries `~` (its sources are never copied into the
  continuation). The StandardModules are still parsed once per resolve.

## Evidence

- New arm `tests/lib/clay-load` `test-clay-load-carries-parse-cache`: at
  the `%src` hand-off the cache holds exactly the two loaded modules, and a
  hit is answered without parsing.
- clay-load 39, job 130, app 44, blackbox 40, source-path 21, modres 18,
  fuzz 14 green.
- Through the runner (`--parse`, load about 2.5–3): `tcp_proof` **153.5 →
  71.7 s**, `bcastByz` **53 → 29.1 s**; both still `agree`.
