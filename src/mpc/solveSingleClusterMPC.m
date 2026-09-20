function [du, solve_time] = solveSingleClusterMPC(xi, psi_ref, u_prev, clusterModel, cluster_id, param)
% solveSingleClusterMPC  Solve MPC using one selected local cluster model.

    A = clusterModel.A{cluster_id};
    B = clusterModel.B{cluster_id};
    b = clusterModel.b{cluster_id};

    [Phi, Gamma, H, lb, ub, Cblk, Qblk] = ...
        computeIncrementalStateSpaceModel(A, B, param, b);
    p = packMpcParams(param, Phi, Gamma, H, lb, ub, Cblk, Qblk);
    [du, ~, solve_time] = solveDeltaU(xi, psi_ref, u_prev, p);
end
