"""Check published observations, feasibility labels, fronts and hypervolume.

This reads the published CSV files only. It neither executes an optimizer nor
reconstructs unavailable simulation outputs.
"""
from collections import defaultdict
import csv
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1] / 'data/benchmarks/seven_solver_comparison'


def rows(name):
    with (ROOT / name).open(encoding='utf-8-sig', newline='') as handle:
        return list(csv.DictReader(handle))


def front(y, feasible):
    mask = np.zeros(len(y), dtype=bool)
    seen = set()
    for i in np.flatnonzero(feasible):
        value = tuple(y[i])
        if value not in seen and not np.any(feasible & np.all(y <= y[i], axis=1) & np.any(y < y[i], axis=1)):
            mask[i] = True
            seen.add(value)
    return mask


def hypervolume(y):
    y = y[np.all(y < 1.1, axis=1)]
    previous_y = 1.1
    area = 0.0
    for x, value in y[np.argsort(y[:, 0])]:
        if value < previous_y:
            area += (1.1 - x) * (previous_y - value)
            previous_y = value
    return area


def main():
    evaluated = rows('evaluations.csv')
    ga = rows('empirical_ga_fronts.csv')
    exported_front = rows('observed_pareto.csv')
    metrics = {(r['problem'], r['solver']): r for r in rows('solver_metrics.csv')}
    table = {r['problem']: r for r in rows('hv_ratio_table.csv')}
    groups = defaultdict(list)
    for record in evaluated:
        groups[record['problem'], record['solver']].append(record)
    assert len(evaluated) == 7350 and len(groups) == 49 and len(metrics) == 49
    assert len(ga) == 2884 and len(exported_front) == 757 and len(table) == 7
    ga_hv = {}
    for problem in table:
        z = np.array([[float(r['normalized_Y1']), float(r['normalized_Y2'])] for r in ga if r['problem'] == problem])
        ga_hv[problem] = hypervolume(z)
    initial = {}
    maximum_hv_error = 0.0
    exported_keys = {(r['problem'], r['solver'], r['evaluation_index']) for r in exported_front}
    recovered_keys = set()
    for (problem, solver), group in groups.items():
        group.sort(key=lambda r: int(r['evaluation_index']))
        assert [int(r['evaluation_index']) for r in group] == list(range(1, 151))
        assert [r['phase'] for r in group] == ['initial'] * 20 + ['adaptive'] * 130
        shared = np.array([[float(r[f'X{i}']) if r[f'X{i}'] else np.nan for i in range(1, 11)] + [float(r['Y1']), float(r['Y2']), float(r['C'])] for r in group[:20]])
        if problem in initial:
            np.testing.assert_allclose(initial[problem], shared, rtol=1e-12, atol=5e-10, equal_nan=True,
                                       err_msg=f'{problem}/{solver}: initial observations differ')
        initial[problem] = shared
        y = np.array([[float(r['Y1']), float(r['Y2'])] for r in group])
        z = np.array([[float(r['normalized_Y1']), float(r['normalized_Y2'])] for r in group])
        assert np.isfinite(y).all() and np.isfinite(z).all()
        feasible = np.array([int(r['C']) == 1 for r in group])
        for r in group:
            margins = [float(r[f'audit_margin{i}']) for i in range(1, 5) if r[f'audit_margin{i}']]
            assert int(r['C']) == int(max(margins) <= 0), (problem, solver, r['evaluation_index'], 'constraint label')
        mask = front(y, feasible)
        assert np.array_equal(mask, np.array([int(r['is_pareto']) == 1 for r in group])), (problem, solver, 'front mismatch')
        for r, selected in zip(group, mask):
            if selected:
                recovered_keys.add((problem, solver, r['evaluation_index']))
        m = metrics[problem, solver]
        assert int(m['FeasibleCount']) == int(feasible.sum())
        assert int(m['ParetoCount']) == int(mask.sum())
        hv = hypervolume(z[mask])
        ratio = hv / ga_hv[problem]
        error = max(abs(hv - float(m['NormalizedHV'])), abs(ratio - float(m['HVToGARatio'])))
        maximum_hv_error = max(maximum_hv_error, error)
        assert error < 1e-12, (problem, solver, 'hypervolume mismatch', error)
        assert abs(ratio - float(table[problem][m['solver_name']])) < 1e-12
    assert recovered_keys == exported_keys
    print(f'Verified 49 trajectories, 7350 observations, 757 Pareto points, shared initial designs, labels and HV ratios; maximum HV/ratio error {maximum_hv_error:.3g}.')


if __name__ == '__main__':
    main()
