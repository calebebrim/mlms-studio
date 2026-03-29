function mret = fitness_wp_marked(arg, data, classes,biomarkers,bites_ln)
    vect = bits2num(arg,bites_ln);
    szdata = size(data,2);
    params = [biomarkers vect];
    parsz = size(params,2);
    
    centers = params(1:parsz/2);
    centers(centers>szdata) = 0;
    params(1:parsz/2) = centers;
    
    mret = fn_inter_spectrum(params,data);
    mret.strg = corr(mret.w,classes);
end