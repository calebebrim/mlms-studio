function [mret,params, xpop] = ga_fr_watch_ii(ECOSPEC,gen,sins,watchFit,xpop)
%GA_FR_WATCH_II Summary of this function goes here
%   Detailed explanation goes here
disp('gaFRWatch')
if(nargin<5)
    xpop = [];
end

[c,d] = fn_wp_params(watchFit.transform.params);
dt = ECOSPEC.data;
usz = length(dt.mz{1});
biomarker = fn_triang_fuzzy(c,d,usz)>0;
[~,ii] = fn_select_biomarkers(dt,biomarker);
[mret,params, xpop] = ga_fr(ECOSPEC,ii,gen,sins,xpop);

mret.transform.preprocess_params = biomarker;
mret.transform.preprocess = @(data,params) fn_select_biomarkers(data,params);

mret.transform.name = [mret.transform.name ' (gaFRWatch)'];
end

