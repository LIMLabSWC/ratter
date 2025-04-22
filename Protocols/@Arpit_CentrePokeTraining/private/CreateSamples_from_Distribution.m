function samples = CreateSamples_from_Distribution(distributiontype,mu_val,sigma_val,range_min,range_max,n_samples)
%%  


% samples = CreateSamples_from_Distribution('Anti_Half_Normal',log(4),log(4),log(10),1000,)

% pairs = { ...
%       'Distribution_Type'        'Sinusoidal'; ...
%       'Range'        [log(0.007) log(0.05)] ; ...
%       'Mean_val' mean([log(0.007),log(0.05)]) ; ...
%       'N_Samples' 1; ...
%       'sigma_val' (log(0.05) - log(0.007))/3
%     }; parseargs(varargin, pairs);

%%


% Ensure the range is valid
if range_max <= range_min
    error('Upper bound range_max must be greater than lower bound range_min.');
end

if contains(distributiontype,'normal','IgnoreCase',true)
    if mu_val == range_min
        distributiontype = 'Anti_Half_Normal';
    else
        distributiontype = 'Half_Normal';
    end

elseif contains(distributiontype,'sinusoidal','IgnoreCase',true)
    if mu_val == range_min
        distributiontype = 'Anti_Sinusoidal';
    else
        distributiontype = 'Sinusoidal';
    end
end

switch distributiontype

    case 'Sinusoidal'
        
        pdf_func = @(x) sin((pi / 2) * ((x - range_min) / (range_max - range_min))); % Define the PDF (Peak at max value)
        A_val = 1 / integral(pdf_func, range_min, range_max); % Compute Normalization Constant A
        pdf_func = @(x) A_val * sin((pi / 2) * ((x - range_min) / (range_max - range_min))); % the normalized PDF
        cdf_func = @(x) integral(@(t) pdf_func(t), range_min, x); % Define the CDF as the cumulative integral of the normalized PDF
        inv_cdf_func = @(u) range_min + (range_max - range_min) * (2/pi) * acos(1 - u); % the Inverse CDF
        sample_single_point = @() inv_cdf_func(rand()); % Function for Sampling a Single Point
        samples = arrayfun(@(x) sample_single_point(), 1:n_samples);% Sample Random Point


    case 'Anti_Sinusoidal'
  
        pdf_func = @(x) sin((pi / 2) * ((range_max - x) / (range_max - range_min))); % Define the PDF (Peak at min value)
        A_val = 1 / integral(pdf_func, range_min, range_max); % Compute Normalization Constant A
        pdf_func = @(x) A_val * sin((pi / 2) * ((range_max - x) / (range_max - range_min))); % Define the normalized PDF
        cdf_func = @(x) integral(@(t) pdf_func(t), range_min, x); % Define the CDF as the cumulative integral of the normalized PDF
        inv_cdf_func = @(u) range_max - (range_max - range_min) * (2/pi) * acos(1 - u); % the Inverse CDF
        sample_single_point = @() inv_cdf_func(rand()); % Function for Sampling a Single Point
        samples = arrayfun(@(x) sample_single_point(), 1:n_samples); % Sample Random Points


    case 'Anti_Half_Normal'

        pdf_func = @(x, A) A * exp(- (x - mu_val).^2 / (2 * sigma_val^2)); % Define the Half-Normal PDF (Peak at min value)
        A_den = integral(@(x) exp(- (x - mu_val).^2 / (2 * sigma_val^2)), range_min, range_max); % Compute Normalization Constant A
        A_sol = 1 / A_den; % Ensuring total probability integrates to 1
        
        pdf_func = @(x) A_sol * exp(- (x - mu_val).^2 / (2 * sigma_val^2)); % Define the normalized PDF function
        
        cdf_func = @(x) (erf((x - mu_val) / (sqrt(2) * sigma_val)) - erf((range_min - mu_val) / (sqrt(2) * sigma_val))) ... % CDF formula for truncated normal distribution
            / (erf((range_max - mu_val) / (sqrt(2) * sigma_val)) - erf((range_min - mu_val) / (sqrt(2) * sigma_val))); 
     
        inv_cdf_func = @(u) mu_val + sqrt(2) * sigma_val * erfinv( ...  % Inverse CDF function (solving for x in terms of U)
            u * (erf((range_max - mu_val) / (sqrt(2) * sigma_val)) - erf((range_min - mu_val) / (sqrt(2) * sigma_val))) ...
            + erf((range_min - mu_val) / (sqrt(2) * sigma_val)));
        
        sample_single_point = @() inv_cdf_func(rand()); % Function for Sampling a Single Point
        samples = arrayfun(@(x) sample_single_point(), 1:n_samples); % Sample Random Points


    case 'Half_Normal'

        pdf_func = @(x, A) A * exp(- (range_max - x).^2 / (2 * sigma_val^2)); % Define the Half-Normal PDF (Peak at max value)
        A_den = integral(@(x) exp(- (range_max - x).^2 / (2 * sigma_val^2)), range_min, range_max); % Compute Normalization Constant A
        A_sol = 1 / A_den; % Ensuring total probability integrates to 1     
        
        pdf_func = @(x) A_sol * exp(- (range_max - x).^2 / (2 * sigma_val^2)); % Define the final normalized PDF function

        cdf_func = @(x) (erf((x - range_max) / (sqrt(2) * sigma_val)) - erf((range_min - range_max) / (sqrt(2) * sigma_val))) ... % CDF formula for truncated normal distribution
                / (erf((range_max - range_max) / (sqrt(2) * sigma_val)) - erf((range_min - range_max) / (sqrt(2) * sigma_val)));

        inv_cdf_func = @(u) range_max - sqrt(2) * sigma_val * erfinv( ...   % Inverse CDF function (solving for x in terms of U)
            u * (erf((range_max - range_min) / (sqrt(2) * sigma_val))));

        sample_single_point = @() inv_cdf_func(rand()); % Function for Sampling a Single Point
        samples = arrayfun(@(x) sample_single_point(), 1:n_samples); % Sample Random Points

end

% check all the samples are within the range (excluding the range)
out_of_range_samples = find(samples <= range_min & samples >= range_max);
if length(out_of_range_samples) >= 1
    samples_replacement = arrayfun(@(x) sample_single_point(), 1:length(out_of_range_samples)); %
    samples(out_of_range_samples) = samples_replacement;
end
% Recheck and if its again out of range then replace it in while loop ( was
% trying to avoid it)
out_of_range_samples_new = find(samples <= range_min & samples >= range_max);
if length(out_of_range_samples) >= 1
    for i = length(out_of_range_samples_new)
        sample_new = arrayfun(@(x) sample_single_point(), 1);
        while sample_new <= range_min || sample_new >= range_max
            sample_new = arrayfun(@(x) sample_single_point(), 1);
        end
        samples(out_of_range_samples_new(i)) = sample_new;
    end
end

% %% Debugging - Validate CDF and Inverse CDF
        
        % % Create a fine grid of x values
        % x_vals = linspace(range_min, range_max, 1000);
        % % Evaluate PDF and CDF
        % pdf_vals = pdf_func(x_vals);
        % cdf_vals = cdf_func(x_vals);
        % % Generate uniform random samples and apply inverse CDF
        % U = rand(10000,1);
        % sampled_x = inv_cdf_func(U);
        % %% Plot PDF and CDF
        % figure;
        % % PDF Plot
        % subplot(2,1,1);
        % plot(x_vals, pdf_vals, 'b', 'LineWidth', 2);
        % xlabel('x'); ylabel('PDF');
        % title('Half-Normal PDF');
        % grid on;
        % % CDF Plot
        % subplot(2,1,2);
        % plot(x_vals, cdf_vals, 'r', 'LineWidth', 2);
        % xlabel('x'); ylabel('CDF');
        % title('Cumulative Distribution Function (CDF)');
        % grid on;