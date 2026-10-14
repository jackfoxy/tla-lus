# R4.2f: the `Json` module (2026-10-13)

**Status: done.** User decisions 2026-10-13: serialize to an artifact; the
read half (`JsonDeserialize`, `ndJsonDeserialize`) REFUSED by name as an
approved difference (reading through Clay was messy: no `.ndjson` mark in
`%tla-ex`, lower-cased staging, a working-directory path; and the one
model, EWD998ChanTrace, also needs `TLCGet("config")`, R4.2w).

The module is tla2tools' own `Json` (`tlc2/module/Json.java`), which CI's
module search places ahead of CommunityModules' copy. Its vendored TLA+
bodies are dummies (`JsonSerialize(f, v) == TRUE`), so the port refused
every operator by name (`excluded` in gen-stdops-tests).

## Encoders (registry rows, pure)

`ToJson` (`getNode`), `ToJsonArray` (`getArrayNode`), `ToJsonObject`
(`getObjectNode`) in `lib/stdops` (`+json-node` and friends), following
Json.java: a record is an object, a tuple an array, a string or model value
a JSON string, an integer a number, a boolean a boolean; a function is an
object keyed by its domain (a string key as itself, any other as its
`toString`) UNLESS its domain is exactly 1..n, when it is an array; a finite
set is an array of its normalized elements; `ToJsonObject` of a tuple keys
it by 0-based position. Gson's compact text and string escaping.

## Writers (node-ops, on the carrier)

`JsonSerialize(path, v)` (v a sequence or a record) and `ndJsonSerialize(path,
s)` (one line per element) are TRUE and write a file at the pin. Here the
file is `rst.files[path]` (a later write to the same path replaces it, as
`FileWriter` truncates), and the job turns each into a `%text` artifact
`file-<path>` (`+file-art`: lower-cased, non-knot characters made `-`). An
argument of the wrong kind is EC 2169 with the pin's wording.

## Found on the way

`+esc-str` (`lib/value`, the string renderer) escaped only `"`. tlc2's
`StringValue.PrintVersion` also escapes `\`, tab, newline, form feed and CR,
so a JSON string printed in a trace differed. Fixed.

## Tests

mc `json-tojson` (pin golden: every encoder shape, and a `JsonSerialize`
that is TRUE); job `test-json-file-artifacts` (the two file artifacts equal
what tla2tools.jar writes for the same calls, `out/Trace.json` ->
`file-out-trace.json`). gen-stdops-tests classifies the five operators
`required`; the registry row count is 40.

## Corpus

EWD840_json reaches `JsonSerialize` only in the `Export` disjunct of its
invariant, which runs when its real invariant fails (it does not); it was
blocked earlier on `$Label` (fixed in R4.2m). EWD998ChanID_export has no
model in the manifest.

## Readers: refused by name

`+json-read-refused` (registry rows, so the refusal names the operator and
the reason; registry 40 -> 42). job `test-json-deserialize-refused`;
compatibility.md "Release R4.2f".
