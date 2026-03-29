function [tr] = fn_percent_select_data(percentage,w_data)
parameterexception = MException('peaksclass:percentSelectData','percent should be greater than 0');
parameterformatexception = MException('peaksclass:percentSelectData','percentage array shoud contain values in 0:1');
if(nargin<2)
    percentage = ECOSPEC.tr_percent;
end

cl = cell2mat(w_data.class);

ucl = unique(cl);
ln_class = length(ucl);
ln_percnt = length(percentage);

if(ln_percnt==0)
    throw(parameterexception);
end

if(sum(percentage<0 | percentage>1)~=0)
    throw(parameterformatexception);
end
tr = 1==zeros(length(cl),1);
for i = 1:ln_class
    index = cl==ucl(i);
    cliCount = sum(index);
    ntr = ceil(cliCount * percentage);
    interval = find(index);
    tridx = interval(randperm(length(interval),ntr));
    
    tr(tridx) = true;
    
end
end