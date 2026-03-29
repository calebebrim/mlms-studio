function [ feature] = def_ui_feature_structure()
%DEF_UI_FEATURE_STRUCTURE Summary of this function goes here
%   Detailed explanation goes here

feature.id = [];
feature.fname = [];
feature.function = [];
feature.reprocess = [];
feature.processed = false;

feature.reproces_feature_id = [];

feature.parameter_name = [];
feature.parameter_value = [];
feature.cross_validation_rate = [];


feature.use_cicles = true;
feature.cicles = [];

feature.use_cross_validation = true;

feature.use_feature_selection = false;

feature.feature_selection_function = [];
feature.background = false;
feature = catstruct(def_feature_structure,feature);




end

