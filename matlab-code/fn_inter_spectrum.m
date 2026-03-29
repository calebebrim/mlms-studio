function mret = fn_inter_spectrum(params, data)
%data = sparse(data);
% [n,m] = size(data);

[c,d] = fn_wp_params(params);
 c(c==0) = [];
 d(c==0) = [];

tf = sparse(fn_triang_fuzzy(c',d',size(data,2)));
w = full(sum(sparse(data)*tf',2));
mret.w = w;

end