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
% Training (2026): the antibias is fully automatic. The training stage
% switches it on/off and picks what it acts on ('configure', called by
% TrainingStageSection at the start of each session and on a stage change):
%   stages 1-4  'side'  : either side pays, so it acts on the side. When the
%                         rat over-uses one side, a trial is more often
%                         rewarded only on the other side ('side_force').
%   stages 5-6  'cells' : the 4-cell antibias above, Standard (only with sound).
%   stage 7     'cells' : a cycle STRONG -> FREE (Gentle) -> STRONG when the
%                         rat starts to use a strategy -> ... (see
%                         TrainingStageSection, 'ab7_cycle').
%   stage 8     off (the test is run like the experiment).
% The only control is AB_Strength (how hard it pushes):
%   Auto by stage | Gentle | Standard | Strong | Off
% which sets the floor, beta range and memory (AB_Floor, AB_BetaMin/Max,
% AB_Tau). 'Auto by stage' = the preset the stage asks for (Standard in
% stages 1-6, Strong / Gentle in stage 7), with the stage's own floor if set.
% Any other choice overrides the stage's preset (but not its on/off).
% Beta is always adaptive (grows with how unequal the cells/sides are).
%
% ACTIONS
%   'init', x, y                 build GUI
%   'update', hit_hist, cell_hist  recompute cell probabilities.
%                                hit_hist: 1/0/NaN per trial (NaN = invalid)
%                                cell_hist: 1..4 per trial, NaN = not a 2-step trial
%   'get_probs'                  returns 1x4 vector of cell probabilities
%   'get_beta'                   returns the beta used in the last update
%   'set', name, value           set AB_On / AB_BetaMode / AB_Floor / AB_Beta
%   'configure', on, kind, floor, preset   on 0/1, kind 'cells' | 'side', stage floor
%                                (NaN = preset's), preset 'Gentle' | 'Standard' | 'Strong'
%   'side_force', hit_hist, choice_hist   'l' / 'r' = only that side pays this trial, '' = either
%   'reinit', 'close'

function [x, y, w, h] = AntibiasSection(obj, action, varargin)

GetSoloFunctionArgs(obj);

switch action

    case 'init'
        x = varargin{1}; y = varargin{2}; y0 = y;
        SoloParamHandle(obj, 'my_gui_info', 'value', [x y double(gcf)], 'saveable', 0);

        MenuParam(obj, 'AB_Strength', {'Auto by stage', 'Gentle', 'Standard', 'Strong', 'Off'}, 'Auto by stage', ...
            x, y, 'label', 'Strength', 'labelfraction', 0.35, 'TooltipString', sprintf([ ...
            'How hard the antibias pushes. On/off and what it acts on are set by the stage.\n' ...
            'Auto by stage: what the stage asks for (Standard; stage 7: Strong / Gentle cycle)\n' ...
            'Gentle:   min P/cell 0.20, beta 1-3, memory 50 trials\n' ...
            'Standard: min P/cell 0.15, beta 2-5, memory 30 trials\n' ...
            'Strong:   min P/cell 0.10, beta 3-8, memory 20 trials\n' ...
            'Off:      no antibias in any stage']));
        set_callback(AB_Strength, {mfilename, 'strength_changed'}); next_row(y);
        DispParam(obj, 'AB_Status', 'off', x, y, 'label', 'Now', 'labelfraction', 0.2, 'TooltipString', ...
            'What the antibias is doing now (set by the training stage)'); next_row(y);
        next_row(y, 0.3);
        DispParam(obj, 'AB_Hit_RLoud',  NaN, x, y, 'label', 'Recent R-Loud', 'TooltipString', 'Recent hit rate in this cell (the last ~AB_Tau valid trials count most). This is what the antibias balances.');  next_row(y);
        DispParam(obj, 'AB_Hit_RQuiet', NaN, x, y, 'label', 'Recent R-Quiet', 'TooltipString', 'Recent hit rate in this cell'); next_row(y);
        DispParam(obj, 'AB_Hit_LLoud',  NaN, x, y, 'label', 'Recent L-Loud', 'TooltipString', 'Recent hit rate in this cell');  next_row(y);
        DispParam(obj, 'AB_Hit_LQuiet', NaN, x, y, 'label', 'Recent L-Quiet', 'TooltipString', 'Recent hit rate in this cell'); next_row(y);
        next_row(y, 0.3);
        DispParam(obj, 'AB_P_RLoud',  0.25, x, y, 'label', 'P next R-Loud', 'TooltipString', 'Probability that the next 2-step trial is of this kind');  next_row(y);
        DispParam(obj, 'AB_P_RQuiet', 0.25, x, y, 'label', 'P next R-Quiet'); next_row(y);
        DispParam(obj, 'AB_P_LLoud',  0.25, x, y, 'label', 'P next L-Loud');  next_row(y);
        DispParam(obj, 'AB_P_LQuiet', 0.25, x, y, 'label', 'P next L-Quiet'); next_row(y);

        % Set by 'configure' / AB_Strength (no manual controls)
        SoloParamHandle(obj, 'AB_On',       'value', 0);
        SoloParamHandle(obj, 'AB_Kind',     'value', 'cells');   % 'cells' or 'side'
        SoloParamHandle(obj, 'AB_StageFloor', 'value', NaN);
        SoloParamHandle(obj, 'AB_StagePreset', 'value', 'Standard');   % preset asked for by the stage
        SoloParamHandle(obj, 'AB_BetaMode', 'value', 'Auto');
        SoloParamHandle(obj, 'AB_Beta',     'value', 0);
        SoloParamHandle(obj, 'AB_BetaMin',  'value', 2);
        SoloParamHandle(obj, 'AB_BetaMax',  'value', 5);
        SoloParamHandle(obj, 'AB_Floor',    'value', 0.15);
        SoloParamHandle(obj, 'AB_Tau',      'value', 30);
        SoloParamHandle(obj, 'AB_BetaUsed', 'value', 0);
        SoloParamHandle(obj, 'AB_cell_probs', 'value', [0.25 0.25 0.25 0.25]);
        SoloParamHandle(obj, 'AB_beta_exact', 'value', 0);
        SoloParamHandle(obj, 'AB_side_force_p', 'value', 0);

        SubheaderParam(obj, 'title', 'Antibias (automatic)', x, y, 'TooltipString', ...
            'On/off and what it acts on are set by the training stage; only the strength can be chosen.');
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

        if value(AB_On) == 0 || strcmp(value(AB_Strength), 'Off')
            beta = 0;
        elseif strcmpi(value(AB_BetaMode), 'Auto')
            gap  = max(frac) - min(frac);
            beta = value(AB_BetaMin) + gap * (value(AB_BetaMax) - value(AB_BetaMin));
        else
            beta = value(AB_Beta);
        end
        AB_BetaUsed.value = round(beta*100)/100;
        AB_beta_exact.value = beta;
        if value(AB_On) == 1 && strcmp(value(AB_Kind), 'cells')
            AB_Status.value = sprintf('4-cell, beta %.1f', beta);
        end

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

    case 'configure'
        % on (0/1), kind ('cells' | 'side'), stage floor (NaN = use the preset),
        % preset ('Gentle' | 'Standard' | 'Strong', used with 'Auto by stage')
        AB_On.value = varargin{1};
        AB_Kind.value = varargin{2};
        if numel(varargin) >= 3, AB_StageFloor.value = varargin{3}; end
        if numel(varargin) >= 4, AB_StagePreset.value = varargin{4}; end
        feval(mfilename, obj, 'strength_changed');

    case 'strength_changed'
        % Presets: [floor, beta min, beta max, memory (trials)]
        sname = value(AB_Strength);
        if strcmp(sname, 'Auto by stage'), sname = value(AB_StagePreset); end
        switch sname
            case 'Gentle',   pr = [0.20 1 3 50];
            case 'Strong',   pr = [0.10 3 8 20];
            otherwise,       pr = [0.15 2 5 30];   % Standard / Auto by stage
        end
        if strcmp(value(AB_Strength), 'Auto by stage') && ~isnan(value(AB_StageFloor))
            pr(1) = value(AB_StageFloor);
        end
        AB_Floor.value = pr(1); AB_BetaMin.value = pr(2); AB_BetaMax.value = pr(3); AB_Tau.value = pr(4);
        AB_BetaMode.value = 'Auto';
        if strcmp(value(AB_Strength), 'Off') || value(AB_On) == 0
            AB_Status.value = 'off';
            AB_cell_probs.value = [0.25 0.25 0.25 0.25];
            AB_P_LQuiet.value = 0.25; AB_P_LLoud.value = 0.25; AB_P_RQuiet.value = 0.25; AB_P_RLoud.value = 0.25;
        elseif strcmp(value(AB_Kind), 'side')
            AB_Status.value = 'side (either side pays)';
        else
            AB_Status.value = ['4-cell, ' lower(sname)];
        end

    case 'is_on'
        x = value(AB_On) == 1 && ~strcmp(value(AB_Strength), 'Off');

    case 'side_force'
        % Stages 1-4 (either side pays). Recent fraction of rewarded pokes on
        % the left, with the same memory as the 4-cell antibias. The more
        % unequal, the more often only the under-used side pays:
        %   gap  = |2*fracL - 1|              (0 = balanced, 1 = one side only)
        %   beta = beta_min + gap * (beta_max - beta_min)
        %   P(force) = min(1 - 2*floor, 2 * gap * beta / 10)
        % e.g. Standard, 70% left: gap 0.4, beta 3.2, P(force right) = 0.26.
        x = '';
        AB_side_force_p.value = 0;
        if ~(value(AB_On) == 1 && strcmp(value(AB_Kind), 'side') && ~strcmp(value(AB_Strength), 'Off'))
            return;
        end
        hh = varargin{1}; hh = hh(:); ch = varargin{2}; ch = ch(:);
        m = min(numel(hh), numel(ch)); hh = hh(1:m); ch = ch(1:m);
        u = find(hh == 1 & (ch == 'l' | ch == 'r'));
        if numel(u) < 5, AB_Status.value = 'side: waiting for 5 rewards'; return; end
        k = exp(-((numel(u)-1):-1:0)' / value(AB_Tau));
        fl = sum(k .* (ch(u) == 'l')) / sum(k);
        gap = abs(2*fl - 1);
        beta = value(AB_BetaMin) + gap * (value(AB_BetaMax) - value(AB_BetaMin));
        p = min(1 - 2*min(max(value(AB_Floor), 0), 0.5), 2 * gap * beta / 10);
        AB_side_force_p.value = p;
        AB_beta_exact.value = beta;
        if fl > 0.5, under = 'r'; else, under = 'l'; end
        AB_Status.value = sprintf('side: %.0f%% L, P(force %s) %.2f', 100*fl, upper(under), p);
        if rand(1) < p, x = under; end

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
