# Results

`model_learned/` contains pretrained models and repeated-model packages.
`mpc/` contains the closed-loop experiments reported in the paper:

| Environment | Heading tracking | S-shaped path following |
| --- | --- | --- |
| MSS | `mss/heading_multi_sine/` | `mss/curve_sine_s/` |
| USV-simulator | `usv_simulator/heading_multisine_mass_current/` | `usv_simulator/curve_sine_s_1_mass/` |

The saved results support plotting and metric evaluation without retraining.
See the [README](../README.md) for commands and
[MPC result format](../docs/MPC_RESULT_FORMAT.md) for the saved fields.

The README previews are stored in `docs/assets/`. Local MATLAB figure files and
results from additional scenarios are not versioned.
