"""Recalculate compact structural outcome tables using adjacent CSV inputs only.

Python standard library only. This reproduces arithmetic on stored numerical
results; it does not rerun structural, aerodynamic, or geometry solvers.
"""
from pathlib import Path
import csv
import math
from statistics import median

BASE = Path(__file__).resolve().parent
CHECKS = 0


def read(name):
    with (BASE / name).open(encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))


def write(name, rows):
    assert rows, name
    with (BASE / name).open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def num(row, key):
    value = float(row[key])
    assert math.isfinite(value), (key, value)
    return value


def close(actual, expected, label):
    global CHECKS
    # Public source exports retain finite decimal precision.
    assert math.isclose(actual, expected, rel_tol=1e-10, abs_tol=1e-8), (label, actual, expected)
    CHECKS += 1


def unique(rows, keys):
    values = [tuple(row[k] for k in keys) for row in rows]
    assert len(values) == len(set(values)), keys


def trapezoid(x, y):
    return sum((x[i+1]-x[i])*(y[i+1]+y[i])/2 for i in range(len(x)-1))


def geometry(row):
    area = num(row, "FullWingArea_m2")
    aspect = num(row, "AR")
    taper = num(row, "TaperRatio")
    semispan = math.sqrt(area*aspect)/2
    root_chord = area/(semispan*(1+taper))
    a = num(row, "CellSize_m")
    root = a*num(row, "RootRatio")
    tip = root*num(row, "TipRootRatio")
    if row.get("RecordedSemispan_m"):
        close(semispan, num(row, "RecordedSemispan_m"), "semispan")
        close(root_chord, num(row, "RecordedRootChord_m"), "root chord")
    return dict(AR=aspect, TaperRatio=taper, CellSize_m=a,
                RootRatio=num(row,"RootRatio"), TipRootRatio=num(row,"TipRootRatio"),
                FullWingArea_m2=area, Semispan_m=semispan, RootChord_m=root_chord,
                TipChord_m=root_chord*taper, NominalRootDiameter_mm=1000*root,
                NominalTipDiameter_mm=1000*tip,
                AreaCentroid_m=semispan*(1+2*taper)/(3*(1+taper)))


def outcomes(row, components=True):
    result = {"Case": int(row["Case"]), **geometry(row)}
    mass = num(row,"WingMassTotal_kg")
    result.update(WingMassTotal_kg=mass, Ctrim_Nm=num(row,"Ctrim_Nm"))
    if row.get("CDitrim"):
        result["CDitrim"] = num(row,"CDitrim")
    if components:
        skin, lattice = num(row,"SkinMassHalf_kg"), num(row,"LatticeMassHalf_kg")
        close(2*(skin+lattice), mass, "component mass sum")
        result.update(SkinMassTwoWing_kg=2*skin, LatticeMassTwoWing_kg=2*lattice,
                      SkinMassFraction_pct=100*skin/(skin+lattice))
    if row.get("TrimStrainEnergyHalf_Nm"):
        close(4*num(row,"TrimStrainEnergyHalf_Nm"), result["Ctrim_Nm"], "trim energy to compliance")
    skin_stress, lattice_stress = num(row,"ScreenSkinVM_MPa"), num(row,"ScreenBeamNormal_MPa")
    maximum = max(skin_stress,lattice_stress)
    limit = num(row,"StressLimit_MPa")
    result.update(ScreenSkinVM_MPa=skin_stress, ScreenBeamNormal_MPa=lattice_stress,
                  GoverningComponent="skin" if skin_stress>=lattice_stress else "lattice",
                  ScreenUtilization=maximum/limit, ScreenReserve_pct=100*(1-maximum/limit),
                  ScreenStressMargin_MPa=limit-maximum, Feasible=row["Feasible"],
                  Origin=row["Origin"], FlutterBasis=row["FlutterBasis"])
    return result


topology = read("source_topology.csv")
planform = read("source_planform.csv")
coupled = read("source_coupled_designs.csv")
components = {int(r["Case"]):r for r in read("source_coupled_components.csv")}
physics = {int(r["Case"]):r for r in read("source_coupled_trim.csv")}
samples = read("source_coupled_llt_samples.csv")
unique(topology, ("Family","Case"))
unique(planform, ("Case",))
unique(coupled, ("Case",))
assert len(topology)==8 and len(planform)==3 and len(coupled)==19

topology_results=[]
for row in topology:
    out={"Family":row["Family"], **outcomes(row)}
    out.update(C_signed_recorded=num(row,"C_signed_recorded"),
               FamilyPareto=row["FamilyPareto"], PooledPareto=row["PooledPareto"],
               SelectionSource=row["SelectionSource"])
    topology_results.append(out)
write("chapter05_topology_outcomes.csv",topology_results)

planform_results=[]
for row in planform:
    out=outcomes(row)
    out.update(C_signed_recorded=num(row,"C_signed_recorded"), Pareto=row["Pareto"],
               SelectionSource=row["SelectionSource"])
    planform_results.append(out)
write("chapter05_planform_outcomes.csv",planform_results)

coupled_by_case={int(r["Case"]):r for r in coupled}
coupled_results=[]
load_results=[]
for case in (4,37,64,99):
    row={**coupled_by_case[case],**components[case]}
    out=outcomes(row)
    out.update(Pareto=row["Pareto"],MeshControls=row["MeshControls"])
    p=physics[case]
    for field in ("MaxAbsTrimTwist_deg","MaxAbsTrimVerticalDisplacement_m",
                  "MaxTrimSkinVM_MPa","MaxTrimCbeamNormalStress_MPa","Mode1Frequency_Hz"):
        out[field]=num(p,field)
    profile=sorted((r for r in samples if int(r["Case"])==case),key=lambda r:num(r,"NormalizedSemispan"))
    assert len(profile)==401
    eta=[num(r,"NormalizedSemispan") for r in profile]
    close(eta[0],0,"root profile coordinate")
    close(eta[-1],1,"tip profile coordinate")
    assert all(a<b for a,b in zip(eta,eta[1:]))
    y=[v*out["Semispan_m"] for v in eta]
    lift=[num(r,"LiftPerUnitSpan_N_m") for r in profile]
    total=trapezoid(y,lift)
    moment=trapezoid(y,[a*b for a,b in zip(y,lift)])
    close(moment,num(p,"RecordedRootLLTAeroMoment_Nm"),"integrated LLT aerodynamic moment")
    centroid=moment/total
    displacement_ratio=out["MaxAbsTrimVerticalDisplacement_m"]/out["Semispan_m"]
    out.update(HalfWingLLTLift_N=total,RootLLTAeroMoment_Nm=moment,
               LiftCentroid_m=centroid,LiftCentroidOverSemispan=centroid/out["Semispan_m"],
               MaxAbsTrimVerticalDisplacementOverSemispan=displacement_ratio)
    coupled_results.append(out)
    load_results.append(dict(Case=case,HalfWingLLTLift_N=total,RootLLTAeroMoment_Nm=moment,
                             LiftCentroid_m=centroid,LiftCentroidOverSemispan=centroid/out["Semispan_m"],
                             MaxAbsTrimVerticalDisplacementOverSemispan=displacement_ratio,
                             MomentScope="LLT aerodynamic integral; not a finite element internal resultant"))
write("chapter06_representative_outcomes.csv",coupled_results)
write("chapter06_load_diagnostics.csv",load_results)

comparisons=[]
def compare(campaign,first,last,fields):
    for key in fields:
        before,after=first[key],last[key]
        comparisons.append(dict(Campaign=campaign,FromCase=first["Case"],ToCase=last["Case"],
                                Quantity=key,FromValue=before,ToValue=after,
                                Change=after-before,Ratio=after/before,Change_pct=100*(after/before-1)))

structural_fields=("CellSize_m","RootRatio","NominalRootDiameter_mm","WingMassTotal_kg",
                   "LatticeMassTwoWing_kg","Ctrim_Nm","ScreenSkinVM_MPa","ScreenBeamNormal_MPa")
topo={(r["Family"],r["Case"]):r for r in topology_results}
for family,a,b in (("FCC",26,70),("FCC",61,70),("FCC",40,70),("BCC",17,58),("SC",53,70)):
    compare(family,topo[(family,a)],topo[(family,b)],structural_fields)
plan={r["Case"]:r for r in planform_results}
for a,b in ((45,20),(45,47),(47,20)):
    compare("Planform",plan[a],plan[b],("Semispan_m","RootChord_m","WingMassTotal_kg",
            "SkinMassTwoWing_kg","LatticeMassTwoWing_kg","CDitrim","Ctrim_Nm",
            "ScreenSkinVM_MPa","ScreenBeamNormal_MPa","AreaCentroid_m"))
multi={r["Case"]:r for r in coupled_results}
for a,b in ((4,37),(4,64),(4,99),(37,64),(64,99),(37,99)):
    compare("Coupled",multi[a],multi[b],("Semispan_m","RootChord_m","NominalRootDiameter_mm",
            "NominalTipDiameter_mm","WingMassTotal_kg","SkinMassTwoWing_kg","LatticeMassTwoWing_kg",
            "CDitrim","Ctrim_Nm","ScreenUtilization","HalfWingLLTLift_N","RootLLTAeroMoment_Nm",
            "LiftCentroid_m","LiftCentroidOverSemispan","MaxAbsTrimVerticalDisplacement_m"))
write("design_comparisons.csv",comparisons)

corners=[r for r in coupled if int(r["Case"])<=16]
assert len(corners)==16 and all(r["Origin"]=="corner" for r in corners)
inputs=("AR","TaperRatio","RootRatio","TipRootRatio")
metrics=("WingMassTotal_kg","CDitrim","Ctrim_Nm","ScreenUtilization")
corner_results={int(r["Case"]):outcomes(r,components=False) for r in corners}
pairs=[]
for varied in inputs:
    for lo in corners:
        for hi in corners:
            if num(hi,varied)>num(lo,varied) and all(num(hi,k)==num(lo,k) for k in inputs if k!=varied):
                a,b=corner_results[int(lo["Case"])],corner_results[int(hi["Case"])]
                row=dict(ChangedInput=varied,LowCase=a["Case"],HighCase=b["Case"],
                         LowInput=num(lo,varied),HighInput=num(hi,varied),
                         LowFeasible=a["Feasible"],HighFeasible=b["Feasible"])
                row.update({"Fixed_"+k:("varied" if k==varied else num(lo,k)) for k in inputs})
                for metric in metrics:
                    row.update({"Low_"+metric:a[metric],"High_"+metric:b[metric],
                                "Ratio_"+metric:b[metric]/a[metric],
                                "Change_pct_"+metric:100*(b[metric]/a[metric]-1)})
                pairs.append(row)
assert len(pairs)==32
write("chapter06_corner_pairs.csv",pairs)
summary=[]
for varied in inputs:
    group=[r for r in pairs if r["ChangedInput"]==varied]
    assert len(group)==8
    for metric in metrics:
        changes=[r["Change_pct_"+metric] for r in group]
        summary.append(dict(ChangedInput=varied,Quantity=metric,Pairs=len(group),
                            MinChange_pct=min(changes),MedianChange_pct=median(changes),
                            MaxChange_pct=max(changes)))
write("chapter06_corner_summary.csv",summary)
print(f"Validated {CHECKS} numerical identities; recomputed 8 topology, 3 planform, 4 coupled representatives,")
print("4 LLT load integrals, 32 matched corner pairs, and all listed design comparisons.")
