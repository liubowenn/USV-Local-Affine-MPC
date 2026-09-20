function [du, solve_time] = solveFusedMPC(xi, psi_ref, u_prev, clusterModel, membership, param)
% solveFusedMPC  Solve MPC with a membership-weighted local state-space model.
%
% Local models are fused as:
%   A_f = sum_i membership_i A_i
%   B_f = sum_i membership_i B_i
%   b_f = sum_i membership_i b_i

    K = clusterModel.K;
    A_f = zeros(3);
    B_f = zeros(3, 2);
    b_f = zeros(3, 1);

    for k = 1:K
        A_f = A_f + membership(k) * clusterModel.A{k};
        B_f = B_f + membership(k) * clusterModel.B{k};
        b_f = b_f + membership(k) * clusterModel.b{k};
    end

    [Phi, Gamma, H, lb, ub, Cblk, Qblk] = ...
        computeIncrementalStateSpaceModel(A_f, B_f, param, b_f);
    p = packMpcParams(param, Phi, Gamma, H, lb, ub, Cblk, Qblk);
    [du, ~, solve_time] = solveDeltaU(xi, psi_ref, u_prev, p);
end
