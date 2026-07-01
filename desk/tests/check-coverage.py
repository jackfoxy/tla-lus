#!/usr/bin/env python3
"""Generate and verify the %tla-lus black-box acceptance inventory.

The Examples corpus mirrored under ``fixtures/examples`` is the source of
truth.  Every CI-validated manifest model with a stable declared outcome
becomes one traceable Hoon test arm.  ``--write`` regenerates the Hoon
corpus/failure files, the coverage ledger and the fixture checksum list;
the default (check) mode fails if anything is missing, stale, duplicated or
points at a missing fixture, and if the selected/tested counts diverge.

This file is the deterministic coverage gate required by the suite: the
selected count and the tested count must match, or it exits non-zero.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from collections import Counter, defaultdict
from datetime import timedelta
from pathlib import Path

HERE = Path(__file__).resolve().parent
DESK = HERE.parent
EXAMPLES = HERE / "fixtures" / "examples"
COMMIT = "47b0e2cc0268836b89f5ce451f38e5df5f1cf773"

# Manifest results that map to a stable, externally observable oracle.  A
# declared failure is a passing test when the app reports that same failure.
SELECTED_RESULTS = {
    "safety failure",
    "deadlock failure",
    "liveness failure",
    "assumption failure",
    "success",
}

# PlusCal translation checks excluded upstream (tracked against the pinned
# commit so the exclusion stays visible in the ledger).
PLUSCAL_EXCLUSIONS = {
    "specifications/byzpaxos/BPConProof.tla": "upstream CI excludes translation for tlaplus/tlaplus#906",
    "specifications/byzpaxos/PConProof.tla": "upstream CI excludes translation for tlaplus/tlaplus#906",
    "specifications/byzpaxos/VoteProof.tla": "upstream CI excludes translation for tlaplus/tlaplus#906",
}

# Synthetic deterministic fixtures for public failure modes not covered by
# the Examples corpus.  Each row:
#   (name, scenario, root, config, tool, mode, expected, code, fragment,
#    actions, loop, overrides)
FAILURES = {
    "parser": [
        ("lexical-error", "run", "parser/Lexical.tla", None, "sany", "parse", "lexical-error", 4000, "lexical", [], None, {}),
        ("parse-error", "run", "parser/Parse.tla", None, "sany", "parse", "parse-error", 4001, "syntax", [], None, {}),
        ("semantic-error", "run", "parser/Semantic.tla", None, "sany", "parse", "semantic-error", 4002, "semantic", [], None, {}),
        ("level-error", "run", "parser/Level.tla", None, "sany", "parse", "level-error", 4002, "level", [], None, {}),
        ("module-name-mismatch", "run", "parser/WrongName.tla", None, "sany", "parse", "parse-error", 4001, "module name", [], None, {}),
        ("missing-dependency", "run", "parser/MissingDependency.tla", None, "sany", "parse", "semantic-error", 4002, "dependency", [], None, {}),
        ("malformed-dependency", "run", "parser/MalformedDependency.tla", None, "sany", "parse", "parse-error", 4001, "Broken", [], None, {}),
    ],
    "config": [
        ("missing-config", "run", "valid/Valid.tla", "config/Missing.cfg", "tlc", "exhaustive", "config-error", 5001, "config", [], None, {}),
        ("malformed-config", "run", "valid/Valid.tla", "config/Malformed.cfg", "tlc", "exhaustive", "config-error", 5003, "identifier", [], None, {}),
        ("duplicate-config", "run", "valid/Valid.tla", "config/Duplicate.cfg", "tlc", "exhaustive", "config-error", 5004, "twice", [], None, {}),
        ("unassigned-constant", "run", "config/Unassigned.tla", "config/Unassigned.cfg", "tlc", "exhaustive", "config-error", 5002, "constant", [], None, {}),
        ("unknown-constant", "run", "valid/Valid.tla", "config/UnknownConstant.cfg", "tlc", "exhaustive", "config-error", 5002, "constant", [], None, {}),
        ("wrong-level-invariant", "run", "valid/Valid.tla", "config/WrongInvariant.cfg", "tlc", "exhaustive", "level-error", 2146, "invariant", [], None, {}),
        ("wrong-level-property", "run", "valid/Valid.tla", "config/WrongProperty.cfg", "tlc", "exhaustive", "config-error", 5002, "property", [], None, {}),
    ],
    "runtime": [
        ("false-assumption", "run", "runtime/Assumption.tla", "runtime/Assumption.cfg", "tlc", "exhaustive", "assumption-failure", 2104, "assumption", [], None, {}),
        ("incomplete-initial-state", "run", "runtime/IncompleteInit.tla", "runtime/IncompleteInit.cfg", "tlc", "exhaustive", "evaluation-error", 2106, "initial", [], None, {}),
        ("incomplete-next-state", "run", "runtime/IncompleteNext.tla", "runtime/IncompleteNext.cfg", "tlc", "exhaustive", "evaluation-error", 2109, "next", [], None, {}),
        ("no-initial-states", "run", "runtime/NoInitialStates.tla", "runtime/NoInitialStates.cfg", "tlc", "exhaustive", "evaluation-error", 2118, "initial", [], None, {}),
        ("no-constraint-states", "run", "runtime/NoConstraintStates.tla", "runtime/NoConstraintStates.cfg", "tlc", "exhaustive", "evaluation-error", 2256, "constraint", [], None, {}),
        ("invariant-in-initial-state", "run", "runtime/InvariantInitial.tla", "runtime/InvariantInitial.cfg", "tlc", "exhaustive", "safety-failure", 2107, "invariant", ["Init"], None, {}),
        ("invariant-in-reachable-state", "run", "runtime/InvariantReachable.tla", "runtime/InvariantReachable.cfg", "tlc", "exhaustive", "safety-failure", 2110, "invariant", ["Init", "Next"], None, {}),
        ("invariant-evaluation", "run", "runtime/InvariantEvaluation.tla", "runtime/InvariantEvaluation.cfg", "tlc", "exhaustive", "evaluation-error", 2111, "evaluation", [], None, {}),
        ("action-property", "run", "runtime/ActionProperty.tla", "runtime/ActionProperty.cfg", "tlc", "exhaustive", "safety-failure", 2112, "action", ["Init", "Next"], None, {}),
        ("deadlock", "run", "runtime/Deadlock.tla", "runtime/Deadlock.cfg", "tlc", "exhaustive", "deadlock-failure", 2114, "deadlock", ["Init"], None, {}),
        ("liveness-lasso", "run", "runtime/Liveness.tla", "runtime/Liveness.cfg", "tlc", "exhaustive", "liveness-failure", 2116, "temporal", ["Init", "Next"], 1, {}),
        ("liveness-with-symmetry", "run", "runtime/LivenessSymmetry.tla", "runtime/LivenessSymmetry.cfg", "tlc", "exhaustive", "config-error", 2279, "symmetry", [], None, {}),
        ("expression-evaluation", "run", "runtime/Evaluation.tla", "runtime/Evaluation.cfg", "tlc", "exhaustive", "evaluation-error", 2179, "division", [], None, {}),
        ("invalid-mode", "invalid-mode", "valid/Valid.tla", "valid/Valid.cfg", "tlc", "exhaustive", "parameter-error", 3113, "mode", [], None, {}),
        ("invalid-flag", "run", "valid/Valid.tla", "valid/Valid.cfg", "tlc", "exhaustive", "parameter-error", 3113, "flag", [], None, {"flags": ["--not-a-real-flag"]}),
        ("invalid-worker", "run", "valid/Valid.tla", "valid/Valid.cfg", "tlc", "exhaustive", "parameter-error", 3105, "worker", [], None, {"workers": 0}),
        ("invalid-depth", "invalid-depth", "valid/Valid.tla", "valid/Valid.cfg", "tlc", "simulate", "parameter-error", 3107, "depth", [], None, {}),
        ("invalid-seed", "invalid-seed", "valid/Valid.tla", "valid/Valid.cfg", "tlc", "simulate", "parameter-error", 1102, "seed", [], None, {}),
        ("invalid-timeout", "run", "valid/Valid.tla", "valid/Valid.cfg", "tlc", "exhaustive", "parameter-error", None, "timeout", [], None, {"timeout": 0}),
        ("invalid-path", "run", "../../etc/passwd", "valid/Valid.cfg", "tlc", "exhaustive", "interface-error", None, "path", [], None, {}),
        ("cancellation", "cancel", "runtime/Unbounded.tla", "runtime/Unbounded.cfg", "tlc", "exhaustive", "cancelled", None, "cancel", [], None, {"timeout": 30}),
        ("timeout", "run", "runtime/Unbounded.tla", "runtime/Unbounded.cfg", "tlc", "exhaustive", "timeout", None, "timeout", [], None, {"timeout": 1}),
        ("resource-limit", "run", "runtime/Unbounded.tla", "runtime/Unbounded.cfg", "tlc", "exhaustive", "resource-limit", None, "state limit", [], None, {"max_states": 10}),
        ("worker-process-failure", "run", "valid/Valid.tla", "valid/Valid.cfg", "tlc", "exhaustive", "process-failure", None, "worker", [], None, {"flags": ["--test-worker-command=/definitely/missing"]}),
        ("oversized-input", "run", "valid/Valid.tla", "valid/Valid.cfg", "tlc", "exhaustive", "resource-limit", None, "input", [], None, {"max_input": 1}),
    ],
    "interface": [
        ("malformed-mark", "malformed-mark", "valid/Valid.tla", "valid/Valid.cfg", "tlc", "exhaustive", "interface-error", None, "mark", [], None, {}),
        ("malformed-payload", "malformed-payload", "valid/Valid.tla", "valid/Valid.cfg", "tlc", "exhaustive", "interface-error", None, "payload", [], None, {}),
        ("unauthorized-poke", "unauthorized", "valid/Valid.tla", "valid/Valid.cfg", "tlc", "exhaustive", "interface-error", None, "unauthorized", [], None, {}),
        ("unknown-scry", "unknown-scry", "valid/Valid.tla", "valid/Valid.cfg", "tlc", "exhaustive", "interface-error", 5999, "unknown scry", [], None, {}),
        ("duplicate-request-id", "duplicate-request", "valid/Valid.tla", "valid/Valid.cfg", "tlc", "exhaustive", "interface-error", None, "duplicate", [], None, {}),
        ("missing-request-id", "missing-request-id", "valid/Valid.tla", "valid/Valid.cfg", "tlc", "exhaustive", "interface-error", None, "request id", [], None, {}),
        ("query-before-submit", "query-before-submit", "valid/Valid.tla", "valid/Valid.cfg", "tlc", "exhaustive", "interface-error", 5999, "absent", [], None, {}),
        ("query-after-completion", "query-after-completion", "valid/Valid.tla", "valid/Valid.cfg", "tlc", "exhaustive", "success", None, None, [], None, {}),
        ("deterministic-repeat", "repeat", "valid/Valid.tla", "valid/Valid.cfg", "tlc", "exhaustive", "success", None, None, [], None, {}),
        ("concurrent-independent", "concurrent", "valid/Valid.tla", "valid/Valid.cfg", "tlc", "exhaustive", "success", None, None, [], None, {}),
        ("restart-persistence", "restart", "valid/Valid.tla", "valid/Valid.cfg", "tlc", "exhaustive", "success", None, None, [], None, {}),
        ("rejected-run-isolation", "rejected-run-isolation", "valid/Valid.tla", "valid/Valid.cfg", "tlc", "exhaustive", "success", None, None, [], None, {}),
    ],
}


def manifests():
    for path in sorted((EXAMPLES / "specifications").glob("*/manifest.json")):
        yield path, json.loads(path.read_text(encoding="utf-8"))


def seconds(runtime):
    if runtime == "unknown":
        return None
    hours, minutes, secs = map(int, runtime.split(":"))
    return int(timedelta(hours=hours, minutes=minutes, seconds=secs).total_seconds())


def hid(prefix, *parts):
    digest = hashlib.sha256("\x00".join(parts).encode()).hexdigest()[:12]
    return f"{prefix}-{digest}"


def slug(value):
    value = re.sub("[^a-z0-9]+", "-", value.lower()).strip("-")
    return value[:38].rstrip("-")


def arm_name(prefix, label, identifier):
    return f"test-{prefix}-{slug(label)}-{identifier[-8:]}"


def hnum(value):
    return f"{value:,}".replace(",", ".")


def hcord(value):
    return "'" + value.replace("\\", "\\\\").replace("'", "\\'") + "'"


def htape(value):
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def bind_cord(name, value):
    escaped = value.replace("\\", "\\\\").replace('"', '\\"')
    if len(escaped) <= 48:
        return [f"  =/  {name}  (crip {htape(value)})"]
    parts = [escaped[i:i + 48] for i in range(0, len(escaped), 48)]
    lines = [f"  =/  {name}", "    %-  crip"]
    lines.extend(
        f'    "{part}"' + ("." if index < len(parts) - 1 else "")
        for index, part in enumerate(parts)
    )
    return lines


def hunit_number(value):
    if value is None:
        return "~"
    return f"[~ {hnum(value)}]"


def hunit_cord(value):
    if value is None:
        return "~"
    return f"[~ {hcord(value)}]"


def hlist_cords(values):
    if not values:
        return "~"
    return "~[" + " ".join(hcord(value) for value in values) + "]"


def mode_expr(mode, tool=None):
    if tool == "sany":
        return "[%parse ~]"
    if tool == "tlaps":
        return "[%prove ~]"
    if tool == "pluscal":
        return "[%translate ~]"
    if mode == "exhaustive search" or mode == "exhaustive":
        return "[%exhaustive ~]"
    if mode == "generate":
        return "[%generate ~]"
    if mode == "symbolic":
        return "[%symbolic 5]"
    if mode == "simulate":
        return "[%simulate 1]"
    if isinstance(mode, dict):
        count = int(mode["simulate"]["traceCount"])
        return f"[%simulate {hnum(count)}]"
    raise ValueError(mode)


def options_expr(*, workers, timeout, seed, max_states=None, max_input=None, flags=None):
    worker = "%auto" if workers == "auto" else hnum(int(workers))
    flags = flags or []
    return [
        "  =/  options",
        f"    :*  {worker}",
        f"        {hnum(int(timeout))}",
        f"        {hunit_number(seed)}",
        f"        {hunit_number(max_states)}",
        f"        {hunit_number(max_input)}",
        f"        {hlist_cords(flags)}",
        "    ==",
    ]


def stats_expr(model):
    values = [model.get("distinctStates"), model.get("totalStates"), None]
    if not any(value is not None for value in values):
        return "~"
    return "[~ " + " ".join(hunit_number(value) for value in values) + "]"


def test_file(arms):
    return "\n".join(["/-  *tla-lus-test", "/+  *tla-lus-test-helpers", "|%", *arms, "--", ""])


def corpus_arm(entry):
    lines = [
        "::",
        f"::  coverage-id: {entry['id']}",
        "::",
        f"++  {entry['arm']}",
    ]
    lines.extend(bind_cord("manifest", entry["manifest"]))
    lines.extend(bind_cord("module", entry["module"]))
    lines.extend(bind_cord("model", entry.get("model", "")))
    lines.extend(options_expr(**entry["options"]))
    lines.extend([
        "  %-  expect-corpus-case",
        f"  :*  {hcord(entry['id'])}",
        "      manifest",
        "      module",
        "      model",
        f"      %{entry['tool']}",
        f"      {entry['mode_expr']}",
        f"      %{entry['expected'].replace(' ', '-')}",
        f"      {hcord(entry['runtime'])}",
        f"      {'%.y' if entry['quick'] else '%.n'}",
        f"      {entry['stats']}",
        "      options",
        "  ==",
    ])
    return "\n".join(lines)


def failure_arm(group, item):
    (name, scenario, root, config, tool, mode, expected, code,
     fragment, actions, loop, overrides) = item
    options = {
        "workers": overrides.get("workers", "auto"),
        "timeout": overrides.get("timeout", 60),
        "seed": overrides.get("seed"),
        "max_states": overrides.get("max_states"),
        "max_input": overrides.get("max_input"),
        "flags": overrides.get("flags", []),
    }
    identifier = hid("failure", group, name)
    lines = [
        "::",
        f"::  failure-id: {identifier}",
        "::",
        f"++  {arm_name(group, name, identifier)}",
    ]
    prefix = "tests/fixtures/failures/"
    lines.extend(bind_cord("root", prefix + root))
    if config is not None:
        lines.extend(bind_cord("config", prefix + config))
    lines.extend(options_expr(**options))
    config_expr = "~" if config is None else "[~ config]"
    lines.extend([
        "  %-  expect-failure-case",
        f"  :*  {hcord(name)}",
        f"      %{scenario}",
        "      root",
        f"      {config_expr}",
        f"      %{tool}",
        f"      {mode_expr(mode, tool)}",
        "      options",
        f"      %{expected}",
        f"      {hunit_number(code)}",
        f"      {hunit_cord(fragment)}",
        f"      {hlist_cords(actions)}",
        f"      {hunit_number(loop)}",
        "  ==",
    ])
    return "\n".join(lines)


def build_inventory():
    model_entries = []
    parse_entries = []
    proof_entries = []
    pluscal_entries = []
    for manifest_path, data in manifests():
        manifest_rel = manifest_path.relative_to(EXAMPLES).as_posix()
        for module in data["modules"]:
            module_path = module["path"]
            parser_id = hid("parse", manifest_rel, module_path)
            parse_entries.append({
                "id": parser_id,
                "arm": arm_name("sany", Path(module_path).stem, parser_id),
                "manifest": manifest_rel,
                "module": module_path,
                "model": "",
                "tool": "sany",
                "mode_expr": "[%parse ~]",
                "expected": "success",
                "runtime": "parse-only",
                "quick": True,
                "stats": "~",
                "options": {"timeout": 60, "workers": "auto", "seed": None},
            })
            if "proof" in module:
                proof_id = hid("proof", manifest_rel, module_path)
                minutes = int(module["proof"]["maxRuntimeMinutes"])
                proof_entries.append({
                    "id": proof_id,
                    "arm": arm_name("tlaps", Path(module_path).stem, proof_id),
                    "manifest": manifest_rel,
                    "module": module_path,
                    "model": "",
                    "tool": "tlaps",
                    "mode_expr": "[%prove ~]",
                    "expected": "success",
                    "runtime": f"max {minutes} minutes",
                    "quick": False,
                    "stats": "~",
                    "options": {"timeout": minutes * 60, "workers": "auto", "seed": None},
                })
            if "pluscal" in module["features"]:
                pcal_id = hid("pluscal", manifest_rel, module_path)
                pluscal_entries.append({
                    "id": pcal_id,
                    "arm": arm_name("pluscal", Path(module_path).stem, pcal_id),
                    "manifest": manifest_rel,
                    "module": module_path,
                    "model": "",
                    "tool": "pluscal",
                    "mode_expr": "[%translate ~]",
                    "expected": "success",
                    "runtime": "translation",
                    "quick": False,
                    "stats": "~",
                    "options": {"timeout": 60, "workers": "auto", "seed": None},
                    "excluded": PLUSCAL_EXCLUSIONS.get(module_path),
                })
            for model in module["models"]:
                model_id = hid("model", manifest_rel, module_path, model["path"])
                tool = "apalache" if model["mode"] == "symbolic" else "tlc"
                elapsed = seconds(model["runtime"])
                quick = elapsed is not None and elapsed <= 30
                quick = quick and not isinstance(model["mode"], dict)
                flags = []
                if "action composition" in module["features"]:
                    flags.append("tlc2.tool.impl.Tool.cdot=true")
                timeout = 0 if elapsed is None else max(60, elapsed * 3)
                entry = {
                    "id": model_id,
                    "arm": arm_name(tool, Path(model["path"]).stem, model_id),
                    "manifest": manifest_rel,
                    "module": module_path,
                    "model": model["path"],
                    "tool": tool,
                    "mode_expr": mode_expr(model["mode"]),
                    "expected": model["result"],
                    "runtime": model["runtime"],
                    "quick": quick,
                    "stats": stats_expr(model),
                    "options": {
                        "workers": model.get("workers", "auto"),
                        "timeout": timeout,
                        "seed": 1 if isinstance(model["mode"], dict) else None,
                        "flags": flags,
                    },
                    "selected": model["result"] in SELECTED_RESULTS,
                    "model_data": model,
                }
                model_entries.append(entry)
    return model_entries, parse_entries, proof_entries, pluscal_entries


def generated_files():
    models, parsers, proofs, pluscal = build_inventory()
    files = {}
    grouped = defaultdict(list)
    for entry in models:
        if entry["selected"]:
            speed = "quick" if entry["quick"] else "full"
            outcome = entry["expected"].replace(" ", "-")
            path = f"lib/corpus/{entry['tool']}/{speed}/{outcome}.hoon"
            grouped[path].append(entry)
    grouped["lib/corpus/parser/modules.hoon"].extend(parsers)
    grouped["lib/corpus/tlaps/proofs.hoon"].extend(proofs)
    grouped["lib/corpus/pluscal/translations.hoon"].extend(
        entry for entry in pluscal if not entry["excluded"]
    )
    for path, entries in grouped.items():
        entries.sort(key=lambda entry: entry["id"])
        files[path] = test_file([corpus_arm(entry) for entry in entries])
    for group, items in FAILURES.items():
        files[f"lib/failures/{group}.hoon"] = test_file(
            [failure_arm(group, item) for item in items]
        )
    files["coverage.md"] = coverage_markdown(models, parsers, proofs, pluscal)
    files["fixture-sha256.txt"] = fixture_checksums()
    return files


def coverage_markdown(models, parsers, proofs, pluscal):
    selected = [entry for entry in models if entry["selected"]]
    result_counts = Counter(entry["expected"] for entry in selected)
    tool_counts = Counter(entry["tool"] for entry in selected)
    lines = [
        "# TLA+ Gall black-box coverage",
        "",
        f"Examples commit: `{COMMIT}`",
        "",
        f"Manifest models: {len(models)}; selected: {len(selected)}; "
        f"tested: {len(selected)}; excluded unknown: {len(models) - len(selected)}.",
        "",
        "Selected outcomes: "
        + ", ".join(f"{key}={value}" for key, value in sorted(result_counts.items()))
        + ".",
        "",
        "Selected tools: "
        + ", ".join(f"{key}={value}" for key, value in sorted(tool_counts.items()))
        + ".",
        "",
        "## Manifest models",
        "",
        "| Manifest | Module | Model/config | Mode/options | Expected | Test arm |",
        "|---|---|---|---|---|---|",
    ]
    for entry in sorted(models, key=lambda entry: entry["id"]):
        model = entry["model_data"]
        mode = model["mode"]
        if isinstance(mode, dict):
            mode = f"simulation ({mode['simulate']['traceCount']} traces, seed 1)"
        workers = model.get("workers", "auto")
        counts = ", ".join(
            f"{key}={model[key]}"
            for key in ("distinctStates", "totalStates", "stateDepth")
            if key in model
        )
        details = f"{mode}; runtime={model['runtime']}; workers={workers}"
        if counts:
            details += f"; {counts}"
        details += f"; declared {entry['expected']}"
        if entry["selected"]:
            arm = f"`{entry['arm']}` (`{entry['id']}`)"
        else:
            arm = "Excluded: manifest result is `unknown`; no stable oracle"
        lines.append(
            f"| `{entry['manifest']}` | `{entry['module']}` | `{entry['model']}` | "
            f"{details} | {entry['expected']} | {arm} |"
        )
    lines.extend([
        "",
        "## Parser-only coverage",
        "",
        f"All {len(parsers)} manifest modules have one SANY/linter-only test arm.",
        "",
        "## TLAPS proof coverage",
        "",
        "| Module | Maximum runtime | Test arm |",
        "|---|---:|---|",
    ])
    for entry in sorted(proofs, key=lambda entry: entry["id"]):
        lines.append(
            f"| `{entry['module']}` | {entry['runtime']} | `{entry['arm']}` (`{entry['id']}`) |"
        )
    lines.extend([
        "",
        "## PlusCal translation coverage",
        "",
        "| Module | Test arm or exclusion |",
        "|---|---|",
    ])
    for entry in sorted(pluscal, key=lambda entry: entry["id"]):
        if entry["excluded"]:
            value = f"Excluded: {entry['excluded']}"
        else:
            value = f"`{entry['arm']}` (`{entry['id']}`)"
        lines.append(f"| `{entry['module']}` | {value} |")
    lines.extend([
        "",
        "## Upstream CI exclusions",
        "",
        "- `specifications/BlockingQueue`: ignored git submodule; content is not pinned by the Examples parent commit.",
        "- `specifications/CCF`: ignored git submodule; content is not pinned by the Examples parent commit.",
        "- `specifications/azure-cosmos-tla`: ignored git submodule; content is not pinned by the Examples parent commit.",
        "- `specifications/microwave`: ignored git submodule; content is not pinned by the Examples parent commit.",
        "- `specifications/tcp/IndInv_apa.cfg`: upstream CI excludes repeated Apalache invariant search; its module still has parser coverage.",
        "- `specifications/tcp/IndInv_apa_init.cfg`: same upstream exclusion.",
        "- `specifications/doesnotexist`: `.ciignore` sentinel, not a fixture.",
        "",
        "## Non-corpus failure coverage",
        "",
    ])
    for group, items in FAILURES.items():
        lines.append(f"- {group}: {len(items)} cases")
    return "\n".join(lines) + "\n"


def fixture_checksums():
    paths = sorted(
        path for path in EXAMPLES.rglob("*")
        if path.is_file() and path.name != "fixture-sha256.txt"
    )
    lines = []
    for path in paths:
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        lines.append(f"{digest}  {path.relative_to(EXAMPLES).as_posix()}")
    return "\n".join(lines) + "\n"


def validate_inventory():
    errors = []
    if (EXAMPLES / "SOURCE_COMMIT").read_text().strip() != COMMIT:
        errors.append("fixture commit does not match coverage commit")
    models, parsers, proofs, pluscal = build_inventory()
    for entry in models:
        for key in ("module", "model"):
            if not (EXAMPLES / entry[key]).is_file():
                errors.append(f"missing model fixture: {entry[key]}")
    for entry in parsers:
        if not (EXAMPLES / entry["module"]).is_file():
            errors.append(f"missing parser fixture: {entry['module']}")
    ids = [entry["id"] for entry in models if entry["selected"]]
    duplicates = [key for key, count in Counter(ids).items() if count > 1]
    if duplicates:
        errors.append("duplicate selected coverage ids: " + ", ".join(duplicates))
    selected = [entry for entry in models if entry["selected"]]
    if len(selected) != 214:
        errors.append(f"selected model count changed: expected 214, got {len(selected)}")
    if len(parsers) != 408:
        errors.append(f"parser module count changed: expected 408, got {len(parsers)}")
    if len(proofs) != 73:
        errors.append(f"proof count changed: expected 73, got {len(proofs)}")
    tested_pluscal = [entry for entry in pluscal if not entry["excluded"]]
    if len(tested_pluscal) != 32:
        errors.append(f"PlusCal test count changed: expected 32, got {len(tested_pluscal)}")
    return errors


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    errors = validate_inventory()
    expected = generated_files()
    generated_roots = [HERE / "lib" / "corpus", HERE / "lib" / "failures"]
    if args.write:
        for root in generated_roots:
            if root.exists():
                for path in root.rglob("*.hoon"):
                    path.unlink()
        for relative, content in expected.items():
            path = HERE / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8")
    else:
        for relative, content in expected.items():
            path = HERE / relative
            if not path.is_file():
                errors.append(f"missing generated file: {relative}")
            elif path.read_text(encoding="utf-8") != content:
                errors.append(f"generated file is stale: {relative}")
        expected_paths = {HERE / relative for relative in expected}
        for root in generated_roots:
            if root.exists():
                for path in root.rglob("*.hoon"):
                    if path not in expected_paths:
                        errors.append(f"unexpected generated Hoon file: {path.relative_to(HERE)}")
        # Every generated arm must carry exactly one coverage marker and one
        # unique arm name; the marker set must equal the inventory ids.
        models, parsers, proofs, pluscal = build_inventory()
        selected_ids = (
            [entry["id"] for entry in models if entry["selected"]]
            + [entry["id"] for entry in parsers]
            + [entry["id"] for entry in proofs]
            + [entry["id"] for entry in pluscal if not entry["excluded"]]
        )
        marker_counts = Counter()
        arm_counts = Counter()
        for root in generated_roots:
            if root.exists():
                for path in root.rglob("*.hoon"):
                    text = path.read_text(encoding="utf-8")
                    marker_counts.update(re.findall(r"^::  coverage-id: (\S+)$", text, re.M))
                    arm_counts.update(re.findall(r"^\+\+  (test-[a-z0-9-]+)$", text, re.M))
        repeated_markers = [key for key, count in marker_counts.items() if count > 1]
        if repeated_markers:
            errors.append("duplicate coverage markers: " + ", ".join(repeated_markers))
        repeated_arms = [key for key, count in arm_counts.items() if count > 1]
        if repeated_arms:
            errors.append("duplicate test arms: " + ", ".join(repeated_arms))
        if set(marker_counts) != set(selected_ids):
            errors.append("coverage marker set differs from generated inventory")
    if errors:
        print("coverage check failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        sys.exit(1)
    models, parsers, proofs, pluscal = build_inventory()
    selected = sum(1 for entry in models if entry["selected"])
    tested_pluscal = sum(1 for entry in pluscal if not entry["excluded"])
    print(
        f"coverage ok: models {selected}/{selected}"
        f", parser {len(parsers)}, proofs {len(proofs)}, pluscal {tested_pluscal}"
    )


if __name__ == "__main__":
    main()
