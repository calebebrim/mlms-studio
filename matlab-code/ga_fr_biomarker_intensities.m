function [mret, params,xpop] = ga_fr_biomarker_intensities(tr_selector,gen,sins,biomarker,data,cross_validation_rate,run_background)
disp('gaFRBiomarkerIntensities');


[xx,ii]= fn_select_biomarkers(data,biomarker.selected_peaks);
szxi = length(xx);
d = cell(szxi,1);
for i = 1:szxi
    d{i} = round([xx{i}].*[ii{i}]);
end
[mret, params] = ga_fr( tr_selector,...
    data.class,...
    d,...
    gen,...
    sins,...
    cross_validation_rate,...
    run_background);

mret.transform.preprocess_params = biomarker.selected_peaks;
mret.transform.preprocess = @parser;

mret.transform.name = [mret.transform.name ' (gaFRBiomarkerIntensities)'];

    function ii = parser(data,params)
        [~,ii] = fn_select_biomarkers(data,params);
    end
    
end