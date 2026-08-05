#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Validate path/canonical wiring for active entry documents (v2.2.1, G1).

Checks:
  1. repo-relative path references in active entry docs actually exist;
  2. no active entry references a stale Chinese-dir repo path (启动器/ 框架/ 个人实例/) as a real path;
  3. exactly one active editable canonical for charter / router / user profile;
  4. release/published artifacts are not loaded as canonical by the runtime layer.
Exit code 0 on PASS, 1 on any failure.
"""
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FAILS = []
OKS = []


def rp(*p):
    return os.path.join(REPO, *p)


def read(path):
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        return f.read()


# active entry documents whose path references must resolve
ACTIVE = [
    "runtime/00-entry.md", "runtime/01-core-rules.md",
    "runtime/02-user-runtime-profile.md", "runtime/router.yaml",
    "README.md", "00-从这里开始.md", "AGENTS.md",
    "core/01-governance-charter-v2.md",
    "profiles/user/user-profile.template.md",
    "adapters/codex/README.md", "adapters/claude/README.md",
    "adapters/generic/README.md",
    "skills/global-ai-dialogue-governor/SKILL.md",
]
for pat in ("launchers",):
    d = rp(pat)
    if os.path.isdir(d):
        for fn in os.listdir(d):
            if fn.endswith(".txt"):
                ACTIVE.append("%s/%s" % (pat, fn))

TOP = ("core|runtime|launchers|projects|profiles|templates|skills|registry|"
       "adapters|reviews|docs|tools|scripts|archive|published|releases|migration")
# stop the path at whitespace, quotes, brackets, and CJK punctuation
PATH_RE = re.compile(r"(?:%s)(?:/[^\s`'\"()\[\]，、。：；（）【】《》「」〈〉]+)+" % TOP)
STRIP = ".,)]}`'\"，、。：；（）【】《》"
EXT = (".md", ".txt", ".yaml", ".yml", ".py", ".ps1", ".json",
       ".html", ".htm", ".docx", ".pdf", ".zip", ".png")

missing = {}
for rel in ACTIVE:
    p = rp(*rel.split("/"))
    if not os.path.exists(p):
        continue
    txt = read(p)
    for raw in PATH_RE.findall(txt):
        ref = raw.rstrip(STRIP)
        if any(c in ref for c in "<>*"):
            continue  # placeholder or glob
        if ref.endswith("/"):
            if not os.path.isdir(rp(*ref.rstrip("/").split("/"))):
                missing.setdefault(rel, set()).add(ref)
            continue
        # only validate references that name a concrete file (known extension);
        # bare shorthand like "core/01 §1.1" is prose, not a path claim
        if not ref.lower().endswith(EXT):
            continue
        if not os.path.exists(rp(*ref.split("/"))):
            missing.setdefault(rel, set()).add(ref)

if missing:
    for rel, refs in sorted(missing.items()):
        FAILS.append("%s -> broken path refs: %s" % (rel, sorted(refs)))
else:
    OKS.append("all resolvable path references in active docs exist")

# 2. stale Chinese-dir *repo* references (real path form only, dir/ + filename)
STALE_RE = re.compile(r"(?:启动器|框架|个人实例)/[A-Za-z0-9一-鿿._-]+\.(?:md|txt|ya?ml|py)")
stale = {}
for rel in ACTIVE:
    p = rp(*rel.split("/"))
    if not os.path.exists(p):
        continue
    hits = STALE_RE.findall(read(p))
    if hits:
        stale[rel] = hits
if stale:
    for rel, hits in stale.items():
        FAILS.append("%s references stale Chinese-dir repo path: %s" % (rel, hits))
else:
    OKS.append("no active doc references stale 启动器/框架/个人实例 repo paths")

# 3. single active editable canonical (outside archive/)
def find(name_re):
    out = []
    for root, dirs, files in os.walk(REPO):
        if ".git" in root or os.sep + "archive" in root:
            continue
        for fn in files:
            if re.search(name_re, fn):
                out.append(os.path.relpath(os.path.join(root, fn), REPO))
    return out

for label, rx, want in [
    ("charter", r"governance-charter-v2\.md$", 1),
    ("router", r"^router\.yaml$", 1),
    ("user-profile", r"^user-profile.template\.md$", 1),
]:
    hits = find(rx)
    if len(hits) == want:
        OKS.append("single active canonical for %s: %s" % (label, hits[0]))
    else:
        FAILS.append("expected %d active canonical for %s, found %d: %s"
                     % (want, label, len(hits), hits))

# 4. runtime layer must not load a release/published artifact as canonical
router = read(rp("runtime", "router.yaml")) if os.path.exists(rp("runtime", "router.yaml")) else ""
leak = re.findall(r"(?:published|releases)/[^\s]+|\.(?:zip|docx|pdf)\b",
                  "\n".join(l for l in router.splitlines()
                            if l.strip().startswith("- ") and "forbidden" not in l))
# only flag if they appear as list ITEMS in default_files/optional_files, not in forbidden lists
bad_leak = []
mode = key = None
for line in router.splitlines():
    m = re.match(r"^  ([A-Z]+):\s*$", line)
    if m:
        mode = m.group(1); key = None; continue
    k = re.match(r"^    ([a-z_]+):", line)
    if k:
        key = k.group(1); continue
    it = re.match(r"^      - (.*)$", line)
    if it and key in ("default_files", "optional_files"):
        v = it.group(1)
        if re.search(r"published/|releases/|\.zip|\.docx|\.pdf", v):
            bad_leak.append("%s.%s: %s" % (mode, key, v))
if bad_leak:
    FAILS.append("release/published artifact loaded as runtime source: %s" % bad_leak)
else:
    OKS.append("no release/published artifact loaded by runtime layer")

print("=== validate_paths.py ===")
for o in OKS:
    print("  PASS", o)
for f in FAILS:
    print("  FAIL", f)
print("--- %d passed, %d failed ---" % (len(OKS), len(FAILS)))
sys.exit(1 if FAILS else 0)
