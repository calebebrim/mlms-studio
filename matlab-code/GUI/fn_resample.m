function [ all,mz ] = fn_resample(val, w_data , window)
%FN_RESAMPLE Summary of this function goes here
%   Detailed explanation goes here

    
    all = w_data.all(val);
    mz = w_data.mz(val);
    wsz = size(all,1);
    allmz = [mz{:}];
    mx = max(allmz(:));
    mn = min(allmz(:));
    
    
    
    nall = cell(wsz,1);
    H = waitbar(0,'processing');
    idx = cellfun(@(x) 1+round((window-1)*fn_norm_max_min(x,1,[mx mn])),mz,'UniformOutPut',false);
    
    for i = 1:wsz
        waitbar(i/wsz,H);
        
        [nidx,processed] = fn_execute_groups(all{i}, idx{i},@max);
        np = zeros(1,window);
        np(nidx) = processed';
        
        
        tdiff = diff(nidx);
        hasinterval = find(tdiff>1);
        inds = intervallist2inds([nidx(hasinterval)'+ones(length(hasinterval),1) nidx(hasinterval)'+tdiff(hasinterval)'-ones(length(hasinterval),1)]);
        
        np(inds) = repmat(mean(np([nidx(hasinterval)' nidx(hasinterval)'+tdiff(hasinterval)']),2),1,size(inds,2));
        
        
        nall{i} = np;
        nmz = zeros(1,window);
        [nidx,processed] = fn_execute_groups(mz{i}, idx{i},@mean);
        
        nmz(nidx) = processed';
        nmz(inds) = repmat(mean(nmz([nidx(hasinterval)' nidx(hasinterval)'+tdiff(hasinterval)']),2),1,size(inds,2));

        mz{i} = nmz;
%       nall(i,tidx) = tall(tidx);
        
%         for j = 1:window
%             nall(i,j) = max(tall(tidx==j));
%         end
    end
    all = nall;
%     all = cellfun(@(x) mean(fn_vet2mat(x,window),2)',all,'UniformOutPut',false);
%     mz = cellfun(@(x) mean(fn_vet2mat(x,window),2)',mz,'UniformOutPut',false);

end

