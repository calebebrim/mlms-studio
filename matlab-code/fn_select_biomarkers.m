function [mz,ii]= fn_select_biomarkers(data,mask)
idx = data.idx;
lidx = size(idx,1);
mz = cell(lidx,1);
ii = cell(lidx,1);
for i = 1:lidx
    index =([idx{i}]==1 & mask==1) ;
    mz{i} = find(index);
    si = data.all{i};
    ii{i} = si(index);
end
end