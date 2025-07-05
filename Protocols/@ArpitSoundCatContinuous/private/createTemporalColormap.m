function cmap = createTemporalColormap(n_colors)
    % createTemporalColormap Generates a colormap for sequential plotting.
    %   - Newest colors are bright and "hot" (e.g., yellow/red).
    %   - Oldest colors are darker and "cool" (e.g., deep blue/purple).
    %   - Hue, saturation, and brightness are all varied for maximum distinction.

    % Define the path in HSV color space
    hue_start = 0.6; % Start at blue
    hue_end = 0;     % End at red
    
    sat_start = 0.8; % Start slightly desaturated
    sat_end = 1.0;   % End fully saturated
    
    val_start = 0.7; % Start dark
    val_end = 1.0;   % End at full brightness

    % Create linearly spaced vectors for Hue, Saturation, and Value
    h = linspace(hue_start, hue_end, n_colors)';
    s = linspace(sat_start, sat_end, n_colors)';
    v = linspace(val_start, val_end, n_colors)';
    
    % Convert the HSV values to an RGB colormap
    cmap = hsv2rgb([h, s, v]);
end