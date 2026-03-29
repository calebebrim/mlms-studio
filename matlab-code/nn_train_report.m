function out = nn_train_report(result_data)
dtr = result_data.tr;
dts = result_data.ts;
idented = {};
%[~,idented] = obj.tostring;


idented = [ idented ,['Train score: ' num2str(dtr.certos)]];
idented = [ idented ,['Test score: ' num2str(dts.certos)]];
idented = [ idented ,['Train proportional score: ' num2str(dtr.prop)]];
idented = [ idented ,['Test proportional score: ' num2str(dts.prop)]];

[trrecall,trprecision,traccuracy,trjaccard] = recall_precision_acurracy_jaccard(dtr.conf);
[tsrecal,tsprecision,tsacuracy,tsjaccard] = recall_precision_acurracy_jaccard(dts.conf);

idented = [ idented ,['Recall/Sensitivity(tr/ts): ' num2str([trrecall(1) tsrecal(1)])]];
idented = [ idented ,['Inverse Recall/Specificity(tr/ts): ' num2str([trrecall(2) tsrecal(2)])]];
idented = [ idented ,['Accuracy(tr/ts): ' num2str([traccuracy(1) tsacuracy(1)])]];
idented = [ idented ,['Precision(tr/ts): ' num2str([trprecision(1) tsprecision(1)])]];
idented = [ idented ,['Jaccard(tr/ts): ' num2str([trjaccard(1) tsjaccard(1)])]];


% idented = [ idented ,'Confusion Train/Test: '];
% idented = [ idented ,[num2str(dtr.conf(1,:)) zeros(size(dtr.conf)) num2str(dts.conf)]];

features = [result_data.features];
if(isempty( result_data.used))
    used = 1:length(features);
else
    used = result_data.used;
end
idented = [idented,'Feature correlation scores (training/test/featurefn)'];
for i = used
    idented = [idented, [num2str([i mean(abs(features(i).tr.strg)) mean(abs(features(i).ts.strg))]) ' ' features(i).transform.name]];
end
lns = cellfun(@(x) length(x),idented,'UniformOutPut',true);
lnidented = length(idented);
mxln = max(lns);
out = char(zeros(lnidented,mxln));

disp('====================================');
for i = 1:lnidented
    c = idented{i};
    disp(c);
    out(i,1:lns(i)) = c;
end
disp('====================================');

end