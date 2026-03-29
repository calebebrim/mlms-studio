function mret = fitness_counting(params, vals,class)
    w = cell2mat(cellfun(@(x) fn_sum_sins(params,x), vals, 'UniformOutput',false));
    mret = sum(w==0);
%     mret = sum(abs(abs(w)-class));
end