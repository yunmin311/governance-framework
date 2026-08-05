#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Release-layer validator (v2.2.3).

Checks:
  1. every *.yaml / *.yml in the tree parses (catches invalid YAML);
  2. shipped entry docs contain no stale Chinese zip-folder names (框架/ 个人实例/ 文档/);
  3. VERSIONS.md declares the three version dimensions;
  4. if a release zip is present, its RELEASE-MANIFEST matches (files present, sha256 + bytes).
Exit 0 on PASS, 1 on any failure. Requires pyyaml for the YAML check.
"""
import hashlib
import os
import re
import sys
import zipfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FAILS = []
OKS = []

try:
    import yaml
except Exception:
    yaml = None


def read(p, b=False):
    mode = "rb" if b else "r"
    kw = {} if b else {"encoding": "utf-8", "errors": "replace"}
    with open(p, mode, **kw) as f:
        return f.read()


# ---- 1. every YAML parses -------------------------------------------------
if yaml is None:
    FAILS.append("pyyaml not available -> cannot validate YAML files")
else:
    n = 0
    for root, dirs, files in os.walk(REPO):
        if os.sep + ".git" in root:
            continue
        for fn in files:
            if fn.lower().endswith((".yaml", ".yml")):
                p = os.path.join(root, fn)
                rel = os.path.relpath(p, REPO)
                try:
                    yaml.safe_load(read(p))
                    n += 1
                except Exception as e:
                    FAILS.append("YAML parse FAIL: %s -> %s" % (rel, str(e).splitlines()[0]))
    if not any(f.startswith("YAML parse") for f in FAILS):
        OKS.append("%d YAML files parse cleanly" % n)

# ---- 2. no stale Chinese zip-folder names in shipped entry docs -----------
ENTRY_DOCS = [
    "README.md", "00-从这里开始.md", "portable/README.md",
    "分层导航-复用层与本机层.md", "profiles/machines/README.md",
    "projects/README.md", "projects/instances/README.md",
]
STALE = ("框架/", "个人实例/", "文档/PDF", "文档/DOCX", "启动器/")
stale_hits = {}
for rel in ENTRY_DOCS:
    p = os.path.join(REPO, *rel.split("/"))
    if not os.path.exists(p):
        continue
    txt = read(p)
    hits = [t for t in STALE if t in txt]
    if hits:
        stale_hits[rel] = hits
if stale_hits:
    for rel, hits in stale_hits.items():
        FAILS.append("stale zip-folder name in %s: %s (use framework/ instance-example/ documents/)" % (rel, hits))
else:
    OKS.append("entry docs free of stale Chinese zip-folder names")

# ---- 3. VERSIONS.md declares three dimensions -----------------------------
vpath = os.path.join(REPO, "VERSIONS.md")
if not os.path.exists(vpath):
    FAILS.append("VERSIONS.md missing (must declare governance-spec / engineering-wiring / release-package)")
else:
    vtxt = read(vpath)
    need = ["governance-spec", "engineering-wiring", "release-package", "v2.2", "v2.2.1", "v2.2.3"]
    miss = [x for x in need if x not in vtxt]
    if miss:
        FAILS.append("VERSIONS.md missing markers: %s" % miss)
    else:
        OKS.append("VERSIONS.md declares all three version dimensions")

# ---- 4. release zip manifest integrity (if a zip is present) --------------
rel_dir = os.path.join(REPO, "releases")
zips = []
if os.path.isdir(rel_dir):
    zips = sorted(f for f in os.listdir(rel_dir) if f.endswith(".zip") and "v2.2.3" in f)
if not zips:
    OKS.append("no v2.2.3 release zip present -> manifest check skipped (framework-layer run)")
else:
    zp = os.path.join(rel_dir, zips[-1])
    with zipfile.ZipFile(zp) as z:
        names = set(z.namelist())
        if "RELEASE-MANIFEST.yaml" not in names:
            FAILS.append("%s: RELEASE-MANIFEST.yaml missing from zip" % zips[-1])
        elif yaml is None:
            FAILS.append("cannot verify manifest without pyyaml")
        else:
            man = yaml.safe_load(z.read("RELEASE-MANIFEST.yaml"))
            bad = 0
            for item in man.get("files", []):
                ap = item["path"]
                if ap not in names:
                    FAILS.append("manifest lists missing file: %s" % ap); bad += 1; continue
                data = z.read(ap)
                if hashlib.sha256(data).hexdigest() != item["sha256"]:
                    FAILS.append("sha256 mismatch: %s" % ap); bad += 1
                elif len(data) != item["bytes"]:
                    FAILS.append("bytes mismatch: %s" % ap); bad += 1
            if not bad:
                OKS.append("%s: manifest integrity OK (%d files)" % (zips[-1], len(man.get("files", []))))

print("=== validate_release.py ===")
for o in OKS:
    print("  PASS", o)
for f in FAILS:
    print("  FAIL", f)
print("--- %d passed, %d failed ---" % (len(OKS), len(FAILS)))
sys.exit(1 if FAILS else 0)
