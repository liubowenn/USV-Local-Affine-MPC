# Data-Driven Model Predictive Control of Differential-Thrust Unmanned Surface Vehicles via Local Affine Model Blending

MATLAB source code and simulation data for data-driven model predictive control
(MPC) of differential-thrust unmanned surface vehicles (USVs).

The method combines feature weighted fuzzy c-means (WFCM) with linear-kernel
least-squares support vector machines (LS-SVMs) to identify explicit local affine
models in overlapping maneuvering regions. The local models are smoothly blended
online to form an incremental predictor, retaining a quadratic programming (QP)
formulation for MPC.

## Results in the MSS environment

The following results show open-loop prediction, multisine heading tracking, and
S-shaped path following in the Marine Systems Simulator (MSS).

### Open-loop prediction performance

Open-loop prediction is evaluated under 25° and 35° zigzag maneuvers, a sinusoidal
heading maneuver, and circular motion. The proposed method is compared with
Global LS-SVM, Global GP, and K-means LS-SVM.

Prediction errors are measured by root-mean-square error (RMSE).
Proposed results are reported as the mean ±
standard deviation over 10 independently trained models. Bold values indicate
the lowest RMSE for each variable and maneuver. Yaw-rate RMSE is in rad/s.

| Maneuver | Variable | Global LS-SVM | Global GP | K-means LS-SVM | Proposed |
| --- | --- | ---: | ---: | ---: | ---: |
| zigzag25 | u (m/s) | 0.0513 | 0.0509 | **0.0328** | 0.0373 ± 0.0057 |
| zigzag25 | v (m/s) | 0.0573 | 0.0573 | 0.0471 | **0.0258 ± 0.0104** |
| zigzag25 | r (rad/s) | 0.0467 | 0.0467 | 0.0390 | **0.0237 ± 0.0042** |
| zigzag25 | ψ (°) | 8.7637 | 8.7546 | 7.4691 | **4.2160 ± 2.9112** |
| zigzag25 | xy (m) | 1.3098 | 1.3078 | 1.0702 | **0.7113 ± 0.2978** |
| zigzag35 | u (m/s) | 0.0458 | 0.0454 | 0.0322 | **0.0274 ± 0.0026** |
| zigzag35 | v (m/s) | 0.0485 | 0.0485 | 0.0442 | **0.0176 ± 0.0080** |
| zigzag35 | r (rad/s) | 0.0343 | 0.0343 | 0.0333 | **0.0219 ± 0.0020** |
| zigzag35 | ψ (°) | 8.2701 | 8.2617 | 6.6011 | **2.8715 ± 1.4545** |
| zigzag35 | xy (m) | 1.0863 | 1.0845 | 1.0397 | **0.3903 ± 0.1948** |
| circle | u (m/s) | 0.0356 | 0.0353 | **0.0342** | 0.0513 ± 0.0078 |
| circle | v (m/s) | 0.1010 | 0.1011 | 0.0602 | **0.0371 ± 0.0128** |
| circle | r (rad/s) | 0.0372 | 0.0372 | 0.0240 | **0.0104 ± 0.0065** |
| circle | ψ (°) | 61.6642 | 61.6540 | 37.0905 | **14.5111 ± 12.3210** |
| circle | xy (m) | 13.9502 | 13.9459 | 7.8912 | **2.9872 ± 2.6480** |
| sine | u (m/s) | 0.0508 | 0.0507 | **0.0248** | 0.0487 ± 0.0044 |
| sine | v (m/s) | 0.0763 | 0.0763 | 0.0614 | **0.0328 ± 0.0057** |
| sine | r (rad/s) | 0.0365 | 0.0365 | 0.0319 | **0.0143 ± 0.0032** |
| sine | ψ (°) | 15.7289 | 15.7190 | 9.7290 | **4.2957 ± 3.9561** |
| sine | xy (m) | 8.2640 | 8.2559 | 5.1394 | **2.4881 ± 1.9892** |

### Multisine heading tracking

Multisine heading tracking is evaluated under a time-varying payload disturbance.

MAE and IAE denote mean absolute error and integral of absolute error. Values are
mean ± standard deviation over 10 runs. QP solution time is averaged within each
run; the PID controller does not solve a QP.

| Controller | MAE<sub>ψ</sub> (°) | IAE<sub>ψ</sub> (°·s) | Mean QP time (ms) |
| --- | ---: | ---: | ---: |
| Nomoto-tuned PID | 10.2971 ± 0.0001 | 308.9120 ± 0.0041 | — |
| MPC-Global LS-SVM | 5.9756 ± 0.0005 | 179.2675 ± 0.0152 | 1.4388 ± 0.1493 |
| MPC-K-means LS-SVM | 6.2809 ± 0.0007 | 188.4258 ± 0.0202 | 1.4676 ± 0.1676 |
| MPC-Global GP | 5.9748 ± 0.0005 | 179.2444 ± 0.0152 | **1.4216 ± 0.1481** |
| Proposed | **5.7164 ± 0.0004** | **171.4922 ± 0.0119** | 1.4384 ± 0.1683 |

### S-shaped path following

A Frenet-frame line of sight (LOS) guidance law generates the reference heading.
Surge velocity is included in the MPC output. The controllers are evaluated under
simultaneous ocean-current and payload-mass disturbances.

Values are mean ± standard deviation over 10 runs.

| Controller | MAE<sub>ψ</sub> (°) | MAE<sub>u</sub> (m/s) | MAE<sub>eᵧ</sub> (m) | Mean QP time (ms) |
| --- | ---: | ---: | ---: | ---: |
| Nomoto-tuned PID | 37.4776 ± 0.0020 | 0.1251 ± 0.0000 | 3.4088 ± 0.0004 | — |
| MPC-Global LS-SVM | 31.8174 ± 0.0029 | 0.1611 ± 0.0000 | 3.3912 ± 0.0005 | 2.4348 ± 0.0639 |
| MPC-K-means LS-SVM | 35.2921 ± 0.0029 | 0.2214 ± 0.0000 | 4.5003 ± 0.0005 | 2.8991 ± 0.0458 |
| MPC-Global GP | 31.8160 ± 0.0029 | 0.1611 ± 0.0000 | 3.3911 ± 0.0005 | 2.4020 ± 0.0431 |
| Proposed | **21.4656 ± 0.0015** | **0.0343 ± 0.0000** | **1.9321 ± 0.0002** | **1.9461 ± 0.0393** |

#### Integral of absolute error (IAE)

| Controller | IAE<sub>ψ</sub> (°·s) | IAE<sub>u</sub> (m) | IAE<sub>eᵧ</sub> (m·s) |
| --- | ---: | ---: | ---: |
| Nomoto-tuned PID | 3642.8205 ± 0.1981 | 12.1644 ± 0.0016 | 331.3396 ± 0.0381 |
| MPC-Global LS-SVM | 2908.1110 ± 0.2653 | 14.7250 ± 0.0020 | 309.9566 ± 0.0488 |
| MPC-K-means LS-SVM | 3200.9952 ± 0.2613 | 20.0825 ± 0.0032 | 408.1807 ± 0.0441 |
| MPC-Global GP | 2907.9866 ± 0.2641 | 14.7219 ± 0.0020 | 309.9450 ± 0.0486 |
| Proposed | **1983.4223 ± 0.1414** | **3.1687 ± 0.0016** | **178.5290 ± 0.0164** |

Saved results: [heading tracking](results/mpc/mss/heading_multi_sine/repeatedMpcResults.mat)
and [S-shaped path following](results/mpc/mss/curve_sine_s/repeatedMpcResults.mat).

## Requirements

The MATLAB implementation is developed on Windows. Required toolboxes:

- Statistics and Machine Learning Toolbox
- Fuzzy Logic Toolbox
- Global Optimization Toolbox
- Optimization Toolbox

Download [LS-SVMlab](https://www.esat.kuleuven.be/sista/lssvmlab/toolbox.html) and
place its MATLAB files in `external/LSSVM/`, including `initlssvm.m` and
`trainlssvm.m`. This toolbox is installed separately after cloning the repository.

The MSS utility subset and OSQP MATLAB interface are included. The bundled OSQP
binary is for Windows x64. On other platforms, install a compatible OSQP MATLAB
interface or set `param.qp_solver = 'quadprog'` in
`src/mpc/config_simulation.m`.

## Reproduce the MSS results

Datasets, pretrained models, and saved simulation results are included. Open
MATLAB in the repository root and run:

```matlab
setupProject;
```

### Open-loop prediction

Validate the saved MSS models and report repeated-model RMSE statistics:

```matlab
setenv('MPC_DATA_SOURCE', 'mss');
validateModels(true, true);
```

### Saved heading-tracking and path-following results

Display the saved runs and print their statistics:

```matlab
plotRepeatedMpcResultFile('results/mpc/mss/heading_multi_sine/repeatedMpcResults.mat');
plotRepeatedMpcResultFile('results/mpc/mss/curve_sine_s/repeatedMpcResults.mat');
```

### New closed-loop simulations

Select the task and controller settings in `src/mpc/config_simulation.m`, then run:

```matlab
runMpcSimulation;
```

For 10 repeated runs of the selected task:

```matlab
runRepeatedMpcStats(10);
```

Results are saved under `results/mpc/mss/<scenario>/`.

### Train the MSS models

```matlab
cfg = defaultExperimentConfig();
cfg.data.source = 'mss';
cfg.steps.train_nonclustered_lssvm = true;
cfg.steps.train_weighted_fcm_lssvm = true;
cfg.steps.train_kmeans_lssvm = true;
cfg.steps.train_gp = true;
cfg.steps.validate_repeated_models = false;
runModelExperiment(cfg);
```

To regenerate the MSS training and test datasets as well, set
`cfg.steps.generate_training_data = true` and
`cfg.steps.generate_test_data = true` before running the experiment. Training
replaces the corresponding saved models.

## Repository layout

| Path | Contents |
| --- | --- |
| `setupProject.m` | MATLAB path setup. |
| `scripts/` | Experiment entry points and model-learning configuration. |
| `src/data_generation/` | MSS training, validation, and test data generation. |
| `src/clustering/` | WFCM and K-means clustering. |
| `src/model_training/` | Global and local LS-SVM models and GP models. |
| `src/state_space/` | Affine state-space models for MPC. |
| `src/model_validation/` | Open-loop prediction and RMSE evaluation. |
| `src/guidance/` | Heading references, path references, and Frenet-LOS guidance. |
| `src/mpc/` | Closed-loop simulation, controllers, QP solvers, and result plotting. |
| `src/common/` | Shared data, model, and metric utilities. |
| `data/` | Training, validation, and test datasets. |
| `results/model_learned/` | Pretrained models and repeated-model packages. |
| `results/mpc/` | Saved closed-loop simulation results. |
| `docs/assets/` | Complete paper figures in PNG format. |
| `external/` | Runtime dependencies. |

The data and result folders also contain the USV-simulator experiments described
in the paper. The MATLAB closed-loop simulation uses the MSS model.

## Data and result formats

- [Dataset format](docs/DATASET_FORMAT.md)
- [Model artifact format](docs/MODEL_ARTIFACT_FORMAT.md)
- [MPC result format](docs/MPC_RESULT_FORMAT.md)
- [Code structure](docs/CODE_STRUCTURE.md)
