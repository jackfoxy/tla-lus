#!/usr/bin/env bash
# R4.0a: the three module trees upstream Examples CI puts on the module path,
# plus tlauc (Unicode clause 8), pinned to what CI would have fetched on
# 2026-05-24 -- the Examples pin's date. CI fetches `releases/latest` (and
# tlapm `main`), so the pin is the last release (or main commit) on or before
# that date. THE RELEASE ARTIFACT, not the repo tree, is the oracle: the
# CommunityModules repo carries modules (Quorum*, GraphTheorems*) its release
# jar does not ship.
#
# This file is the single source of these pins. tools/check-portmap.py reads
# the PIN_* lines and checks port-map.md §1, testing.md and compatibility.md
# against them.
#
# Usage: tools/r4-deps.sh [--fetch]   (default: verify only)
set -euo pipefail

DEPS="${R4_DEPS:-/mnt/mars/gitrepos/r4-deps}"
SRC="${R4_SRC:-/mnt/mars/gitrepos}"

PIN_COMMUNITY_TAG="202604221529"
PIN_COMMUNITY_COMMIT="a20cc8eb2ee6e7140848ca511040cf283e9d7256"
PIN_COMMUNITY_SHA256="b074c4c507b84b4a92fafba1f543efe76a7bbef3a08877362c7f9c96d078b6a8"
PIN_TLAPM_COMMIT="fd3988fc4e930565e0fa118158055448673dbcd2"
PIN_APALACHE_TAG="v0.57.1"
PIN_APALACHE_COMMIT="a9d9f8267db1c9d24f864eaf7610450496447f25"
PIN_APALACHE_SHA256="ab2731643411fe16d0b611f4f49a692ff6165ad97d44f7fa927d9517b6c37c9b"
PIN_TLAUC_TAG="1.1.0"
PIN_TLAUC_COMMIT="a4f21b9fc0891341f0b1ec56c88e08514bab101d"
PIN_TLAUC_SHA256="54927abef7521291abe136ab1a8212edd68bc1378d40d5b95c103b9a200aeb61"

fail=0
bad() { echo "FAIL: $*"; fail=1; }
ok()  { echo "ok:   $*"; }

fetch() {
  mkdir -p "$DEPS"
  cd "$DEPS"
  [ -f CommunityModules-deps.jar ] || wget -nv \
    "https://github.com/tlaplus/CommunityModules/releases/download/$PIN_COMMUNITY_TAG/CommunityModules-deps.jar"
  [ -f apalache.tgz ] || wget -nv \
    "https://github.com/apalache-mc/apalache/releases/download/$PIN_APALACHE_TAG/apalache.tgz"
  [ -f tlauc-linux.tar.gz ] || wget -nv \
    "https://github.com/tlaplus-community/tlauc/releases/download/$PIN_TLAUC_TAG/tlauc-linux.tar.gz"
  [ -f apalache/lib/apalache.jar ] || tar -xzf apalache.tgz apalache/lib/apalache.jar
  [ -x tlauc ] || tar -xzf tlauc-linux.tar.gz
  for r in tlaplus/CommunityModules tlaplus/tlapm apalache-mc/apalache tlaplus-community/tlauc; do
    [ -d "$SRC/${r#*/}" ] || git clone -q --filter=blob:none "https://github.com/$r.git" "$SRC/${r#*/}"
  done
  cd - >/dev/null
}

sha() {
  local f="$DEPS/$1" want="$2"
  if [ ! -f "$f" ]; then bad "$1 missing (run with --fetch)"; return; fi
  local got; got=$(sha256sum "$f" | cut -d' ' -f1)
  [ "$got" = "$want" ] && ok "$1 sha256" || bad "$1 sha256 $got != $want"
}

tagis() {
  local repo="$SRC/$1" ref="$2" want="$3"
  if [ ! -d "$repo" ]; then bad "$1 checkout missing (run with --fetch)"; return; fi
  local got; got=$(git -C "$repo" rev-parse "$ref^{commit}" 2>/dev/null || echo none)
  [ "$got" = "$want" ] && ok "$1 $ref = ${want:0:9}" || bad "$1 $ref = $got, want $want"
}

[ "${1:-}" = "--fetch" ] && fetch

sha CommunityModules-deps.jar "$PIN_COMMUNITY_SHA256"
sha apalache.tgz "$PIN_APALACHE_SHA256"
sha tlauc-linux.tar.gz "$PIN_TLAUC_SHA256"
tagis CommunityModules "$PIN_COMMUNITY_TAG" "$PIN_COMMUNITY_COMMIT"
tagis tlapm "$PIN_TLAPM_COMMIT" "$PIN_TLAPM_COMMIT"
tagis apalache "$PIN_APALACHE_TAG" "$PIN_APALACHE_COMMIT"
tagis tlauc "$PIN_TLAUC_TAG" "$PIN_TLAUC_COMMIT"

# The jar's .tla set must equal the tag's modules/ tree (the jar is the
# oracle; this proves the commit we cite is the one it was built from).
if [ -f "$DEPS/CommunityModules-deps.jar" ] && [ -d "$SRC/CommunityModules" ]; then
  a=$(unzip -Z1 "$DEPS/CommunityModules-deps.jar" | grep '\.tla$' | sort)
  b=$(git -C "$SRC/CommunityModules" ls-tree --name-only "$PIN_COMMUNITY_TAG" modules/ \
        | grep '\.tla$' | sed 's,^modules/,,' | sort)
  [ "$a" = "$b" ] && ok "CommunityModules jar .tla set = tag modules/ ($(echo "$a" | wc -l) files)" \
                  || bad "CommunityModules jar .tla set differs from tag modules/"
fi

# Same for Apalache: every jar StandardModule that the tag's src/tla also
# carries must be byte-identical to it.
if [ -f "$DEPS/apalache/lib/apalache.jar" ] && [ -d "$SRC/apalache" ]; then
  n=0; d=0
  for f in $(git -C "$SRC/apalache" ls-tree --name-only "$PIN_APALACHE_TAG" src/tla/ | grep '\.tla$'); do
    m=${f#src/tla/}
    if unzip -Z1 "$DEPS/apalache/lib/apalache.jar" "tla2sany/StandardModules/$m" >/dev/null 2>&1; then
      n=$((n+1))
      cmp -s <(unzip -p "$DEPS/apalache/lib/apalache.jar" "tla2sany/StandardModules/$m") \
             <(git -C "$SRC/apalache" show "$PIN_APALACHE_TAG:$f") || { d=1; bad "apalache $m: jar != tag"; }
    fi
  done
  [ $d = 0 ] && ok "Apalache jar StandardModules = tag src/tla ($n files)"
fi

exit $fail
