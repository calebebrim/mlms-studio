function [ idx,processed ] = fn_execute_groups( x, ids, func )
% retorna lista de pares de indices unicos (ind) cujo x associado seja o
% maximo encontrado
%
if(nargin<3)
    func = @max;
end

itn = x;
% ids = ind;
%
[idsord, ind] = sort(ids);
itnord = itn(ind);
[uidx, ii] = unique(idsord);
list = [(1+ii-[1 diff(ii)])' ii']; %criava um grupo com 1 unidade

% diffi = diff(ii);

% list = [(ii(2:end)-diffi)' ii(2:end)'];

imx = intervallist2inds(list);
%
idx = uidx; 

processed = (func(itnord(imx)'));
end

