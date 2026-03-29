function mret = make_fr_feature_structure(tr_selector,w_all,class,params)

mret = def_feature_structure();

ctr = cell2mat(class(tr_selector));
clts = cell2mat(class(~tr_selector));

cltr = ctr;
% clval = ctr(cross_selector);

dtr = w_all(tr_selector);

wtr = dtr;
wts = w_all(~tr_selector);
% wval = dtr(cross_selector);

mret.tr = fn_get_fr_cell_atrib(params,wtr,cltr);
mret.ts = fn_get_fr_cell_atrib(params,wts,clts);
% mret.val = fn_get_fr_cell_atrib(params,wval,clval);

end