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
| `runRepeatedClusterComparison.m` | Performs repeated GA-based weighted FCM and K-means comparisons. |
| `runRepeatedMpcStats.m` | Performs repeated closed-loop MPC simulations and prints statistics. |
| `exportPaperFigures.m` | Exports complete paper figures from edited local MATLAB figures. |

For a single closed-loop experiment, run `runMpcSimulation` from `src/mpc/`.

`exportPaperFigures(figureDirectory)` reads the local publication figures
`mss_open_loop_all_maneuvers.fig`, `heading_tracking_both_environments.fig`, and
`trajectory_tracking_both_environments.fig`. It exports the complete figures to
`docs/assets/` without changing the source figures or README tables.
