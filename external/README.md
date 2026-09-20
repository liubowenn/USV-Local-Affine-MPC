# Third-party dependencies

`setupProject` adds only the runtime folders listed below. Original upstream
source notices are preserved.

| Component | Runtime folder | Installation |
| --- | --- | --- |
| LS-SVMlab | `LSSVM/` | Install separately as described in the root README; ignored by Git. |
| Marine Systems Simulator utilities | `MSS/GNC/`, `MSS/HYDRO/` | Included. |
| OSQP MATLAB 0.6.2, Windows x64 | `osqp-matlab/osqp-0.6.2-matlab-windows64/` | Included. |

The OSQP package includes upstream tests and code-generation helpers. These are
not project experiments and are not added to the runtime path. The bundled
binary supports Windows x64; other platforms need their own compatible OSQP
installation or the MATLAB `quadprog` option. Only runtime QP solving is used
by this project.
