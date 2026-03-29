function [ mret ] = def_ui_best_feature_structure()
%DEF_BEST_FEATURE_STRUCTURE Summary of this function goes here
%   Detailed explanation goes here
mret.function_name = 'Correlation';
mret.function = @find_biomarker_correlation_based;
mret.idx = 1;
mret.cut_line = 0;

end

