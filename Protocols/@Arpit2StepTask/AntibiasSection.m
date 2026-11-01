% [x, y, w, h] = AntibiasSection(obj, action, [arg1], [arg2])
%
% 4-class antibias for the 2-step task (Arpit2StepTraining).
%
% A 2-step trial belongs to one of four cells:
%     1 = reward Left,  category Quiet      2 = reward Left,  category Loud
%     3 = reward Right, category Quiet      4 = reward Right, category Loud
% The light side is derived from the cell and the cue rule, so it is not a
% separate dimension here.
%
% A side bias shows up as low hit rate on cells {1,2} or {3,4}, a category
% (go-to-lit / go-to-dark) bias as low hit rate on {1,3} or {2,4}, and the
% "ignore the light, use the 1-step mapping" strategy as low hit rate on a
% diagonal ({1,4} or {2,3}). Balancing all four cells corrects all three.
%
% The recent hit fraction of each cell is estimated with an exponential
% kernel (AB_Tau trials) and passed to probabilistic_trial_selector
% (ExperPort/SoloUtility), which already supports N classes:
%     p(cell) ~ prior(cell) * exp(-beta * hitfrac(cell))
% Two additions over the 1-step AntibiasSection:
%   * AB_BetaMode = 'Auto': beta grows with the gap between the best and
%     worst cell (same linear mapping as calculate_adaptive_antibias.m in
%     ArpitCentrePokeTraining: gap 0 -> AB_BetaMin, gap 1 -> AB_BetaMax).
%     'Manual': beta = AB_Beta.
%   * AB_Floor: every cell keeps at least this probability, so the trial
%     sequence never becomes predictable. p = floor + (1 - 4*floor) * p.
% With AB_On = 0 all cells have probability 0.25.
%
% ACTIONS
%   'init', x, y                 build GUI
%   'update', hit_hist, cell_hist  recompute cell probabilities.
%                                hit_hist: 1/0/NaN per trial (NaN = invalid)
%                                cell_hist: 1..4 per trial, NaN = not a 2-step trial
%   'get_probs'                  returns 1x4 vector of cell probabilities
%   'get_beta'                   returns the beta used in the last update
%   'set', name, value           set AB_On / AB_BetaMode / AB_Floor / AB_Beta
%   'reinit', 'close'

function [x, y, w, h] = AntibiasSection(obj, action, varargin)

GetSoloFunctionArgs(obj);

switch action

    case 'init'
        x = varargin{1}; y = varargin{2}; y0 = y;
        SoloParamHandle(obj, 'my_gui_info', 'value', [x y double(gcf)], 'saveable', 0);

        DispParam(obj, 'AB_P_RLoud',  0.25, x, y, 'label', 'P R-Loud');  next_row(y);
        DispParam(obj, 'AB_P_RQuiet', 0.25, x, y, 'label', 'P R-Quiet'); next_row(y);
        DispParam(obj, 'AB_P_LLoud',  0.25, x, y, 'label', 'P L-Loud');  next_row(y);
        DispParam(obj, 'AB_P_LQuiet', 0.25, x, y, 'label', 'P L-Quiet'); next_row(y);
        next_row(y, 0.5);
        DispParam(obj, 'AB_Hit_RLoud',  NaN, x, y, 'label', 'Hit R-Loud');  next_row(y);
        DispParam(obj, 'AB_Hit_RQuiet', NaN, x, y, 'label', 'Hit R-Quiet'); next_row(y);
        DispParam(obj, 'AB_Hit_LLoud',  NaN, x, y, 'label', 'Hit L-Loud');  next_row(y);
        DispParam(obj, 'AB_Hit_LQuiet', NaN, x, y, 'label', 'Hit L-Quiet'); next_row(y);
        next_row(y, 0.5);
        DispParam(obj, 'AB_BetaUsed', 0, x, y, 'label', 'beta used'); next_row(y);
        NumeditParam(obj, 'AB_Beta', 0, x, y, 'label', 'beta (manual)', ...
            'TooltipString', 'Used only when AB_BetaMode = Manual. 0 = no antibias.'); next_row(y);
        NumeditParam(obj, 'AB_BetaMin', 2, x, y, 'position', [x y 100 20], 'label', 'βmin', ...
            'TooltipString', 'Auto mode: beta when all cells perform equally');
        NumeditParam(obj, 'AB_BetaMax', 5, x, y, 'position', [x+100 y 100 20], 'label', 'βmax', ...
            'TooltipString', 'Auto mode: beta when the gap between best and worst cell is 1'); next_row(y);
        MenuParam(obj, 'AB_BetaMode', {'Auto', 'Manual'}, 'Auto', x, y, 'label', 'beta mode'); next_row(y);
        NumeditParam(obj, 'AB_Floor', 0.15, x, y, 'label', 'min P/cell', ...
            'TooltipString', 'Each cell keeps at least this probability (max 0.25)'); next_row(y);
        LogsliderParam(obj, 'AB_Tau', 30, 10, 400, x, y, 'label', 'antibias tau', ...
            'TooltipString', 'Number of trials back over which the per-cell hit fraction is computed'); next_row(y);
        ToggleParam(obj, 'AB_On', 0, x, y, 'OnString', 'Antibias 4-cell ON', 'OffString', 'Antibias 4-cell OFF', ...
            'TooltipString', 'If OFF, all four trial cells have probability 0.25'); next_row(y);

        SoloParamHandle(obj, 'AB_cell_probs', 'value', [0.25 0.25 0.25 0.25]);
        SoloParamHandle(obj, 'AB_beta_exact', 'value', 0);

        SubheaderParam(obj, 'title', 'Antibias (4 cells)', x, y);
        next_row(y, 1.5);
        w = gui_position('get_width');
        h = y - y0;

    case 'update'
        hits  = varargin{1}; hits  = hits(:);
        cells = varargin{2}; cells = cells(:);
        n = min(numel(hits), numel(cells));
        hits = hits(1:n); cells = cells(1:n);

        valid = ~isnan(hits) & ~isnan(cells);
        frac = NaN(1, 4);
        if any(valid)
            hv = hits(valid); cv = cells(valid);
            kernel = exp(-((numel(hv)-1):-1:0)' / value(AB_Tau));
            for c = 1:4
                u = (cv == c);
                if any(u)
                    frac(c) = sum(hv(u) .* kernel(u)) / sum(kernel(u));
                end
            end
        end
        % Display (before filling unseen cells)
        AB_Hit_LQuiet.value = round(frac(1)*100)/100;
        AB_Hit_LLoud.value  = round(frac(2)*100)/100;
        AB_Hit_RQuiet.value = round(frac(3)*100)/100;
        AB_Hit_RLoud.value  = round(frac(4)*100)/100;

        % Cells not seen yet are treated as average, so they are neither
        % favoured nor avoided.
        if all(isnan(frac))
            frac(:) = 1;
        else
            frac(isnan(frac)) = mean(frac(~isnan(frac)));
        end

        if value(AB_On) == 0
            beta = 0;
        elseif strcmpi(value(AB_BetaMode), 'Auto')
            gap  = max(frac) - min(frac);
            beta = value(AB_BetaMin) + gap * (value(AB_BetaMax) - value(AB_BetaMin));
        else
            beta = value(AB_Beta);
        end
        AB_BetaUsed.value = round(beta*100)/100;
        AB_beta_exact.value = beta;

        p = probabilistic_trial_selector(frac, [0.25 0.25 0.25 0.25], beta);
        p = p(:)';
        fl = min(max(value(AB_Floor), 0), 0.25);
        p = fl + (1 - 4*fl) * p;
        p = p / sum(p);

        AB_cell_probs.value = p;
        AB_P_LQuiet.value = round(p(1)*100)/100;
        AB_P_LLoud.value  = round(p(2)*100)/100;
        AB_P_RQuiet.value = round(p(3)*100)/100;
        AB_P_RLoud.value  = round(p(4)*100)/100;

    case 'get_probs'
        x = value(AB_cell_probs);

    case 'get_beta'
        x = value(AB_beta_exact);

    case 'set'
        switch varargin{1}
            case 'AB_On',       AB_On.value       = varargin{2};
            case 'AB_BetaMode', AB_BetaMode.value = varargin{2};
            case 'AB_Floor',    AB_Floor.value    = varargin{2};
            case 'AB_Beta',     AB_Beta.value     = varargin{2};
            otherwise
                warning('AntibiasSection:set', 'Unknown parameter %s', varargin{1});
        end

    case 'close'
        delete_sphandle('owner', ['^@' class(obj) '$'], 'fullname', ['^' mfilename]);

    case 'reinit'
        currfig = double(gcf);
        x = my_gui_info(1); y = my_gui_info(2); figure(my_gui_info(3));
        delete_sphandle('owner', ['^@' class(obj) '$'], 'fullname', ['^' mfilename]);
        [x, y] = feval(mfilename, obj, 'init', x, y);
        figure(currfig);

    otherwise
        warning('AntibiasSection:action', 'Unknown action %s', action);
end
