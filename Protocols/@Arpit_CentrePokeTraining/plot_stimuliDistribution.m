function plot_stimuliDistribution(ax, plot_x_range, distribution_left,mean_left,sigma_left,...
    range_left,distribution_right,mean_right,sigma_right,range_right)

x_left = plot_x_range(1):.01:plot_x_range(2);
x_right = plot_x_range(2):.01:plot_x_range(3);

switch distribution_left

    case 'Uniform'
        
        pdf_funct = makedist('Uniform','lower',range_left(1),'upper',range_left(2));
        pd_left = pdf(pdf_funct,x_left);

    case 'Half Normal'

        pdf_funct_init = @(x, A) A * exp(- (range_left(2) - x).^2 / (2 * sigma_left^2)); % Define the Half-Normal PDF (Peak at max value)
        A_den = integral(@(x) exp(- (range_left(2) - x).^2 / (2 * sigma_left^2)), range_left(1), range_left(2)); % Compute Normalization Constant A
        A_sol = 1 / A_den; % Ensuring total probability integrates to 1             
        pdf_funct = @(x) A_sol * exp(- (range_left(2) - x).^2 / (2 * sigma_left^2)); % Define the final normalized PDF function
        pd_left = pdf_funct(x_left);

    case 'Normal'
            
        pdf_funct = makedist('Normal','mu',mean_left,'sigma',sigma_left);
        pd_left = pdf(pdf_funct,x_left);

    case 'Sinusoidal'

         pdf_funct_init = @(x) sin((pi / 2) * ((x - range_left(1)) / (range_left(2) - range_left(1))));
         A_val = 1 / integral(pdf_funct_init, range_left(1), range_left(2)); % Compute Normalization Constant A
         pdf_funct = @(x) A_val * sin((pi / 2) * ((x - range_left(1)) / (range_left(2) - range_left(1)))); % the normalized PDF
         pd_left = pdf_funct(x_left);

    case 'Anti Half Normal'

        pdf_funct = makedist('HalfNormal','mu',mean_left,'sigma',sigma_left);
        pd_left = pdf(pdf_funct,x_left);

    case 'Anti Sinusoidal'

        pdf_funct_init = @(x) sin((pi / 2) * ((range_left(2) - x) / (range_left(2) - range_left(1)))); % Define the PDF (Peak at min value)
        A_val = 1 / integral(pdf_funct_init, range_left(1), range_left(2)); % Compute Normalization Constant A
        pdf_funct = @(x) A_val * sin((pi / 2) * ((range_left(2) - x) / (range_left(2) - range_left(1)))); % Define the normalized PDF
        pd_left = pdf_funct(x_left);

    case 'Monotonic Increase'

end

switch distribution_right

    case 'Uniform'
             
        pdf_funct = makedist('Uniform','lower',range_right(1),'upper',range_right(2));
        pd_right = pdf(pdf_funct,x_right);

    case 'Half Normal'

        pdf_funct = makedist('HalfNormal','mu',mean_right,'sigma',sigma_right);
        pd_right = pdf(pdf_funct,x_right);

    case 'Normal'

        pdf_funct = makedist('Normal','mu',mean_right,'sigma',sigma_right);
        pd_right = pdf(pdf_funct,x_right);

    case 'Sinusoidal'

        pdf_funct_init = @(x) sin((pi / 2) * ((range_right(2) - x) / (range_right(2) - range_right(1)))); % Define the PDF (Peak at min value)
        A_val = 1 / integral(pdf_funct_init, range_right(1), range_right(2)); % Compute Normalization Constant A
        pdf_funct = @(x) A_val * sin((pi / 2) * ((range_right(2) - x) / (range_right(2) - range_right(1)))); % Define the normalized PDF
        pd_right = pdf(pdf_funct,x_right);

    case 'Anti Half Normal'

        pdf_funct_init = @(x, A) A * exp(- (range_right(2) - x).^2 / (2 * sigma_right^2)); % Define the Half-Normal PDF (Peak at max value)
        A_den = integral(@(x) exp(- (range_right(2) - x).^2 / (2 * sigma_right^2)), range_right(1), range_right(2)); % Compute Normalization Constant A
        A_sol = 1 / A_den; % Ensuring total probability integrates to 1             
        pdf_funct = @(x) A_sol * exp(- (range_right(2) - x).^2 / (2 * sigma_right^2)); % Define the final normalized PDF function
        pd_right = pdf(pdf_funct,x_right);

    case 'Anti Sinusoidal'

        pdf_funct_init = @(x) sin((pi / 2) * ((x - range_right(1)) / (range_right(2) - range_right(1))));
        A_val = 1 / integral(pdf_funct_init, range_right(1), range_right(2)); % Compute Normalization Constant A
        pdf_funct = @(x) A_val * sin((pi / 2) * ((x - range_right(1)) / (range_right(2) - range_right(1)))); % the normalized PDF
        pd_right = pdf(pdf_funct,x_right);

    case 'Monotonic Increase'

end    

% Plot the distribution

plot_x = [x_left,x_right];
plot_y = [pd_left,pd_right];

plot(ax,plot_x,plot_y,'b','LineWidth', 2);

end