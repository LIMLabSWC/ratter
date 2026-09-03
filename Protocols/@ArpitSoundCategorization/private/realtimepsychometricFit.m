function [y_pred, fitParams, methodUsed, fitStatus] = realtimepsychometricFit(stim, resp, rangeStim, options)
% realtimepsychometricFit Robust real-time psychometric fitting and plotting.
%
% This function fits a 4-parameter logistic psychometric function. It includes
% internal checks for data quality and fitting stability.
%
% Inputs:
%   stim        - vector of stimulus values.
%   response    - binary response vector (0 or 1).
%   rangeStim   - 1x2 or 1x3 vector for the stimulus grid [min, max].
%   options     - (Optional) struct with fields:
%                 .MinTrials    - Min trials to attempt fit (default: 15).
%                 .LapseUB      - Upper bound for lapse rates (default: 0.1).
%                 .StdTol       - Tolerance for stimulus std dev (default: 1e-6).
%                 .SlopeTol     - Tolerance for slope parameter (default: 1e-5).
%
% Outputs:
%   y_pred      - Predicted y-values on a grid across rangeStim.
%   fitParams   - [mu, sigma, lapseL, lapseR] fitted parameters.
%   methodUsed  - String indicating the final fitting method used.
%   fitStatus   - String providing information on the fit quality/outcome.

%% 1. Argument Handling & Pre-computation Guard Clauses
if nargin < 4, options = struct(); end
if ~isfield(options, 'MinTrials'), options.MinTrials = 15; end
if ~isfield(options, 'LapseUB'), options.LapseUB = 0.1; end
if ~isfield(options, 'StdTol'), options.StdTol = 1e-6; end
if ~isfield(options, 'SlopeTol'), options.SlopeTol = 1e-5; end

fitParams = [nan,nan,nan,nan];
y_pred = [];
fitStatus = 'Success'; % Assume success initially

% Ensure both inputs are vectors and have the same number of elements
if ~isvector(stim) || ~isvector(resp)
    methodUsed = 'Fit Canceled';
    fitStatus = 'Inputs `stim` and `resp` must be vectors.';
    return;
end
if numel(stim) ~= numel(resp)
    methodUsed = 'Fit Canceled';
    fitStatus = 'Inputs `stim` and `resp` must have the same number of elements.';
    return;
end

% Enforce column vector orientation for consistency with fitting functions.
stim = stim(:);
resp = resp(:);

% GUARD (added): strip NaN/Inf entries before any statistics are computed.
% Without this, a single stray NaN propagates through std(), lassoglm(),
% and lsqcurvefit() silently — std(stim) becomes NaN, the variance guard
% below never catches it (NaN < anything is always false in MATLAB), and
% the fit either errors deep inside a toolbox call or returns garbage.
bad = isnan(stim) | isnan(resp) | isinf(stim) | isinf(resp);
stim = stim(~bad);
resp = resp(~bad);

% GUARD: Check for minimum number of trials (after NaN/Inf removal)
if numel(stim) < options.MinTrials
    methodUsed = 'Fit Canceled';
    fitStatus = sprintf('Insufficient trials (n=%d, min=%d)', numel(stim), options.MinTrials);
    return;
end

% GUARD: Check for stimulus variance
if std(stim) < options.StdTol
    methodUsed = 'Fit Canceled';
    fitStatus = 'Insufficient stimulus variance';
    return;
end

% GUARD (added): require stimuli on both sides of the boundary.
% Without this, a block where every trial happens to land on one side
% (a real risk in Discrete mode with only a few blocks) lets the fit
% extrapolate a threshold outside the sampled range with no warning.
approx_mu = mean(rangeStim);
if ~any(stim < approx_mu) || ~any(stim > approx_mu)
    methodUsed = 'Fit Canceled';
    fitStatus = 'Stimuli present on only one side of the boundary';
    return;
end

%% 2. Initial Fit (Ridge)
stim_std = (stim - mean(stim)) / std(stim);
methodUsed = 'ridge';

try
    % --- Ridge logistic fit for mu and sigma ---
    [B, FitInfo] = lassoglm(stim_std, resp, 'binomial', 'Alpha', 1e-6, 'Lambda', 0.1); % Alpha near 0 for ridge
    b0 = FitInfo.Intercept;
    b1 = B(1);

    % GUARD: Check for near-zero or excessively large slope from ridge fit
    if abs(b1) < options.SlopeTol
        throw(MException('MyFit:ZeroSlope', 'Initial ridge fit found no slope.'));
    end
    if abs(b1) > 10 % Check for quasi-perfect separation
         throw(MException('MyFit:SteepSlope', 'Initial ridge fit is too steep.'));
    end

    mu = -b0 / b1 * std(stim) + mean(stim);
    sigma = std(stim) / b1;

    % Residual lapse estimate for initialization
    predTrain = 1 ./ (1 + exp(-(b0 + b1 * stim_std)));
    lapseEstimate = mean(abs(predTrain - resp));
    lapseL = min(max(lapseEstimate * 1.2, 0), options.LapseUB);
    lapseR = lapseL;

catch ME
    % --- Fallback if ridge fit fails for any reason ---
    % FIX: robustfit(stim, resp, 'logit') is invalid — 'logit' is not a
    % recognized robustfit weight function ('bisquare','huber','logistic',
    % etc. are), and robustfit performs robust *linear* regression, which
    % is the wrong model for a binary response in the first place. Every
    % call to the old fallback threw, permanently forcing 'Fit Failed'
    % whenever ridge failed. glmfit is the correct logistic-regression tool.
    methodUsed = 'glmfit';
    fitStatus = sprintf('Switched to glmfit fallback. Reason: %s', ME.message);

    try
        brob = glmfit(stim, resp, 'binomial', 'link', 'logit');

        % GUARD: Check for near-zero slope from fallback fit
        if abs(brob(2)) < options.SlopeTol
            methodUsed = 'Fit Failed';
            fitStatus = 'Could not find a slope with either method.';
            return;
        end

        mu = -brob(1) / brob(2);
        sigma = 1 / brob(2);
        lapseL = 0.02; % Use fixed lapse guesses for fallback
        lapseR = 0.02;
    catch
        methodUsed = 'Fit Failed';
        fitStatus = 'glmfit fallback also failed to converge.';
        return;
    end
end

%% 3. Final Nonlinear Fit (lsqcurvefit)
psychometricFun = @(params, x) params(3) + (1 - params(3) - params(4)) ./ ...
    (1 + exp(-(x - params(1)) / params(2)));

% Use a slightly wider range for bounds to avoid railing issues
stim_min = min(rangeStim);
stim_max = max(rangeStim);
range_width = stim_max - stim_min;

init = [mu, sigma, lapseL, lapseR];
lb = [stim_min - 0.1*range_width, 0.1, 0, 0];
ub = [stim_max + 0.1*range_width, 15, options.LapseUB, options.LapseUB];

% Constrain initial guess to be within bounds
init(1) = max(min(init(1), ub(1)), lb(1));
init(2) = max(min(init(2), ub(2)), lb(2));
% GUARD (added): lapse initial guesses were never clamped — if lapseEstimate
% from the ridge branch exceeded LapseUB before the min/max clamp above ran,
% or LapseUB was configured very small, init(3)/init(4) could start outside
% [lb,ub]. lsqcurvefit tolerates this but it's cheap insurance.
init(3) = max(min(init(3), ub(3)), lb(3));
init(4) = max(min(init(4), ub(4)), lb(4));

optimOpts = optimset('Display', 'off');
fitParams = lsqcurvefit(psychometricFun, init, stim, resp, lb, ub, optimOpts);

%% 4. Post-Fit Sanity Checks & Prediction
% CHECK: Did the fit "rail" against the stimulus range bounds?
bound_tolerance = 0.01 * range_width;
if (fitParams(1) <= lb(1) + bound_tolerance) || (fitParams(1) >= ub(1) - bound_tolerance)
    fitStatus = 'Warning: Threshold is at the edge of the stimulus range.';
    % FIX: original warning('realtimepsychometricFit:%s', fitStatus) put a
    % '%' inside what looked like a message ID. MATLAB message IDs cannot
    % contain '%', so it was never actually registered as an ID — it was
    % silently reinterpreted as a plain format string instead. Split into
    % a proper ID and message so this is a real, filterable warning ID.
    warning('realtimepsychometricFit:threshAtEdge', '%s', fitStatus);
end

% CHECK: Did the lapse rates hit their upper bound?
if (fitParams(3) >= options.LapseUB*0.99) || (fitParams(4) >= options.LapseUB*0.99)
    fitStatus = 'Warning: Lapse rate may be underestimated (at upper bound).';
    warning('realtimepsychometricFit:lapseAtBound', '%s', fitStatus);
end

% Predict on a fine grid
xGrid = linspace(stim_min, stim_max, 300)';
y_pred = psychometricFun(fitParams, xGrid);

end