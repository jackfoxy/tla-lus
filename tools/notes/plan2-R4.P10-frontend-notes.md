# R4.P10: front-end speed (2026-10-12)

**Status: DONE (exit evidence met).** `tcp_proof` is analyzed through the
job in 153 s (891 s before), under the default 600 s limit.

## Where the time went

Phase profile of `tcp_proof` (18 modules) in one event, scratch profiler:

| phase | time |
|---|---|
| module resolution (parsing every module) | **274 s** |
| contexts (`+analyze`) | 0.5 s |
| root context, level deps | 0.6 s |
| `+gen-module` | 5.6 s |
| level check + lint | 0.4 s |

Within parsing, the LEXER dominated:

| input | tokens | lex before | lex after | parse total after |
|---|---|---|---|---|
| tcp.tla (330 lines) | 1,874 | 6.47 s | 0.34 s | 1.05 s |
| tcp_proof, first 2,000 lines | 16,685 | 59.2 s | 2.85 s | 10.5 s |

## Cause and fix (`lib/lexer`)

`+fixed-table` was a plain arm, so every call REBUILT it: about 280 fixed
lexemes, each decoded to codepoints. `+match-fixed` called it once per
token and then scanned every entry. That was about 3.5 ms per token.
- `+fixed-table` is folded at compile time (`^~`).
- `+fixed-index` (also `^~`) buckets the lexemes by first character, each
  bucket in table order, so the first-longest choice is unchanged. A lexeme
  starting with another character can neither match nor leave a live prefix
  (the error-reporting `alive` length), so that is unchanged too.

Evidence: lexer 270, syntax 253, parse-err 99, bnf, fuzz green
(byte-identical token streams and trees); `tcp_proof` 891 → 153.5 s and
`bcastByz` 237 → 53 s through the runner.

## Remaining (follow-on)

- The parser itself costs about 0.45 ms per token (tcp_proof about 16 s).
  It is linear; no hot spot has been identified yet.
- A `%clay` analyze job parses every module THREE times: in the loader (for
  references), in `%parse`, and again in `+analyze-graph` (which resolves
  with an empty parse cache). A `~+` on `+parse` did not help (the memo
  does not survive across the job's events). The fix is to carry the
  loader's trees in the continuation and pass them as `+resolve`'s cache:
  about 3× on the job path.
