function varargout = PerformanceMonitorSection(obj, action, varargin)
% PerformanceMonitorSection  -  flags problems and sends ONE summary e-mail
%                               after the session has stopped
%
% During the session the monitor checks recent trials after every trial and
% keeps a list of remarks (episodes: what, from which trial to which trial).
% Nothing is sent while the rat is running. When the session ends
% (pre_saving_settings, i.e. after runrats has stopped the protocol) it:
%   * writes the remarks summary into the Comments box (saved with the data)
%   * sends ONE e-mail to the rat's contacts, only if something is FLAGGED.
%
% What is checked:
%
%   Flag           Condition                                          Stages
%   -----------    -------------------------------------------------  --------------------
%   low_trials     fewer than min_valid_trials VALID trials (not       from low_trials_from_stage
%                  violations / timeouts) in the session               (default 2)
%   stalled        stage 5, 6 or 7 for >= stall_sessions sessions, or  stages 5-7 (end of session)
%                  the same sound level for >= stall_sessions sessions
%   (the checks below start at email_from_stage, default 5)
%   violations     violation rate >= viol_rate over the last window    stages 6-8 (and Arpit2StepTask)
%   side_bias      >= strategy_frac of recent first pokes to one side  expert phase
%   light_rule     lit-port choices >= strategy_frac or <= 1-frac      expert phase
%   category       "loud" responses >= strategy_frac or <= 1-frac      expert phase
%   perf_drop      recent hit rate >= drop_size below this rat's       expert phase
%                  usual (mean of its last 3 expert-phase sessions)
%
% Expert phase (MonitorExpertMode 'Auto by stage'): stage 7 at sound level 6
% (full distribution, no second chance) and stage 8. Earlier, strategies are
% normal learning.
% An episode is FLAGGED (goes into the e-mail) if it lasted at least
% persist_trials trials; shorter episodes are listed as brief remarks only.
% low_trials is always flagged.
%
% The Monitor button on the main window opens the remarks and thresholds.
% Its colour: green = nothing, orange = brief remarks only, red = flagged.
%
% Saved with the data: monitor_flags (per trial, bit k = check k active)
% and monitor_log (one row per episode).

GetSoloFunctionArgs(obj);

TYPES = {'low_trials', 'violations', 'side_bias', 'light_rule', 'category', 'perf_drop'};

switch action

    % ------------------------------------------------------------------
    case 'init'
        x = varargin{1}; y = varargin{2};

        PushbuttonParam(obj, 'MonitorButton', x, y, 'label', 'Monitor: no remarks', ...
            'TooltipString', 'Open the performance monitor remarks and thresholds');
        set_callback(MonitorButton, {mfilename, 'show'});
        try set(get_ghandle(MonitorButton), 'BackgroundColor', [0.75 1 0.75]); catch, end
        next_row(y);

        oldx = x; oldy = y; parentfig = double(gcf);
        % Window in pixels: thresholds in two columns at the bottom, remarks above
        SoloParamHandle(obj, 'myfig', 'value', figure( ...
            'closerequestfcn', [mfilename '(' class(obj) ', ''hide'');'], ...
            'MenuBar', 'none', 'Name', 'Performance Monitor', 'Units', 'pixels', ...
            'Position', [200 150 540 420], 'Visible', 'off'), 'saveable', false);
        % Remarks text (top half of the window)
        LF = 0.66;   % wider labels
        x = 10; y = 5;
        NumeditParam(obj, 'drop_size', 0.2, x, y, 'labelfraction', LF, 'label', 'Perf drop (hit frac)'); next_row(y);
        NumeditParam(obj, 'strategy_frac', 0.9, x, y, 'labelfraction', LF, 'label', 'Strategy fraction'); next_row(y);
        NumeditParam(obj, 'viol_rate', 0.5, x, y, 'labelfraction', LF, 'label', 'Viol. rate (st 6-7)'); next_row(y);
        NumeditParam(obj, 'persist_trials', 100, x, y, 'labelfraction', LF, 'label', 'Flag if lasts (tr)'); next_row(y);
        NumeditParam(obj, 'window', 60, x, y, 'labelfraction', LF, 'label', 'Window (trials)'); next_row(y);
        SubheaderParam(obj, 'title2b', 'Strategy / performance', x, y);
        next_column(x); y = 5;
        NumeditParam(obj, 'min_valid_trials', 80, x, y, 'labelfraction', LF, 'label', 'Min valid tr/session', 'TooltipString', ...
            'Valid = not a violation and not a timeout'); next_row(y);
        NumeditParam(obj, 'low_trials_from_stage', 2, x, y, 'labelfraction', LF, 'label', 'Valid check from st.'); next_row(y);
        NumeditParam(obj, 'stall_sessions', 6, x, y, 'labelfraction', LF, 'label', 'Stalled after (sess)', 'TooltipString', ...
            'Flag a rat that has been in stage 5, 6 or 7, or at the same sound level, for this many sessions'); next_row(y);
        NumeditParam(obj, 'email_from_stage', 5, x, y, 'labelfraction', LF, 'label', 'Other checks from st.'); next_row(y);
        MenuParam(obj, 'MonitorExpertMode', {'Auto by stage', 'Always expert', 'Never expert'}, 'Auto by stage', ...
            x, y, 'label', 'Expert phase', 'labelfraction', 0.4, 'TooltipString', ...
            'When strategy / performance checks are active'); next_row(y);
        ToggleParam(obj, 'email_alerts', 1, x, y, 'OnString', 'Summary e-mail ON', 'OffString', 'Summary e-mail OFF'); next_row(y);
        SubheaderParam(obj, 'title2', 'Session checks', x, y);

        % Remarks list. BControl draws its parameters on a full-window panel
        % ('ContainerPanel'); anything put directly on the figure ends up hidden
        % behind it, so the list goes on that panel too.
        panel = findobj(value(myfig), 'Tag', 'ContainerPanel');
        if isempty(panel), panel = value(myfig); end
        SoloParamHandle(obj, 'remarks_box', 'value', uicontrol(panel, 'Style', 'listbox', ...
            'Units', 'pixels', 'Position', [10 160 520 228], 'String', {'No remarks yet'}, ...
            'FontName', 'Courier', 'Max', 2, 'Min', 0), 'saveable', false);
        uicontrol(panel, 'Style', 'text', 'Units', 'pixels', 'Position', [10 390 520 20], ...
            'String', 'Remarks this session', ...
            'HorizontalAlignment', 'left', 'FontWeight', 'bold');


        % Per-session state
        SoloParamHandle(obj, 'ep_active', 'value', false(1, numel(TYPES)));
        SoloParamHandle(obj, 'ep_start',  'value', zeros(1, numel(TYPES)));
        % Saved with the data file
        SoloParamHandle(obj, 'monitor_flags', 'value', []);
        SoloParamHandle(obj, 'monitor_log',   'value', cell(0, 4));   % {type, start_trial, end_trial, message}
        % Saved with settings: this rat's recent expert-phase session hit rates
        SoloParamHandle(obj, 'expert_session_hits', 'value', [], 'save_with_settings', 1);

        x = oldx; y = oldy;
        figure(parentfig);
        varargout{1} = x; varargout{2} = y;

    % ------------------------------------------------------------------
    %   TRIAL: called from prepare_next_trial after SideSection has scored
    %   trial n_done_trials. Only bookkeeping, nothing is sent.
    % ------------------------------------------------------------------
    case 'trial'
        try
            n = n_done_trials + 0;
            if n < 1, return; end
            [st, expert] = feval(mfilename, obj, 'phase');
            cond = false(1, numel(TYPES)); msg = cell(1, numel(TYPES));

            if st >= value(email_from_stage)
                w   = max(10, round(value(window)));
                idx = max(1, n - w + 1):n;
                hh = value(hit_history);       hh = hh(:);
                vh = value(violation_history); vh = double(vh(:));
                ch = value(choice_history);    ch = ch(:);
                lh = value(light_history);     lh = lh(:);
                ca = value(category_history);  ca = ca(:);
                ce = value(cell_history);      ce = ce(:);
                f  = value(strategy_frac);

                % violations: stage 6 and 7 only
                if st >= 6 && numel(idx) >= w && mean(vh(idx)) >= value(viol_rate)
                    cond(2) = true; msg{2} = sprintf('violation rate %.2f', mean(vh(idx)));
                end
                if expert
                    v = idx(~isnan(hh(idx)) & ~isnan(ce(idx)) & (ch(idx) == 'l' | ch(idx) == 'r'));
                    if numel(v) >= round(w / 2)
                        fl = mean(ch(v) == 'l');
                        if fl >= f || fl <= 1 - f
                            cond(3) = true; msg{3} = sprintf('%.0f%% of first pokes to the left', 100*fl);
                        end
                        vl = v(lh(v) == 'l' | lh(v) == 'r');
                        if ~isempty(vl)
                            flit = mean(ch(vl) == lh(vl));
                            if flit >= f || flit <= 1 - f
                                cond(4) = true; msg{4} = sprintf('%.0f%% of first pokes to the lit port', 100*flit);
                            end
                        end
                        rl = mean((hh(v) == 1 & ca(v) == 1) | (hh(v) == 0 & ca(v) == 0));
                        if rl >= f || rl <= 1 - f
                            cond(5) = true; msg{5} = sprintf('%.0f%% "loud" responses', 100*rl);
                        end
                        base = value(expert_session_hits);
                        if ~isempty(base)
                            b  = mean(base(max(1, end-2):end));
                            hr = mean(hh(v));
                            if hr <= b - value(drop_size)
                                cond(6) = true; msg{6} = sprintf('hit rate %.2f vs usual %.2f', hr, b);
                            end
                        end
                    end
                end
            end

            % open / close episodes (low_trials is judged at the end of session)
            ea = value(ep_active); es = value(ep_start); lg = value(monitor_log);
            for t = 2:numel(TYPES)
                if cond(t) && ~ea(t)
                    ea(t) = true; es(t) = n;
                    lg(end+1, :) = {TYPES{t}, n, NaN, msg{t}}; %#ok<AGROW>
                elseif ~cond(t) && ea(t)
                    ea(t) = false;
                    r = find(strcmp(lg(:, 1), TYPES{t}) & isnan(cell2mat(lg(:, 3))), 1, 'last');
                    if ~isempty(r), lg{r, 3} = n; end
                end
            end
            ep_active.value = ea; ep_start.value = es; monitor_log.value = lg;

            mf = value(monitor_flags); mf(n) = sum(2.^(find(ea) - 1)); monitor_flags.value = mf;
            feval(mfilename, obj, 'refresh');
        catch ME
            warning('PerformanceMonitorSection:trial', '%s', ME.message);
        end

    case 'summary'
        % Stage / schedule information from the protocol itself, so this
        % file is identical in Arpit2StepTraining and Arpit2StepTask
        [~, sm] = feval(class(obj), obj, 'monitor_summary');
        varargout{1} = sm;

    case 'phase'
        sm = feval(mfilename, obj, 'summary');
        st = sm.stage_no;
        switch value(MonitorExpertMode)
            case 'Always expert', expert = true;
            case 'Never expert',  expert = false;
            otherwise,            expert = sm.expert;
        end
        varargout{1} = st; varargout{2} = expert;

    % ------------------------------------------------------------------
    %   Remarks text, flagged list, button colour
    % ------------------------------------------------------------------
    case 'remarks'
        n  = n_done_trials + 0;
        lg = value(monitor_log);
        lines = {}; flagged = {};
        for i = 1:size(lg, 1)
            e = lg{i, 3}; open = isnan(e); if open, e = n; end
            dur = e - lg{i, 2};
            if any(strcmp(lg{i, 1}, {'low_trials', 'stalled'})) || dur >= value(persist_trials)
                tag = 'FLAG '; flagged{end+1} = sprintf('%s (trials %d-%d): %s', lg{i, 1}, lg{i, 2}, e, lg{i, 4}); %#ok<AGROW>
            else
                tag = 'brief';
            end
            if open, oe = ' (ongoing)'; else, oe = ''; end
            lines{end+1} = sprintf('[%s] %-10s trials %d-%d%s: %s', tag, lg{i, 1}, lg{i, 2}, e, oe, lg{i, 4}); %#ok<AGROW>
        end
        varargout{1} = lines; varargout{2} = flagged;

    case 'refresh'
        [lines, flagged] = feval(mfilename, obj, 'remarks');
        try
            if isempty(lines)
                set(value(remarks_box), 'String', {'No remarks'});
                set(get_ghandle(MonitorButton), 'String', 'Monitor: no remarks', 'BackgroundColor', [0.75 1 0.75]);
            elseif isempty(flagged)
                set(value(remarks_box), 'String', lines);
                set(get_ghandle(MonitorButton), 'String', sprintf('Monitor: %d remark(s)', numel(lines)), 'BackgroundColor', [1 0.85 0.5]);
            else
                set(value(remarks_box), 'String', lines);
                set(get_ghandle(MonitorButton), 'String', sprintf('Monitor: %d FLAGGED', numel(flagged)), 'BackgroundColor', [1 0.5 0.5]);
            end
        catch
        end

    % ------------------------------------------------------------------
    %   END OF SESSION (pre_saving_settings: the protocol has stopped)
    % ------------------------------------------------------------------
    case 'end_of_session'
        try
            n = n_done_trials + 0;
            [st, expert] = feval(mfilename, obj, 'phase');
            lg = value(monitor_log);
            hh = value(hit_history);
            nvalid = sum(~isnan(hh));
            if st >= value(low_trials_from_stage) && nvalid < value(min_valid_trials)
                lg(end+1, :) = {'low_trials', 1, n, sprintf('only %d valid trials (%d trials in total)', nvalid, n)};
                monitor_log.value = lg;
            end
            sm0 = feval(mfilename, obj, 'summary');
            if isfield(sm0, 'sound_level') && sm0.stage_no >= 5 && sm0.stage_no <= 7
                if sm0.stage_sessions >= value(stall_sessions)
                    lg(end+1, :) = {'stalled', 1, n, sprintf('%d sessions in stage %d without passing', sm0.stage_sessions, sm0.stage_no)};
                    monitor_log.value = lg;
                elseif sm0.sound_level < 6 && sm0.sound_level_sessions >= value(stall_sessions)
                    lg(end+1, :) = {'stalled', 1, n, sprintf('%d sessions at sound level %d', sm0.sound_level_sessions, sm0.sound_level)};
                    monitor_log.value = lg;
                end
            end
            [lines, flagged] = feval(mfilename, obj, 'remarks');
            feval(mfilename, obj, 'refresh');

            % Comments (saved with the data)
            if isempty(lines)
                CommentsSection(obj, 'append_line', 'MONITOR: no remarks');
            else
                CommentsSection(obj, 'append_line', sprintf('MONITOR: %d remark(s), %d flagged', numel(lines), numel(flagged)));
                for i = 1:numel(lines), CommentsSection(obj, 'append_line', ['  ' lines{i}]); end
            end

            % One summary e-mail, only if something is flagged
            if ~isempty(flagged) && value(email_alerts) == 1
                [expmtr, rname] = SavingSection(obj, 'get_info');
                sm = feval(mfilename, obj, 'summary');
                hh = value(hit_history);
                body = [{sprintf('Rat %s (%s), rig %s, %s', rname, expmtr, get_hostname, datestr(now, 'yyyy-mm-dd HH:MM')), ...
                         sprintf('Stage: %s | trials %d | valid %d | hit rate %.2f', sm.stage_name, n, ...
                                 sum(~isnan(hh)), mean(hh(~isnan(hh)))), ' ', 'Flagged:'}, ...
                        cellfun(@(s) ['  - ' s], flagged, 'UniformOutput', false), ...
                        {' ', 'All remarks:'}, cellfun(@(s) ['  ' s], lines, 'UniformOutput', false), ...
                        {' ', sprintf('Sent by %s after the session ended.', class(obj))}];
                subject = sprintf('[%s] %s: %d flag(s)', class(obj), rname, numel(flagged));
                if send_alert_email(rname, subject, body)
                    CommentsSection(obj, 'append_line', 'MONITOR: summary e-mail sent');
                end
            end

            % Update this rat's expert baseline with today's hit rate
            if expert
                hh = value(hit_history); ce = value(cell_history);
                m = min(numel(hh), numel(ce));
                v = ~isnan(hh(1:m)) & ~isnan(ce(1:m));
                if sum(v) >= 50
                    b = value(expert_session_hits);
                    expert_session_hits.value = [b(:)' mean(hh(v))];
                end
            end
        catch ME
            warning('PerformanceMonitorSection:end_of_session', '%s', ME.message);
        end

    case 'close'
        if exist('myfig', 'var') && isa(myfig, 'SoloParamHandle') && ishandle(value(myfig)) %#ok<NODEF>
            delete(value(myfig));
        end
        delete_sphandle('owner', ['^@' class(obj) '$'], 'fullname', ['^' mfilename]);

    case 'show'
        feval(mfilename, obj, 'refresh');
        set(value(myfig), 'visible', 'on');

    case 'hide'
        set(value(myfig), 'visible', 'off');

    otherwise
        warning('PerformanceMonitorSection:action', 'Unknown action %s', action);
end
