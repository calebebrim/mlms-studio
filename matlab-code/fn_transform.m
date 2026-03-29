function mret = fn_transform(features,data)
% params = combfeatures.transform.features;

lnp = length(features);
wtr = [];

for i = 1:lnp
    p = features(i);
    preprocessed = p.transform.preprocess(data,p.transform.preprocess_params);
    nparam = p.transform.function(p.transform.params,preprocessed);
    wtr = [wtr, nparam.w];
end

mret = wtr;
end
