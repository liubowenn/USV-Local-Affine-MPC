# Dataset Format

This document describes the `.mat` files used by data generation, model
training, and open-loop validation.

## Locations

```text
data/mss/
data/usv_simulator/
```

The active source is selected by:

```matlab
cfg.data.source = 'mss';           % or 'usv_simulator'
```

## Main Files

| File | Variable | Purpose |
| --- | --- | --- |
| `data.mat` | `data` | Training data used for LS-SVM/GP learning and clustering. |
| `data_val.mat` | `data_val` | Validation data used by GA feature-weight tuning. |
| `testSuite.mat` | `testSuite` | Open-loop validation cases. |
| `data_25.mat` | `data_25` | Single 25° zigzag test dataset. |

## Data Matrix Columns

Rows are time samples. The code expects the following core columns:

| Column | Symbol | Meaning |
| --- | --- | --- |
| 1 | `u` | Surge speed. |
| 2 | `v` | Sway speed. |
| 3 | `r` | Yaw rate. |
| 4-5 | position | Earth-frame position coordinates. MSS generation stores X, Y. |
| 6 | `psi` | Heading in radians; required by open-loop validation. |
| 7 | `tau_X` | Surge force input. |
| 8 | `tau_N` | Yaw moment input. |

The learning functions mainly use:

```matlab
[u, v, r, tau_X, tau_N]
```

and predict the next-step velocity increments `[delta_u, delta_v, delta_r]`.
The state-space model adds these increments to the current velocity state.

## Validation Suite

`testSuite` is an array of structs. Each element should contain:

| Field | Meaning |
| --- | --- |
| `name` | Case name, such as `zigzag25`, `zigzag35`, `circle`, `sine`. |
| `data` | Data matrix with the same column convention as above. |
