function w_data = fn_aligning(selector,w_data,by)

    gaopt = def_gaopt;
    gaopt.Display = 'iter';
    gaopt.InitialPopulation = [];
    gaopt.PopulationSize = 10;
    
    n = size(w_data.all,1);
    bsz  = 10;
    NVARS = n * bsz;
    pluscells = bits2num(ones(1,bsz));
    
    classes = [w_data.class{:}];
    uclass = unique(classes);
    for i = 1:length(uclass)
        idx{i} = classes == uclass(i);
        pclass = w_data.idx(idx{i});
        maxes = cellfun(@(x) sum(x),pclass);
        [~, where] = min(maxes);
        ucl(i,1:length(pclass{where})) = fn_triang_fuzzy(find(pclass{where}),100,length(pclass{where}));
    end
    pos = cellfun(@(val) find(val),w_data.idx,'UniformOutPut',false);
    
    [X,FVAL,EXITFLAG,OUTPUT] = ga(@fitnessfnii,NVARS,[],[],[],[],[],[],[],gaopt);
    
    desloc = bits2num(vet2mat(X,bsz));
    mxdslc =  max(desloc);
    spcsz = size(ucl,2);
    allii = zeros(1,spcsz+mxdslc);
    
    for i = 1:length(classes);
        
        cidx = desloc(i):-1+desloc(i)+length(w_data.idx{i});
        %idx
        allii = zeros(1,spcsz+mxdslc);
        allii(1+cidx) = w_data.idx{i};
        w_data.idx{i} = allii;
        
        allii = zeros(1,spcsz+mxdslc);
        allii(1+cidx) = w_data.all{i};
        w_data.all{i} = allii;
        
        allii = zeros(1,spcsz+mxdslc);
        allii(1+cidx) = w_data.mz{i};
        w_data.mz{i} = allii;
        
        allii = zeros(1,spcsz+mxdslc);
        allii(1+cidx) = w_data.cut_off{i};
        w_data.cut_off{i} = allii;
        
%         allii = zeros(1,spcsz+mxdslc);
%         allii(cidx) = intensities.data.mz{i};
%         intensities.data.idx = allii;
        

    end
    disp('done');
    function fit = fitnessfnii(x)
        desloc = bits2num(vet2mat(x,bsz));
        for i = 1:length(classes);
            cucl = ucl(classes(i)==uclass,:);
            posdesloc = [pos{i}+desloc(i)];
            posdesloc(posdesloc>length(cucl)) = [];
            f(i) = sum(cucl(posdesloc));
            
        end
        fit = -sum(f); 
    end
    
end








