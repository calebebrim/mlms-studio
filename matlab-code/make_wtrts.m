function [wtr,wts,all] = make_wtrts(tr_selector,features,data,use)

ctr = data.class(tr_selector);
cts = data.class(~tr_selector);
if(iscell(ctr))
    ctr = cell2mat(ctr);
end

if(iscell(cts))
    cts = cell2mat(cts);
end

wtr = [];
wts = [];

flength = length(features);

if(nargin<4 || isempty(use))
    use = 1:flength;
end

if(nargout>0)
    wtr = fn_transform(features,fn_resample_data(data,tr_selector));
    wtr = [wtr ctr];

end

if(nargout>1)
    wts = fn_transform(features,fn_resample_data(data,~tr_selector));
    wts = [wts cts];
end

if(nargout>2)
    all = fn_transform(features,fn_resample_data(data,tr_selector | ~tr_selector));
    all = [all cell2mat(data.class(tr_selector | ~tr_selector))];
end

end
