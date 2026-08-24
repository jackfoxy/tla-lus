# R2.3.3 — cfg source override (`check-opts.cfg`)

`check-opt-cfg` → **parity**. Owed 14 → 13.

## What it is

tlc2's `-config <file>` replaces the default `<spec>.cfg` with a named file.
The port's analogue: `check-opts.cfg` names one of an `%inline` bundle's **own
sources** to use as the config, replacing the bundle's `cfg` field.

Nothing new is loaded — the named source is already in the bundle, already
size-counted by `+validate-bundle`, and already hashed into provenance. The
override only decides *which* of the caller's bytes are the config.

## One helper, and the reader that is easy to miss

`+cfg-of [req srcs]` resolves the effective config. Two readers go through it:

- `+do-config`, the obvious one — the `%config` stage.
- **`+has-property`**, the one worth naming. It parses the config **at submit**
  to decide whether the plan needs a `%liveness` stage. Miss it and an
  overridden config *plans a different set of stages than it runs* — the job
  would announce a stage list derived from the bundle's cfg and then execute
  the override's.

`+inline-provs` follows too: under an override it records the NAMED source's id
and hash as the config, not the bundle `cfg` the override displaced. A run must
name what it actually read. (The bytes were already listed under that name in
the module list, so this is about the *config slot* being honest, not about
adding bytes.)

## An unknown name is refused at submit

`+validate` checks the name against `modules` before a job exists. The
alternative — resolving to `~` and falling back to the bundle's cfg — would
check a config the caller did not ask for and report success. That is the
R2.1 doctrine applied to a *resolution* failure rather than an unsupported
option.

## `%clay` keeps a typed rejection, and it is not residue

A `%clay` bundle selects its config by **path** (`src.cfg`). The desk has no
`%cfg` mark, so the file's mark is part of the reference — hence
`/spec-cfg/txt` — and a bare NAME cannot supply it. The capability is present
on both bundle kinds; it is spelled to match how each one names its sources.
Message: `unsupported: cfg source override on a %clay bundle; select the
config with src.cfg (a path)`.

## The differential is a matched pair

One bundle carries **both** configs: its own `cfg` (`INVARIANT Loose`, which
holds) and a named source `strict` (`INVARIANT Strict`, which does not). The
same bundle runs twice with only `check-opts.cfg` different:

| override | result |
|---|---|
| `~` | `%ok [5 4 0 4 …]` |
| `` `'strict' `` | `%violated [%invariant 'Strict']` |

A different verdict **kind**, not a different count — the bundle's own cfg
cannot produce the second, so the test proves the override *selects* rather
than that a number happens to match.

Plus two submit rejections: `unknown cfg source: nope`, and the `%clay` one.

## Touched

`desk/lib/job.hoon` (`+validate`, new `+cfg-of`, `+has-property`,
`+do-config`, `+inline-provs` + its one caller), `desk/sur/tla-lus.hoon`
(the `check-opts.cfg` comment), `desk/tests/lib/job.hoon` (4 arms),
`desk/doc/parity-manifest.md`, `desk/doc/compatibility.md`.

`compatibility.md` also gets an R2.3.2 correction picked up here: its
typed-rejection summary still listed `ALIAS` as wholly refused, which R2.3.2
had narrowed to the temporal-PROPERTY and simulation cases.
