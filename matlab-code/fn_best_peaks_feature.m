function mret = fn_best_peaks_feature(tr_selector,peaks_selector,w_data)



data = cell2mat(w_data.idx);
pks_idx = peaks_selector.selected_peaks;

wtr = data(tr_selector,pks_idx);
wts = data(~tr_selector,pks_idx);

mret = def_feature_structure();
if(sum(pks_idx)~=0)
    mret.tr.w = wtr;
    mret.tr_size = size(wtr,1);
    trstrg = corr(wtr,cell2mat(w_data.class(tr_selector)));
    trstrg(isnan(trstrg)) = 0;
    mret.tr.strg = mean(abs(trstrg));
    
    mret.ts_size = size(wts,1);
    mret.ts.w = wts;
    tsstrg = corr(wts,cell2mat(w_data.class(~tr_selector)));
    tsstrg(isnan(tsstrg)) = 0;
    
    mret.ts.strg = mean(abs(tsstrg));
    mret.feat_count = sum(pks_idx);
    mret.feat_corr = peaks_selector.values(pks_idx);
    mret.feat_corr_avg =  mean(abs(mret.feat_corr));
    mret.transform = def_transform_structure;
    mret.transform.function = @transform_function;
    mret.transform.name = ['correlation_feaure ' num2str(peaks_selector.cut_line)];
    mret.transform.preprocess = @(data,params)data;
    mret.transform.params = pks_idx;
    mret.cicles = 1;
end
    function mret = transform_function(params,data)
        szdata = length(data.all);
        transf  = zeros(szdata,sum(params));
        for i = 1:szdata
            all = data.all{i};
            transf(i,1:sum(params)) = all(params);
        end
        mret.w = transf;
    end


end
