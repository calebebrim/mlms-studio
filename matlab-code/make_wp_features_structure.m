function interSpec = make_wp_features_structure(tr_selector,data,params)
tr = tr_selector;



%tr
trd = data.selected_mz(tr);
cltr = cell2mat(data.class(tr));
interSpec = def_feature_structure();
interSpec.tr = fn_inter_spectrum(params,fn_create_fuzzy_universe(trd,size(data.mz{1},2)));
interSpec.tr.class = cltr;
interSpec.tr.strg = corr(interSpec.tr.w,interSpec.tr.class);


%ts
tsd = data.selected_mz(~tr);
clts = cell2mat(data.class(~tr));
interSpec.ts = fn_inter_spectrum(params,fn_create_fuzzy_universe(tsd,size(data.mz{1},2)));
interSpec.ts.class = clts;
interSpec.ts.strg = corr(interSpec.ts.w,interSpec.ts.class);

interSpec.transform.preprocess_params = size(data.mz{1},2);
interSpec.transform.preprocess = @(data,params)fn_create_fuzzy_universe(data.selected_mz,params);

interSpec.transform.function = @(params,data)fn_inter_spectrum(params,data);
interSpec.transform.name = 'interspc(params,data)';


interSpec.transform.params = params;
end