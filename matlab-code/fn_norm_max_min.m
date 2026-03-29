function [mret, mx, mn]   = fn_norm_max_min(w,mode,maxmin)
%FN_NORM_MAX_MIN - normaliza matriz para o intervalo 0 e 1
%w = matrix data;
%mode = normalization 
% 1 = by row;
% 2 = all;
% mazmin vector 
if(nargin<2 || isempty(mode))
    mode = 1;
end
[n,m] = size(w);

if(mode==1)
    if(nargin<3)
        mn = min(w,[],2);
        mx = max(w,[],2);
    else
        mx = maxmin(1);
        mn = maxmin(2);
    end
    mret = (w - repmat(mn,1,m))./repmat((mx-mn),1,m);
elseif(mode ==2)
    if(nargin<3)
        mn = min(w(:));
        mx = max(w(:));
    else
        mx = maxmin(1);
        mn = maxmin(2);
    end
    mret = (w - repmat(mn,n,m))./(repmat(mx,n,m) - repmat(mn,n,m));
end
end