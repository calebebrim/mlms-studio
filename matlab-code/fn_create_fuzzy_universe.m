function [mret] = fn_create_fuzzy_universe(w,ufuzzy)
%Prepara matriz com espectros das classes em data
d = 6;
n = size(w,1);

spect = zeros(n,ufuzzy);


for i=1:n
    spect(i,:) = fn_triang_fuzzy(w{i},d,ufuzzy);
end
mret = spect;

end