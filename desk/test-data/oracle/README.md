# Oracle Baseline (Work Unit 0)

Golden outputs from the pinned Java `tla2tools.jar`, used as the
differential-test oracle for the Hoon port. Pin, build instructions,
invocation forms, and normalization rules: `desk/doc/port-map.md`.

- `cases/<name>/` — one fixture per pipeline area. Hand-written specs are
  original; copied specs carry a `SOURCE` file with upstream commit and
  license (MIT).
- `golden/<name>.txt` — normalized oracle output plus `exit-code:`; for the
  PlusCal case, also the full rewritten `.tla`.
- `regen.sh` — regenerates all goldens in temp dirs against the pinned jar;
  refuses to run if the `tlaplus` checkout is not at the pinned commit.
  `regen.sh --check` verifies without rewriting (exit 1 on any mismatch).

```bash
TLA_REPO=/mnt/mars/gitrepos/tlaplus ./regen.sh --check
```
