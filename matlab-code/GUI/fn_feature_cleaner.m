function [ feature_list ] = fn_feature_cleaner( feature_list )
%FN_FEATURE_CLEANER Summary of this function goes here
%   Detailed explanation goes here
    tf = feature_list;
    for i = 1:length(feature_list)
        f = feature_list(i);
        f.tr.w = [];
        f.ts.w = [];
        tf(i) = f;
    end
    feature_list = tf;
end

