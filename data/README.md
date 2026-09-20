# Data Directory

Generated datasets are stored here.

- `mss/`: data generated from the MSS/Otter simulation workflow.
- `usv_simulator/`: data generated from the USV simulator ROS logs.

The `.mat` datasets for both sources are included in Git for immediate model
validation. CSV and figure exports are ignored. MSS datasets can be regenerated
with the model pipeline. New USV-Simulator datasets must be collected with the
external simulator; its ROS collection nodes are not included here.

From the repository root, inspect the same split used by training with:

```matlab
setupProject;
plotTrainingData('mss');
% plotTrainingData('usv_simulator');
```

Both sources use `data.mat` (variable `data`) and `data_val.mat` (variable
`data_val`). See `docs/DATASET_FORMAT.md` for columns and test-suite fields.
