"""Conservative reproducible source inventory; excludes tests/examples/generated files."""
import json
from pathlib import Path
import re
import subprocess

root = Path(__file__).resolve().parents[1]
rows = []
for path in sorted(root.glob("*.mbt")):
    if path.name.endswith(("_test.mbt", "_wbtest.mbt")):
        continue
    lines = path.read_text(encoding="utf-8").splitlines()
    code = sum(bool(x.strip()) and not x.lstrip().startswith("//") for x in lines)
    rows.append({"file": path.name, "physical": len(lines), "nonblank_noncomment": code})
total = sum(x["physical"] for x in rows)
conservative = sum(x["nonblank_noncomment"] for x in rows)
assert conservative >= 1500, "substantive production threshold not met"
tests = sum(len(re.findall(r'^test "', p.read_text(encoding="utf-8"), re.M))
            for p in root.glob("*.mbt") if p.name.endswith(("_test.mbt", "_wbtest.mbt")))
print(json.dumps({"files": rows, "production_physical_lines": total,
                  "production_nonblank_noncomment_lines": conservative,
                  "test_cases": tests}, indent=2))
