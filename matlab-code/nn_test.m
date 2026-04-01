function result = nn_test(ECOSPEC,train_structure,data)
result = def_feature_structure;
used = train_structure.used;
features = train_structure.features;
if(nargin<3)
    [wtr,wts] = make_wtrts(ECOSPEC,features,used);
else
    wtr = fn_transform(features,train_structure.tr.sampledata);
    wtr = [wtr;fn_transform(features,data)];
    
%     wtr = [wtr, ones(size(wtr,1),1)];
%     classes = unique(train_structure.tr.w(:,end));
%     for class = classes'
%         wtr = [wtr; train_structure.tr.w(find(train_structure.tr.w(:,end)== class,1,'first'),:)];
%     end
    
end

result.used = train_structure.used;
result.net = train_structure.net;
% result.net = polifan_tr(wtr,5,2000,500);
result.features = features;

if(nargin<3)
    result.ts = nn_mlp_ts(wts,result.net);
    result.tr = nn_mlp_ts(wtr,result.net);
    nn_train_report(ECOSPEC,result);
else
    out = round(sim(train_structure.net,wtr'));
    result.tr.Result = out(length(train_structure.tr.sampledata.all)+1:end);
end

end
