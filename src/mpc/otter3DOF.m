function [x1,x2] = otter3DOF(x3dof,x3dof2,Ts,tau_cmd,current_cmd,mp)
    n = thrustAllocation(tau_cmd(1), tau_cmd(2));
    rp=[0,0,-0.35];
    V_c = current_cmd(2);
    beta_c = current_cmd(1);
    x = [x3dof(1) x3dof(2) x3dof2(1) x3dof2(2) x3dof2(3) x3dof(3) x3dof(4) x3dof(5) x3dof2(4) x3dof2(5) x3dof2(6) x3dof(6)]';
    if (length(x) ~= 12),error('x vector must have dimension 12!'); end
    if (length(n) ~= 2),error('n vector must have dimension 2!'); end
    g   = 9.81;
    rho = 1025;
    L = 2.0;
    B = 1.08;
    m = 55.0;
    rg = [0.2 0 -0.2]'; % Hull center of gravity.
    R44 = 0.4 * B;
    R55 = 0.25 * L;
    R66 = 0.25 * L;
    T_yaw = 1;
    Umax = 6 * 0.5144;
    B_pont  = 0.25;
    y_pont  = 0.395;
    Cw_pont = 0.75;
    Cb_pont = 0.4;
    nu = x(1:6);  nu2 = x(4:6);
    eta = x(7:12);
    u_c = V_c * cos(beta_c - eta(6));
    v_c = V_c * sin(beta_c - eta(6));
    nu_c = [u_c v_c 0 0 0 0 ]';                 % Current velocity.
    nu_r = nu - nu_c;
    nu_c_dot = [-Smtrx(nu2) * nu_c(1:3)
                 zeros(3,1)              ];
    nabla = (m+mp)/rho;
    T = nabla / (2 * Cb_pont * B_pont * L);
    Ig_CG = m * diag([R44^2, R55^2, R66^2]);
    rg = (m*rg + mp*rp)/(m+mp);
    Ig = Ig_CG - m * Smtrx(rg)^2 - mp * Smtrx(rp)^2;
    l1 = -y_pont;
    l2 = y_pont;
    k_pos = 0.02216/2;
    k_neg = 0.01289/2;
    n_max =  sqrt((0.5*24.4 * g)/k_pos);
    n_min = -sqrt((0.5*13.6 * g)/k_neg);
    I3 = eye(3);
    O3 = zeros(3,3);
    MRB_CG = [ (m+mp) * I3  O3
               O3           Ig ];
    CRB_CG = [ (m+mp) * Smtrx(nu2)         O3
               O3               -Smtrx(Ig*nu2)  ];
    H = Hmtrx(rg);
    MRB = H' * MRB_CG * H;
    CRB = H' * CRB_CG * H;
    Xudot = -addedMassSurge(m,L,rho);
    Yvdot = -1.5 * m;
    Zwdot = -1.0 * m;
    Kpdot = -0.2 * Ig(1,1);
    Mqdot = -0.8 * Ig(2,2);
    Nrdot = -1.7 * Ig(3,3);
    MA = -diag([Xudot, Yvdot, Zwdot, Kpdot, Mqdot, Nrdot]);
    CA  = m2c(MA, nu_r);
    CA(6,1) = 0;
    CA(6,2) = 0;
    CA(1,6) = 0;
    CA(2,6) = 0;
    M = MRB + MA;
    C = CRB + CA;
    Aw_pont = Cw_pont * L * B_pont;
    I_T = 2 * (1/12)*L*B_pont^3 * (6*Cw_pont^3/((1+Cw_pont)*(1+2*Cw_pont)))...
        + 2 * Aw_pont * y_pont^2;
    I_L = 0.8 * 2 * (1/12) * B_pont * L^3;
    KB = (1/3)*(5*T/2 - 0.5*nabla/(L*B_pont) );
    BM_T = I_T/nabla;
    BM_L = I_L/nabla;
    KM_T = KB + BM_T;
    KM_L = KB + BM_L;
    KG = T - rg(3);
    GM_T = KM_T - KG;
    GM_L = KM_L - KG;
    G33 = rho * g * (2 * Aw_pont);
    G44 = rho * g * nabla * GM_T;
    G55 = rho * g * nabla * GM_L;
    G_CF = diag([0 0 G33 G44 G55 0]);
    LCF = -0.2;
    H = Hmtrx([LCF 0 0]);
    G = H' * G_CF * H;
    w3 = sqrt( G33/M(3,3) );
    w4 = sqrt( G44/M(4,4) );
    w5 = sqrt( G55/M(5,5) );
    Xu = -24.4 * g / Umax;
    Yv = 0;
    Zw = -2 * 0.3 *w3 * M(3,3);
    Kp = -2 * 0.2 *w4 * M(4,4);
    Mq = -2 * 0.4 *w5 * M(5,5);
    Nr = -M(6,6) / T_yaw;
    Thrust = zeros(2,1);
    for i = 1:1:2
        if n(i) > n_max
           n(i) = n_max;
        elseif n(i) < n_min
           n(i) = n_min;
       end
       if n(i) > 0
         Thrust(i) = k_pos * n(i)*abs(n(i));
       else
         Thrust(i) = k_neg * n(i)*abs(n(i));
       end
    end
    tau = [Thrust(1) + Thrust(2) 0 0 0 0 -l1 * Thrust(1) - l2 * Thrust(2) ]';
    Xh = Xu * nu_r(1);
    Yh = Yv * nu_r(2);
    Zh = Zw * nu_r(3);
    Kh = Kp * nu_r(4);
    Mh = Mq * nu_r(5);
    Nh = Nr * (1 + 10 * abs(nu_r(6))) * nu_r(6);
    tau_damp = [Xh Yh Zh Kh Mh Nh]';
    tau_crossflow = crossFlowDrag(L,B_pont,T,nu_r);
    f_payload = Rzyx(eta(4),eta(5),eta(6))' * [ 0 0 mp*g ]';
    m_payload = Smtrx(rp) * f_payload;
    g_0 = [ f_payload
            m_payload ];
    J = eulerang(eta(4),eta(5),eta(6));
    xdot = [ nu_c_dot + M \ ( tau + tau_damp + tau_crossflow ...
                - C * nu_r - G * eta + g_0 )
             J * nu ];
    x = x + xdot*Ts;
x1=[x(1);x(2);x(6);x(7);x(8);x(12)];
x2=[x(3);x(4);x(5);x(9);x(10);x(11)];
end


