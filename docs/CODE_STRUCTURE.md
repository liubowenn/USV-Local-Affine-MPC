# Code Structure

This project is organized around one data-driven MPC workflow:

```text
data -> clustering -> model training -> state-space extraction
     -> open-loop validation -> closed-loop MPC simulation
```

## Entry Points

| File | Role |
| --- | --- |
| `setupProject.m` | Adds project source, script, and external dependency paths. |
| `scripts/defaultExperimentConfig.m` | Model-learning and validation configuration. |
| `scripts/runFullPipeline.m` | Runs the configured model-learning pipeline. |
| `scripts/runModelExperiment.m` | Executes selected data, training, state-space, and validation stages. |
| `src/mpc/config_simulation.m` | Closed-loop MPC simulation parameters. |
| `src/mpc/runMpcSimulation.m` | Single MPC run: simulation, save, plot, and metric printout. |
| `scripts/runRepeatedMpcStats.m` | Repeated closed-loop MPC statistics. |

## Core Modules

| Folder | Responsibility |
| --- | --- |
| `src/data_generation/` | Generate training and validation data. |
| `src/clustering/` | FCM and K-means clustering. |
| `src/model_training/` | LS-SVM and GP model training. |
| `src/state_space/` | Extract affine state-space models from learned predictors. |
| `src/model_validation/` | Open-loop prediction, repeated-model statistics, and validation plots. |
| `src/guidance/` | Heading references, curve references, and Frenet-LOS guidance. |
| `src/mpc/` | Closed-loop MPC simulation, controllers, plotting, and result saving. |
| `src/common/` | Shared path helpers, metrics, prediction helpers, and small utilities. |

## MPC Design Notes

- `runMpcExperimentCore.m` is the only closed-loop simulation core.
- `runMpcSimulation.m` and `runRepeatedMpcStats.m` both call that core, so controller timing and model selection stay consistent.
- `loadMpcModels.m` loads the global, GP, FCM, and K-means state-space models for MPC.
- `solveFusedMPC.m` performs membership-weighted local model fusion for the proposed method.
- `solveSingleClusterMPC.m` uses one selected hard cluster for the K-means baseline.
- `mpcOverviewLayout.m` owns the overview-figure layout so plotting code and layout tuning are separated.
- `plotCurrentField.m` draws spatial-current heatmaps and fixed-size direction arrows.
- The MATLAB simulation uses MSS models. USV-Simulator result files can be
  imported for plotting; ROS control nodes are outside this repository.

## Validation Design Notes

- `validateModels.m` coordinates open-loop validation and metric reporting.
- `loadValidationSuite.m` owns validation-case loading and filtering.
- `discoverRepeatedClusterModels.m` locates repeated FCM/K-means models.
- `plotValidationOverview.m` owns open-loop validation figures.
- `buildValidationPlotPack.m` converts data and predictions into plotting packages.
- `plotTrainingData(source, Ts)` plots the saved training/validation split for
  either source, using `data.mat` and `data_val.mat` without machine-specific paths.
- GA defaults are read from `defaultExperimentConfig`; `weighted_fcm.beta`
  specifies the fixed fusion exponent used during training.

## Scope and Dependencies

Run the experiment commands from the repository root after `setupProject`.
The data/model helpers resolve paths relative to that working directory.
Datasets, pretrained models, and saved MPC results are versioned for
reproducibility. The README previews are stored in `docs/assets/`; local
MATLAB figure files remain outside Git.

## Result Locations

| Result | Location |
| --- | --- |
| Learned models | `results/model_learned/<source>/trained_models/` |
| State-space models | `results/model_learned/<source>/state_space_models/` |
| Cluster metadata | `results/model_learned/<source>/cluster_info/` |
| Repeated model packages | `results/model_learned/<source>/repeated_models/` |
| MPC latest result | `results/mpc/<source>/<scenario>/latestMpcResult.mat` |

## Format Documents

| Document | Role |
| --- | --- |
| `docs/DATASET_FORMAT.md` | Dataset matrix and validation-suite format. |
| `docs/MODEL_ARTIFACT_FORMAT.md` | Learned model and state-space artifact format. |
| `docs/MPC_RESULT_FORMAT.md` | Single and repeated MPC result format. |
