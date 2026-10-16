# Model Artifact Format

This document describes generated model files under `results/model_learned/`.

## Source Layout

```text
results/model_learned/<source>/
  trained_models/
  state_space_models/
  cluster_info/
  repeated_models/
```

`<source>` is normalized by `artifactSourceName`:

| Config value | Result folder |
| --- | --- |
| `mss` | `mss` |
| `usv_simulator` | `usvsimu` |

## Trained Models

Folder:

```text
results/model_learned/<source>/trained_models/
```

Files:

| File pattern | Variable | Meaning |
| --- | --- | --- |
| `modeluNoCluster.mat` | `modelu` | Global LS-SVM model for surge speed. |
| `modelvNoCluster.mat` | `modelv` | Global LS-SVM model for sway speed. |
| `modelrNoCluster.mat` | `modelr` | Global LS-SVM model for yaw rate. |
| `modeluCluster<i>_FCM.mat` | `modelu` | FCM-cluster local LS-SVM model. |
| `modelvCluster<i>_FCM.mat` | `modelv` | FCM-cluster local LS-SVM model. |
| `modelrCluster<i>_FCM.mat` | `modelr` | FCM-cluster local LS-SVM model. |
| `modeluCluster<i>_KMEANS.mat` | `modelu` | K-means local LS-SVM model. |
| `modelvCluster<i>_KMEANS.mat` | `modelv` | K-means local LS-SVM model. |
| `modelrCluster<i>_KMEANS.mat` | `modelr` | K-means local LS-SVM model. |
| `modelGP.mat` | `gpModels` | Global GP model package. |

## State-Space Models

Folder:

```text
results/model_learned/<source>/state_space_models/
```

Files:

| File | Variable | Fields |
| --- | --- | --- |
| `StateModelNC.mat` | `StateModelNoCluster` | `A`, `B`, `b` |
| `StateModelGP.mat` | `StateModelGP` | `A`, `B`, `b`, model metadata |
| `StateModelClusterFCM.mat` | `StateModelCluster` | Cell array of local models |
| `StateModelClusterKMEANS.mat` | `StateModelCluster` | Cell array of local models |

Each local cluster model stores:

| Field | Meaning |
| --- | --- |
| `A` | State matrix for `[u; v; r]`. |
| `B` | Input matrix for `[tau_X; tau_N]`. |
| `b` | Affine bias vector. |
| `CENTER` | Cluster centers used for online membership. |
| `min_all`, `max_all` | Normalization range. |
| `cluster_min`, `cluster_max` | Cluster-specific range. |
| `cluster_cols` | Feature columns used by clustering. |
| `feature_weights` | WFCM feature weights, if available. |
| `method` | `fcm` or `kmeans`. |
| `F_cov` | Optional covariance-like metadata. |

## Cluster Metadata

Folder:

```text
results/model_learned/<source>/cluster_info/
```

Files:

| File | Variable | Meaning |
| --- | --- | --- |
| `clusters_FCM.mat` | `clusters` | FCM sample groups. |
| `cluster_index_FCM.mat` | `cluster_index` | FCM sample labels. |
| `clusterTail_FCM.mat` | `clusterTail` | FCM centers, ranges, weights, and fusion settings. |
| `clusters_KMEANS.mat` | `clusters` | K-means sample groups. |
| `cluster_index_KMEANS.mat` | `cluster_index` | K-means sample labels. |
| `clusterTail_KMEANS.mat` | `clusterTail` | K-means centers and metadata. |

## Repeated Models

Folder:

```text
results/model_learned/<source>/repeated_models/
```

| File | Variable | Meaning |
| --- | --- | --- |
| `repeatedClusterComparison.mat` | `results` | Repeated-run metric summary. |
| `repeatedClusterModels.mat` | `repeatedClusterModels` | Local models from repeated WFCM and K-means training. |
