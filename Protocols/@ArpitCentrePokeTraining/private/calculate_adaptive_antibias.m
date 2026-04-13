function [left_prob, right_prob, current_beta] = calculate_adaptive_antibias(hit_history, sides_history, left_prior, tau)
    % 1. Data Prep
    hit_history = hit_history(:);
    n_trials = length(hit_history);
    
    if n_trials < 5 % Not enough data to calculate bias yet
        left_prob = left_prior;
        right_prob = 1 - left_prior;
        current_beta = 2; % Start with a gentle beta
        return;
    end

    % 2. Calculate Weighted Accuracies (using the kernel logic from before)
    kernel = exp(-(0:n_trials-1)/tau)';
    kernel = kernel(end:-1:1);
    
    is_left = (sides_history == 'l');
    is_right = (sides_history == 'r');

    % Left Hit Fraction
    if ~any(is_left), lt_frac = 1; else
        lt_frac = sum(hit_history(is_left) .* kernel(is_left)) / sum(kernel(is_left));
    end

    % Right Hit Fraction
    if ~any(is_right), rt_frac = 1; else
        rt_frac = sum(hit_history(is_right) .* kernel(is_right)) / sum(kernel(is_right));
    end

    % 3. AUTOMATE BETA
    % Calculate the performance gap (0 to 1)
    perf_gap = abs(lt_frac - rt_frac);
    
    % Linear mapping: Gap of 0 -> Beta=2 | Gap of 1 -> Beta=5
    % Formula: Beta = min_beta + (gap * (max_beta - min_beta))
    current_beta = 2 + (perf_gap * 3);

    % 4. Calculate Probabilities
    fractions = [lt_frac, rt_frac];
    priors = [left_prior, 1 - left_prior];
    
    p = exp(-fractions * current_beta) .* priors;
    p = p ./ sum(p);

    left_prob = p(1);
    right_prob = p(2);
end