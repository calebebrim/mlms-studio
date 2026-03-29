function [mret,params, xpop] = ga_fr_watch(ECOSPEC,gen,sins,watchFit,cross_validation_rate,run_background)
disp('gaFRWatch')

[c,d] = fn_wp_params(watchFit.transform.params);
dt = ECOSPEC.data;
usz = length(dt.mz{1});
biomarker = fn_triang_fuzzy(c,d,usz)>0;
bio = fn_select_biomarkers(dt,biomarker);

[mret,params, xpop] = ga_fr(bio,gen,sins,cross_validation_rate,run_background);

mret.transform.preprocess_params = biomarker;
mret.transform.preprocess = @(data,params) fn_select_biomarkers(data,params);

mret.transform.name = [mret.transform.name ' (gaFRWatch)'];
end
