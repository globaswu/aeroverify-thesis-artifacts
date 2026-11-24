"""Check the published package without solver software."""
from collections import Counter
from pathlib import Path
import csv
import hashlib
import math

ROOT = Path(__file__).resolve().parent

def read_rows(name):
    with (ROOT / name).open(encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))

for line in (ROOT/"checksums.sha256").read_text(encoding="utf-8").splitlines():
    expected, relative = line.split("  ", 1)
    target = (ROOT/relative).resolve()
    assert target.is_relative_to(ROOT)
    with target.open("rb") as stream:
        assert hashlib.file_digest(stream, "sha256").hexdigest() == expected, relative

cases = read_rows("casewise_stress.csv")
assert Counter(r["study"] for r in cases) == {"FCC":71,"BCC":71,"SC":71,"Planform":50,"Four-input":100}
assert len({(r["study"],r["case_id"]) for r in cases}) == 363
for limit, count in ((220,327),(184,305)):
    assert sum(r[f"pass_{limit}_MPa"]=="True" for r in cases)==count
    for row in cases:
        peak = max(float(row[k]) for k in ("reevaluation_beam_peak_MPa","reevaluation_skin_peak_MPa"))
        assert (peak<=limit)==(row[f"pass_{limit}_MPa"]=="True")

parents = read_rows("refinement/joint_refinements.csv")
assert len(parents)==26 and len({r["variant"] for r in parents})==26
assert sum(r["on_combined_184_front"]=="True" for r in parents)==12
responses = read_rows("refinement/trim_response_samples.csv")
for row in parents:
    lo,hi = sorted((r for r in responses if r["variant"]==row["variant"] and r["is_trim_bracket"]=="True"),
                   key=lambda r: float(r["incidence_deg"]))
    w = float(lo["interpolation_fraction"])
    energy = float(lo["half_wing_strain_energy_Nm"])*(1-w)+float(hi["half_wing_strain_energy_Nm"])*w
    assert math.isclose(float(row["trim_compliance_Nm"]),4*energy,abs_tol=5e-5)

for name, positive in (("BCC033",0),("FCC018",9)):
    roots = read_rows(f"refinement/{name}_PK_roots.csv")
    assert len(roots)==980
    assert sum(float(r["g"])>0 for r in roots)==positive
print("Verified file hashes, 363 stress records, 26 refinements, and both 980-row PK tables.")
