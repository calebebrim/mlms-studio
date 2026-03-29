function cross_selector = fn_cross_validation_selector(cross_validation_rate,szd)
%tr_crossvalidation = 0 dont use crossvalidation
%tr_crossvalidation = 1 use cros validation with random k
%resampling
%tr_crossvalidation < 1 and tr_crossvalidation > 0 use percentage
%resampling
%tr_crossvalidation > 1 use k folds to resapling
if(cross_validation_rate <= 0 )
    cross_selector = ones(szd(1),1)==1;
elseif(cross_validation_rate== 1)
    szcross = randi(szd(1),1);
    [~,selector] = sort(rand(1,szd(1)));
    cross_selector = zeros(szd(1),1) == 1;
    cross_selector(selector(szcross)) = 1;
elseif(cross_validation_rate> 1)
    
    intervals = (1:cross_validation_rate-1:szd)';
    cross_selector = intervallist2inds([intervals(1:end-1) [intervals(2:end)]]);
    cross_selector = cross_selector';
elseif(cross_validation_rate<1)
    szcross = round(szd*cross_validation_rate);
    [~,selector] = sort(rand(1,szd(1)));
    cross_selector = zeros(szd(1),1) == 1;
    cross_selector(selector(1:szcross)) = 1;
end

end