# Scripts

This folder contains executable experiment entry points. Run scripts from the
repository root after adding the project to the MATLAB path:

```matlab
setupProject;
```

| File | Purpose |
| --- | --- |
| `defaultExperimentConfig.m` | Central pipeline configuration. |
| `runFullPipeline.m` | Runs the configured end-to-end model pipeline. |
| `runModelExperiment.m` | Executes data generation, clustering, training, state-space extraction, and validation stages. |
| `runMpcExperiment.m` | Runs the closed-loop MPC script when `cfg.steps.run_mpc` is enabled. |
| `runRepeatedClusterComparison.m` | Performs repeated GA-based weighted FCM and K-means comparisons. |
| `runRepeatedMpcStats.m` | Performs repeated closed-loop MPC simulations and prints statistics. |
| `exportReadmeResults.m` | Exports three MSS README previews from edited local MATLAB figures. |
