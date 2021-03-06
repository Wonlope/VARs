function Y = SimulateVAR(T, B, Sigma, Yinit, drop_init)
% Simulate a sample of length T from a Vector Autoregression (VAR) with
% parameters {B, Sigma}, conditional on the p initial observations stored
% in Yinit.
%
% The VAR has n variables and p lags, and can be written as
%
% y_t = C + B_1 y_t-1 + ... + B_p y_t-p + e_t
% e_t ~ N(0, Sigma)
%
% The coefficients are collected in the k-by-n matrix
% B = [C, B_1,..., B_p]' where k = n * p + 1. By writing
% x_t = [1, y'_t-1,..., y'_t-p]', we can express the VAR in row-vector
% form:
%
% y_t = x'_t B + e_t
%
% ---------
% ARGUMENTS
% ---------
%
% T:         Integer, length of sample to generate.
% B:         k-by-n matrix of coefficients for all lags. See paragraph
%            above for details.
% Sigma:     n-by-n matrix of error covariances.
% Yinit:     p-by-n matrix of initial observations to condition on.
% drop_init: (optional) logical,
%                - if drop_init == 'drop_init', the inital p observations
%                  will be excluded from the returned matrix, so that T new
%                  observations will be simulated.
%                - otherwise, the initial p observations will be included
%                  in the returned matrix, so that only T - p new
%                  observations will be simulated.
%
% ------
% OUTPUT
% ------
%
% Y: T-by-n matrix of simulated observations.

%% Validate arguments.

% Convert drop_init from string to logical.
drop_init = exist('drop_init', 'var') && strcmp(drop_init, 'drop_init');

% Check sizes.
[k, n] = size(B);
p = size(Yinit, 1);

if ~drop_init && (T < p)
    error('Sample length is shorter than number of initial conditions.')
end

if (k ~= n * p + 1) || any(size(Sigma) ~= [n, n]) || (size(Yinit, 2) ~= n)
    error('Argument dimensions are inconsistent.')
end

%% Simulate observations
% Construct output matrix.
Y = zeros(T, n);
if ~drop_init
    Y(1:p, :) = Yinit;
    t_init = p + 1;
else
    t_init = 1;
end

% Draw shocks.
if drop_init
    Epsilon = mvnrnd(zeros(1, n), Sigma, T);
else
    Epsilon = [NaN(p, n); mvnrnd(zeros(1, n), Sigma, T - p)];
end

% Construct initial x vector of RHS variables.
Yinitprime = Yinit';
x = [1; Yinitprime(:)];

% Iterate forward.
for t = t_init:T
    % Compute and store y_t.
    Y(t, :) = x' * B + Epsilon(t, :);
    % Create new x vector from old one.
    if p > 1
        x(2:(n * (p - 1) + 1)) = x((n + 1):(n * p + 1));
    end
    x((n * (p - 1) + 2):(n * p + 1)) = Y(t, :);
end

end
