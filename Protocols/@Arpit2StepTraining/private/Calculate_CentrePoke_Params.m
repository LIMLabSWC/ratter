function [prestim,A1,prego] = Calculate_CentrePoke_Params(fixed_length,cp_length,range_min_prestim,range_max_prestim, is_random_prestim, provided_time_prestim,...
    range_min_A1,range_max_A1, is_random_A1, provided_time_A1,range_min_prego,range_max_prego, is_random_prego, provided_time_prego)

if fixed_length == 1 % warm up stage where cp length is increasing
% then calculate the range/typical value
    if cp_length <= 0.3
        prestim = 0.1;
        A1 = 0.1;
        prego = 0.1;
    else
        range_size = round(0.3 * cp_length,1);
        if range_size > 0.4
            step_size = 0.1;
        else
            step_size = 0.01;
        end

        timerange = 0.1:step_size:range_size;

        if is_random_prestim == 1
            prestim = timerange(randi([1, numel(timerange)],1,1));
        else
            if provided_time_prestim <= range_size
                prestim = provided_time_prestim;
            else
                prestim = range_size;
            end

        end

        if is_random_A1 == 1
            A1 = timerange(randi([1, numel(timerange)],1,1));
        else
            if provided_time_A1 <= range_size
                A1 = provided_time_A1;
            else
                A1 = range_size;
            end
        end

        prego = cp_length - prestim - A1;

    end

else

    if is_random_prestim == 1
        range_size_prestim = range_max_prestim - range_min_prestim;
        if range_size_prestim > 0.4
            step_size_prestim = 0.1;
        else
            step_size_prestim = 0.01;
        end
        time_range_prestim = range_min_prestim:step_size_prestim:range_max_prestim;
        prestim = time_range_prestim(randi([1, numel(time_range_prestim)],1,1));
    else
        prestim = provided_time_prestim;
    end

    if is_random_A1 == 1
        range_size_A1 = range_max_A1 - range_min_A1;
        if range_size_A1 > 0.4
            step_size_A1 = 0.1;
        else
            step_size_A1 = 0.01;
        end
        time_range_A1 = range_min_A1:step_size_A1:range_max_A1;
        A1 = time_range_A1(randi([1, numel(time_range_A1)],1,1));
    else
        A1 = provided_time_A1;
    end

    if is_random_prego == 1
        range_size_prego = range_max_prego - range_min_prego;
        if range_size_prego > 0.4
            step_size_prego = 0.1;
        else
            step_size_prego = 0.01;
        end
        time_range_prego = range_min_prego:step_size_prego:range_max_prego;
        prego = time_range_prego(randi([1, numel(time_range_prego)],1,1));
    else
        prego = provided_time_prego;
    end

end
end