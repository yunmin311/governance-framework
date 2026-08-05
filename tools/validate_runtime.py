#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Validate the runtime minimal-loading layer (v2.2.1, G4).

Dependency-free (no pyyaml). Non-whitespace character counting.
Exit code 0 on full PASS, 1 on any failure.
"""
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

FAILS = []
OKS = []


def rp(*parts):
    return os.path.join(REPO, *parts)


def read(path):
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def nonws(text):
    return len("".join(text.split()))


def check(cond, ok_msg, fail_msg):
    if cond:
        OKS.append(ok_msg)
    else:
        FAILS.append(fail_msg)
    return cond


# ---- 1. character budgets ------------------------------------------------
CAPS = {
    "runtime/00-entry.md": 1200,
    "runtime/01-core-rules.md": 3500,
    "runtime/02-user-runtime-profile.md": 2000,
}
total = 0
for rel, cap in CAPS.items():
    p = rp(*rel.split("/"))
    if not os.path.exists(p):
        FAILS.append("MISSING runtime file: %s" % rel)
        continue
    n = nonws(read(p))
    total += n
    check(n <= cap, "%s = %d chars (<= %d)" % (rel, n, cap),
          "OVER BUDGET: %s = %d chars (cap %d)" % (rel, n, cap))
check(total <= 8000, "runtime total = %d chars (<= 8000)" % total,
      "OVER BUDGET: runtime total = %d chars (cap 8000)" % total)

# ---- 2. parse router.yaml (indentation-based mini parser) ----------------
router_path = rp("runtime", "router.yaml")
router_txt = read(router_path) if os.path.exists(router_path) else ""
if not router_txt:
    FAILS.append("MISSING runtime/router.yaml")

MODES = ("QUICK", "NORMAL", "STRUCTURAL", "INCIDENT")
FORBIDDEN_TOKENS = ("archive/", "docs/", "reviews/", "published/",
                    "releases/", ".pdf", ".docx", ".zip")

# collect list items grouped by (mode, key)
lists = {}
cur_mode = None
cur_key = None
for line in router_txt.splitlines():
    m = re.match(r"^  ([A-Z]+):\s*$", line)
    if m and m.group(1) in MODES:
        cur_mode = m.group(1)
        cur_key = None
        continue
    k = re.match(r"^    ([a-z_]+):\s*(.*)$", line)
    if k and cur_mode:
        cur_key = k.group(1)
        lists.setdefault((cur_mode, cur_key), [])
        continue
    item = re.match(r"^      - (.*)$", line)
    if item and cur_mode and cur_key:
        lists[(cur_mode, cur_key)].append(item.group(1).split("#")[0].strip())

# 2a. QUICK default file count
qd = lists.get(("QUICK", "default_files"), [])
check(len(qd) <= 5, "QUICK default_files = %d (<= 5)" % len(qd),
      "QUICK default_files = %d (> 5)" % len(qd))

# 2b. QUICK & NORMAL default_files must not include forbidden top paths
for mode in ("QUICK", "NORMAL"):
    df = lists.get((mode, "default_files"), [])
    bad = [x for x in df for t in FORBIDDEN_TOKENS if t in x]
    check(not bad, "%s default_files clean of archive/docs/reviews/published/releases/PDF/DOCX/ZIP" % mode,
          "%s default_files contains forbidden path(s): %s" % (mode, bad))

# 2c. ponytail must not be in any mode's default/optional files
pony = []
for (mode, key), items in lists.items():
    if key in ("default_files", "optional_files"):
        pony += [x for x in items if "ponytail" in x.lower()]
check(not pony, "no Ponytail in any default/optional route",
      "Ponytail found in a runtime route: %s" % pony)

# 2d. archive/ not referenced in any default_files
arch = []
for (mode, key), items in lists.items():
    if key == "default_files":
        arch += [x for x in items if x.startswith("archive/")]
check(not arch, "no archive/ file in any default_files",
      "archive/ referenced by a default route: %s" % arch)

# ---- 3. rule IDs unique + traceable --------------------------------------
core_rules = read(rp("runtime", "01-core-rules.md")) if os.path.exists(rp("runtime", "01-core-rules.md")) else ""
ids = re.findall(r"GOV-\d{3}", core_rules)
dupes = sorted({i for i in ids if ids.count(i) > 1})
check(ids and not dupes, "%d rule IDs, all unique" % len(set(ids)),
      "duplicate rule IDs: %s" % dupes)

trace_path = rp("migration", "rule-traceability.yaml")
trace_txt = read(trace_path) if os.path.exists(trace_path) else ""
if not trace_txt:
    FAILS.append("MISSING migration/rule-traceability.yaml")
else:
    missing = [i for i in sorted(set(ids)) if i not in trace_txt]
    check(not missing, "every rule ID traceable in rule-traceability.yaml",
          "rule IDs missing from traceability: %s" % missing)

# ---- report --------------------------------------------------------------
print("=== validate_runtime.py ===")
for o in OKS:
    print("  PASS", o)
for f in FAILS:
    print("  FAIL", f)
print("--- %d passed, %d failed ---" % (len(OKS), len(FAILS)))
sys.exit(1 if FAILS else 0)
