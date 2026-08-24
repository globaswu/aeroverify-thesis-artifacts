function run_tests()
%RUN_TESTS Validate public data and execute every solver-free workflow.

root = artifact_repository_root();
assert(strcmp(which("cTSEMO"), fullfile(root, "matlab", "cTSEMO.m")), ...
    "The public cTSEMO entry point is missing or shadowed.");
config = jsondecode(fileread(fullfile( ...
    root, "config", "reproduction_config.json")));

for topology = ["fcc", "bcc", "sc"]
    [evaluations, continuation, ~, expected] = ...
        load_topology_data(topology);
    assert(nnz(evaluations.feasible) == expected.expected_total_feasible);
    assert(nnz(evaluations.pareto_case071) == ...
        expected.expected_total_pareto);
    assert(nnz(continuation.feasible) == ...
        expected.expected_continuation_feasible);
    assert(nnz(continuation.pareto_case071) == ...
        expected.expected_continuation_pareto);
    assert(nnz(continuation.selection_source == "primary") == ...
        expected.expected_primary_selections);
    assert(nnz(continuation.selection_source == "challenger") == ...
        expected.expected_challenger_selections);
    assert(all(evaluations.feasible == (evaluations.constraint <= 0)));
    recomputed = observed_pareto_mask( ...
        [evaluations.mass_kg, evaluations.compliance_Nm], ...
        evaluations.feasible);
    assert(isequal(recomputed, evaluations.pareto_case071));
    assert(all(continuation.flutter_screen == ...
        string(expected.flutter_screen)));

    lowerBound = reshape(double(config.design_domain.lower_bound), 1, []);
    upperBound = reshape(double(config.design_domain.upper_bound), 1, []);
    X = [evaluations.a_m, evaluations.t1_over_a];
    assert(all(X >= lowerBound, "all") && all(X <= upperBound, "all"));
    XUnit = (X - lowerBound) ./ (upperBound - lowerBound);
    [model, fitDiagnostics] = ctsemo.fitClippedBinaryPof( ...
        XUnit, evaluations.feasible, cTSEMOOptions());
    anchorScore = ctsemo.predictClippedBinaryPof(model, XUnit);
    assert(max(abs(anchorScore - double(evaluations.feasible))) <= 1e-12);
    assert(fitDiagnostics.interpolationWithinTolerance);
end

planform = readtable(fullfile(root, "data", "planform", ...
    "evaluations_cases001_050.csv"), TextType="string");
planform.feasible = to_logical_column(planform.feasible);
planform.final_pareto = to_logical_column(planform.final_pareto);
assert(height(planform) == config.planform.expected_evaluations);
assert(nnz(planform.feasible) == config.planform.expected_feasible);
assert(nnz(planform.final_pareto) == config.planform.expected_pareto);

multiinput = readtable(fullfile(root, "data", "multiinput", ...
    "evaluations_cases001_100.csv"), TextType="string");
multiinput.Feasible = to_logical_column(multiinput.Feasible);
multiinput.Pareto = to_logical_column(multiinput.Pareto);
assert(height(multiinput) == config.multiinput.expected_evaluations);
assert(nnz(multiinput.Feasible) == config.multiinput.expected_feasible);
assert(nnz(multiinput.Pareto) == config.multiinput.expected_pareto);

mesh = readtable(fullfile(root, "data", "mesh_convergence", ...
    "results_summary.csv"), TextType="string");
assert(height(mesh) == config.mesh_convergence.expected_rows);

case067 = readtable(fullfile(root, "data", "diagnostics", ...
    "fcc_case067", "old_vs_18_point_all20.csv"), TextType="string");
assert(height(case067) == config.case067_flutter.expected_points);
assert(all(case067.rowCount == config.case067_flutter.expected_rows_per_point));
point3 = case067(case067.point == 3, :);
assert(abs(point3.oldMaxDamping - ...
    config.case067_flutter.point3_old_max_damping) < 1e-15);
assert(abs(point3.newMaxDamping - ...
    config.case067_flutter.point3_new_max_damping) < 1e-15);

exact = readtable(fullfile(root, "data", "representative_physics", ...
    "exact_trim_cdi_cases001_150.csv"), TextType="string");
representatives = readtable(fullfile(root, "data", ...
    "representative_physics", ...
    "representative_physics_cases004_037_064_065_099.csv"), ...
    TextType="string");
assert(height(exact) == ...
    config.representative_physics.expected_exact_trim_rows);
assert(isequal(sort(representatives.Case), ...
    sort(config.representative_physics.expected_representative_cases(:))));

temporaryOutput = makeTemporaryOutputDirectory();
cleanup = onCleanup(@() removeTemporaryOutput(temporaryOutput));
summary = reproduce_all(temporaryOutput);
assert(height(summary) == 8);
expectedOutputs = [ ...
    "fcc/fcc_observed_pareto.pdf"; ...
    "bcc/bcc_feasibility_score.pdf"; ...
    "sc/sc_continuation_table.tex"; ...
    "planform/planform_design_space.pdf"; ...
    "multiinput/multiinput_design_space.pdf"; ...
    "mesh_convergence/mesh_convergence_primary_metrics.pdf"; ...
    "case067_flutter/case067_mkaero1_comparison.pdf"; ...
    "representative_physics/exact_trim_cdi_comparison.pdf"; ...
    "reproduction_summary.csv"];
for relativePath = expectedOutputs(:)'
    path = fullfile(temporaryOutput, relativePath);
    assert(isfile(path), "Missing reproduced artifact: %s", path);
    info = dir(path);
    assert(info.bytes > 0, "Empty reproduced artifact: %s", path);
end

fprintf("All public-package checks passed.\n");
clear cleanup
end

function path = makeTemporaryOutputDirectory()
[temporaryParent, temporaryName] = fileparts(tempname);
path = fullfile(temporaryParent, ...
    "aeroverify_thesis_artifacts_test_" + string(temporaryName));
mkdir(path);
end

function removeTemporaryOutput(path)
path = string(path);
temporaryRoot = string(tempdir);
[parent, name] = fileparts(path);
safeParent = startsWith(lower(parent), ...
    lower(strip(temporaryRoot, "right", filesep)));
safeName = startsWith(name, "aeroverify_thesis_artifacts_test_");
if ~safeParent || ~safeName
    error("artifacts:TestCleanup:UnsafePath", ...
        "Refusing to remove unexpected test directory: %s", path);
end
if isfolder(path)
    rmdir(path, "s");
end
end
