function mret = def_triang_fuzzy_hash(maxtf)
if(nargin<1)
    maxtf = 1000;
end
mret = java.util.Hashtable;
for d = 1:maxtf
    ud = (1+d-abs([d+1-(0:(d+1)) (1:d+1)]))/(d+1);
    mret.put(d,ud);
end
end