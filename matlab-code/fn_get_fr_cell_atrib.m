function mret = fn_get_fr_cell_atrib(params, data,class)
mret.w = cell2mat(cellfun(@(x) fn_sum_sins(params,x), data, 'UniformOutput',false));
mr = [mret.w class];
cr = corr(mr,'type','Pearson');
mret.class = class;

strg = (abs(cr(1,2)));
cc = length(class);
uniques = zeros(1,cc); 
for c = 1:cc
    uniques(c) = length(unique(mret.w(class==class(c))));
end
mret.strg = strg;
mret.cormat = cr;
mret.params = params;
mret.uniques = uniques;
end