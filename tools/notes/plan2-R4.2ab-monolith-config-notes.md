# R4.2ab — the monolith CONFIG half (`tlc-monolith` → parity)

2026-10-14. The user's r12 call: port `MonolithSpecExtractor.config` rather
than keep the R4.1-close approved difference (`%tla-config` refused at submit).

## Measured at the pin (tla2tools.jar, `-config X.tla`)

Scratch specs `M1`..`M7` (a 4-state counter, deadlocking at x = 3):

| case | pin |
|---|---|
| `---- CONFIG M1 ----` … `====` | the block is the config (run proceeds) |
| no CONFIG block | empty config: EC 2231 "The configuration file did not specify the initial state predicate." |
| an empty block (`====` on the next line) | EC 2231 |
| `CONFIG m4` in `M4.tla` | no match (Java is case-sensitive): EC 2231 |
| `-----  CONFIG   M5   -------`, no closing `====` | matches; block runs to end of file |
| two `CONFIG M6` blocks | the first wins |
| `CONFIG Other` only | EC 2231 |
| empty `E.cfg` | EC 2231 (same as the no-block case) |
| `-config M1.tla M2` | reads `CONFIG M1`: the name is the CONFIG file's, not the root module's |

Source: `ModelConfig.parse` passes `configFileName.replace(".tla", "")`;
the header is the whole-line `-----*\s*CONFIG\s+<quoted name>\s*-----*`, the end
is the first `====.*` line after activation, the result is `String.trim()`ed.

## Port

- `lib/modules` `+monolith-config [text seg]`, `+trim-ws`.
- `lib/job` `+cfg-text`: at load close, a `cfg` path ending `/tla` yields
  `(monolith-config file seg)`; provenance (`+clay-provs`) still hashes the
  whole file as read.
- `lib/source-path`: the `%tla-config` error and its `+check-bundle` refusal
  are gone.

**Analogue (the one judgment call):** a Clay file segment is the lowercased
name (`+module-seg`; Clay knots have no capitals), so `<name>` cannot be
compared case-sensitively. The header's name is case-folded and compared to
the segment. A header whose case differs from the file name matches here and
not at the pin; no corpus spec does that.

## Tests

`tests/lib/clay-load`: `test-clay-monolith-config`,
`-config-other-file` (`CONFIG Conf` in `/src/conf/tla`, first block for another
name skipped), `-config-missing-block` (= inline empty cfg),
`test-monolith-config-edges` (first wins, unterminated, `---` too short, junk
after the dashes, empty block, CR, trim). `test-clay-tla-config-rejected`
retired.
