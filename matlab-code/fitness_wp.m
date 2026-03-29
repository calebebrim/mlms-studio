function mret = fitness_wp(obj, arg, spect, cl)
vect = bits2num(vet2mat(arg,15))';
z = fn_inter_spectrum(obj,vect,spect,cl);
ln = length(vect);
mret = -z.strg + (length(unique(vect))~=ln)*10 + (sum(diff(sort(vect))>obj.wp_dfuzzy*5)~=ln-1)*10 ;
end