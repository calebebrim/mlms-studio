function [c,d] = fn_wp_params(params)
l = length(params);
l = round(l/2);
d = max(1,fix(mod(params(l+1:end),10000)));
c = params(1:l);
end