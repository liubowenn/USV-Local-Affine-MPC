function p = packMpcParams(param, Phi, Gamma, H, lb, ub, Cblk, Qblk)
% packMpcParams  Bundle prediction matrices and shared MPC settings.
%
% solveDeltaU expects a compact struct containing the lifted prediction
% model, input constraints, optimizer options, and tracking reference data.

    p.Phi = Phi;
    p.Gamma = Gamma;
    p.H = H;
    p.lb = lb;
    p.ub = ub;
    p.Cblk = Cblk;
    p.Qblk = Qblk;
    p.opts = param.opts;
    p.Np = param.Np;
    p.Du_lim = param.Du_lim;
    p.u_min = param.u_min;
    p.u_max = param.u_max;
    p.u_ref = param.u_ref;
    p.qp_solver = getStructField(param, 'qp_solver', 'quadprog');
    p.osqp = getStructField(param, 'osqp', struct());
end
