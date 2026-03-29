function mret = fitness_fr(param, vals,class)
atrib = fn_get_fr_cell_atrib(param, vals,class);
mret = -atrib.strg;
end