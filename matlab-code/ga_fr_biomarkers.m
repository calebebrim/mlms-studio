function [mret,params] = ga_fr_biomarkers(tr_selector,gen,sins,biomarker,data,cross_validation_rate,run_background)
disp('gaFRBiomarkers')

speaks = biomarker.selected_peaks;
bio = fn_select_biomarkers(data,speaks);
[mret,params] = ga_fr(tr_selector,data.class,bio,gen,sins,cross_validation_rate,run_background);

mret.transform.preprocess_params = speaks;
mret.transform.preprocess = @(data,params) fn_select_biomarkers(data,params);

mret.transform.name = [mret.transform.name ' (gaFRBiomarkers)'];
end