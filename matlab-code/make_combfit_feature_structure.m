function mret = make_combfit_feature_structure(tr_selector,data,params,features)
[wtr,wts] = make_wtrts(tr_selector,features, data);
ctr = wtr(:,end);
cts = wts(:,end);


mret = def_feature_structure();

mret.tr.w = fn_fcol(params,wtr);
mret.tr.cormat = corr([mret.tr.w ctr]);
mret.tr.strg = mean(abs(mret.tr.cormat(1:end-1,end)));

mret.ts.w = fn_fcol(params,wts);
mret.ts.cormat = corr([mret.ts.w cts]);
mret.ts.strg = mean(abs(mret.ts.cormat(1:end-1,end)));

mret.transform.params = params;
mret.transform.name = 'fcol(params,data)';
mret.transform.function = @comb_transform;
mret.transform.preprocess_params = features;
mret.transform.preprocess = @(data,params) fn_transform(params,data);


    function transformed = comb_transform(params,data)        
        transformed.w = fn_fcol(params,data);
    end

end