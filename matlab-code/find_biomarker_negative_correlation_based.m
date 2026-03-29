function [tr, correlation] = find_biomarker_negative_correlation_based(ECOSPEC,limit)
parameterexception = MException('peaksclass:percentSelectData','percent should be greater than 0');
parameterformatexception = MException('peaksclass:percentSelectData','percentage array shoud contain values in 0:1');
selector = ECOSPEC.tr_selector;
cl = ECOSPEC.data.class(selector);
idxs = ECOSPEC.data.idx(selector);
idxs = double(cell2mat(idxs));
ccr = corr(idxs,cl);
ccr(isnan(ccr)) = 0;

tr = (ccr>limit)';
correlation = ccr';
end