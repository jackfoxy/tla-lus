# R5.1 — upstream license files (2026-11-03)

Plan r12 added R5.1 as a follow-on step after R4's acceptance. The user moved
it up on 2026-11-03, at the R4.Q close.

## Inventory: where tlapm and tlauc material reaches the repo or a desk

| upstream | license (at the pin) | where its text goes | before R5.1 |
|---|---|---|---|
| tlapm library (`fd3988fc4`) | BSD-2-Clause | `%tla-ex` `tlapm/` (11 modules, `examples.py --stage`) | no license beside them |
| tlauc (`a4f21b9f`, 1.1.0) | MIT | nowhere yet; R4.4's converted modules and goldens will live in `desk/test-data/unicode/` | — |
| CommunityModules (`a20cc8eb`) | MIT | `%tla-ex` `community/`; module texts quoted in `tests/lib/cmops` | no license beside them |
| Apalache (`a9d9f826`, v0.57.1) | Apache-2.0 + NOTICE | `%tla-ex` `apalache/` | no license or NOTICE beside them |
| tlaplus-Examples (`47b0e2cc`) | MIT | `%tla-ex` `specifications/` | no license beside them |

The repo itself stores no tlapm module text. The tier-2 inventory and the
classifier only NAME the TLAPS modules (`module:TLAPS` exclusions). The
three upstreams outside R5.1's letter are staged the same way, so they got
the same fix.

## Changes

- `licenses/<upstream>-license.txt` (5 files): the LICENSE (and Apalache's
  NOTICE) verbatim from the pinned commit (`git show <pin>:LICENSE`), under
  a header giving the upstream URL, the pinned commit and tag, the SPDX
  name and what the file covers.
- `tools/gen-licenses.py` writes them from the pins in `tools/r4-deps.sh`.
  `--check` passes when the files equal what the pins give and there are no
  extras, every tlapm library module stored under `desk/` has a
  `license.txt` beside it, and `desk/test-data/unicode/` (R4.4) has one.
- `tools/examples.py`: `+stage_licenses` puts each upstream's file beside
  its staged library as `license.txt` (`.txt`: Clay casts every file by its
  extension). Two new offline checks in `tools/test-examples.py`.
- `tools/scaffold-gate.sh` gate 4 runs `gen-licenses.py --check`. It used
  to name only MIT.
- `desk/doc/port-map.md`'s attribution paragraph and the README's License
  section point at `licenses/`.
- tla-zod's live `%tla-ex` got the four `license.txt` files (revision 21).

## Evidence

- `gen-licenses.py --check` ok. It fails on an edited license file, on a
  tlapm module (`TLAPS.tla`) placed under `desk/` without a license, and on
  `desk/test-data/unicode/` without one (all three tried, then reverted).
- scaffold-gate PASS (gate 4: 3/3). test-examples PASS.

## For R4.4

Its tlauc output goes under `desk/test-data/unicode/` with
`licenses/tlauc-license.txt` copied in as `license.txt`. The gate refuses
the directory otherwise.
