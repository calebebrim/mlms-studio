function [result] = nn_train(tr_selector,layers,features,data,used)
result = def_feature_structure;


if(nargin<5)
    used = [];
end

[wtr,wts] = make_wtrts(tr_selector,features,data,used);
result.used = used;
result.net = nn_mlp_tr(wtr,layers);
% result.net = polifan_tr(wtr,5,2000,500);

classes = cell2mat(data.class);
uclass = unique(classes);
luc = length(uclass);
ifc = ones(1,luc);

for i = 1:luc
    ifc(i) = find(classes == uclass(i),1,'first');
end

ndata = fn_resample_data(data,ifc);

result.ts = nn_mlp_ts(wts,result.net);
result.tr = nn_mlp_ts(wtr,result.net);

result.tr.sampledata = ndata;
result.tr.w = wtr;
result.ts.w = wts;

% result.tr = polifan_ts(wtr,result.net.Net);
% result.ts = polifan_ts(wts,result.net.Net);

result.features = features;
out = nn_train_report(result);
msgbox(out);

end