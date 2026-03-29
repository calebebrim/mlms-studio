function [ mret ] = fn_vet2mat(vet,larg)
%cria matriz com os valores de vet com larg colunas (descata os excedentes)
lnv = length(vet);
idx = repmat((1:larg:lnv)',1,larg)+repmat(1:larg,ceil(lnv/larg),1)-1;
cr = sum(sum(idx>lnv))-1;
idx(idx>lnv) = lnv;
mret = vet(idx);
mret(end,end-cr:end) = 0;
%mret = vet2mat(vet,larg);

end

