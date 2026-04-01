function mret = uniquemax_x_in_ind(x, ind)
% retorna lista de pares de indices unicos (ind) cujo x associado seja o
% maximo encontrado
%
itn = x;
ids = ind;
%
[idsord ind] = sort(ids);
itnord = itn(ind);
[uidx ii] = unique(idsord);
list = [(1+ii-[1 diff(ii)])' ii'];
imx = intervallist2inds(list);
%
mret = [uidx' max(itnord(imx)')'];