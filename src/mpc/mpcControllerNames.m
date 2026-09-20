function names = mpcControllerNames()
% mpcControllerNames  Return the canonical controller plotting/evaluation order.
%
% The short names are used as struct fields throughout MPC results:
%   mss    - Nomoto-tuned PID baseline
%   nc     - MPC with one global LSSVM model
%   kmeans - MPC with K-means local LSSVM models
%   gp     - MPC with one global GP model
%   fcm    - Proposed weighted-FCM local LSSVM model fusion

    names = {'mss', 'nc', 'kmeans', 'gp', 'fcm'};
end
