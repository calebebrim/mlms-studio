function mret = fn_mmv_fuzzy(vect, vz,mode)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Media movel fuzzy melhorada usando fun??o triangular para os dois lados
%% Calebe 14-12-14 calebebrim@gmail.com
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(nargin<3)
    mode = 1;
end
mret = [];


switch(mode)
    case 1
        mret = mm3d(vect,vz);
    case 2
        mret = fnmmcellfun(vect,vz);
    case 3
        mret = defmm(vect,vz);
    case 4
        mret = fullvectorialmmf(vect,vz);
    case 5
        mret = semivectoroial(vect,vz);
        
end


    function mret = mm3d(vect,vz)
        fprintf('.');
        s = 2*vz+1;
        t = triang(s)';
        
        if(iscell(vect))
            vect = cell2mat(vect);
        end
        
        [m,n] = size(vect);
        indexes = repmat(repmat(1:n,s,1)'+(repmat(-vz:vz,n,1)),[1 1 m]);
        nvect = repmat([zeros(m,vz) vect zeros(m,vz)]',[1,1,m]);
        x(1,1,:) = n.*(0:m-1);
        xi = repmat(x,[n s 1]);
        iii = (indexes>0 & indexes<=n);
        c = nvect(vz+indexes+xi);
        ti = repmat(t,[n 1 m]);
        mret = sum((c .* ti),2)./(sum(iii .* ti,2));
        mret = mret(fn_vet2mat(1:length(mret(:)),n)) ;
    end

    function mret = defmm(vect,vz)
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Media movel fuzzy melhorada usando fun??o triangular para os dois lados
        %% Roberto 30-10-2013
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if(iscell(vect))
            mret = cellfun(@(x) defmm(x,vz),vect,'UniformOutPut',false);
        else
            fprintf('.');
            
            n = length(vect(1,:));
            s = 2*vz+1;
            t = triang(s)';
            svect = zeros(1,n);
            for i=1:n
                d = (i-vz-1);
                t0 = 1;
                if d<=0
                    k = vz + d;
                    t0 = vz - k + 1;
                end
                d  = (n-(i+vz));
                tE = s;
                if d<=0
                    tE = s + d;
                end
                i0 = max(i-vz,1);
                iE = min(i+vz,n);
                svect(i) = (vect(i0:iE)*t(t0:tE)')/sum(t(t0:tE));
            end
            mret = svect;
        end
    end

    function mret = fnmmcellfun(vect, vz)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Media movel fuzzy melhorada usando fun??o triangular para os dois lados
        %% Calebe 14-12-14 calebebrim@gmail.com
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        
        if(iscell(vect))
            mret = cellfun(@(x) fnmmcellfun(x,vz),vect,'UniformOutPut',false);
        else
            s = 2*vz+1;
            t = triang(s)';
            fprintf('.');
            [m,n] = size(vect);
            indexes = repmat(1:n,s,1)'+(repmat(-vz:vz,n,1));
            
            nvect = [zeros(m,vz) vect zeros(m,vz)];
            
            c = nvect(vz+indexes);
            mret = ((c * t')./((indexes>0 & indexes<=n) * t'))';
        end
    end

    function mret = fullvectorialmmf(vect,vz)
        
        if(iscell(vect))
            vect = cell2mat(vect);
        end
        
        s = 2*vz+1;
        t = triang(s)';
        fprintf('.');
        [m,n] = size(vect);
        indexes = repmat(repmat(1:n,s,1)'+(repmat(-vz:vz,n,1)),[m 1]);
        
        xi = repmat(((n)*ceil((1:(m*n))/n)-n)',1,s);
        
        nvect = [zeros(m,vz) vect zeros(m,vz)]';
        
        c = nvect(vz+indexes+xi);
        
        mret = ((c * t')./((indexes>0 & indexes<=n) * t'))';
        
        mret = mret(fn_vet2mat(1:(m*n),n));
        
        
        
    end

    function mret = semivectoroial(vect,vz)
        if(iscell(vect))
            vect = cell2mat(vect);
        end
        [n,m] = size(vect);
        nvect = [zeros(n,vz) vect zeros(n,vz)];
        s = (2*vz)+1;
        ii = repmat((-vz:vz),m,1)+repmat((1:m)',1,s);
        
        trg = triang(s);
        den = (ii<=m & ii>0)*trg;
        mret = zeros(n,m);
        for i = 1:n
            tvect = nvect(i,:);
            num = tvect(vz+ii) * trg;
            mret(i,:) = num./den;
        end
    end


end








%{

% version 1 working
function mret = fn_mmv_fuzzy(vect, vz)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Media movel fuzzy melhorada usando fun??o triangular para os dois lados
%% Roberto 30-10-2013
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
n = length(vect(1,:));
s = 2*vz+1;
t = triang(s)';
svect = zeros(1,n);
for i=1:n
    d = (i-vz-1);
    t0 = 1;
    if d<=0
        k = vz + d;
        t0 = vz - k + 1;
    end
    d  = (n-(i+vz));
    tE = s;
    if d<=0
        tE = s + d;
    end
    i0 = max(i-vz,1);
    iE = min(i+vz,n);
    svect(i) = sum((vect(i0:iE).*t(t0:tE)))/sum(t(t0:tE));
end
mret = svect;
end


%version 2 working

function mret = fn_mmv_fuzzy(vect, vz)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Media movel fuzzy melhorada usando fun??o triangular para os dois lados
%% Calebe 14-12-14 calebebrim@gmail.com
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    s = 2*vz+1;
    t = triang(s)';
    
    if(iscell(vect))
        mret = cellfun(@(x) mm(x),vect,'UniformOutPut',false);
    else
        mret = mm(vect);
    end
function mret = mm(vect)
        fprintf('.');
        [m,n] = size(vect);
        indexes = repmat(1:n,s,1)'+(repmat(-vz:vz,n,1));
        
        nvect = [zeros(1,vz) vect zeros(1,vz)];
        
        c = nvect(vz+indexes);
        mret = (c * t')./((indexes>0 & indexes<=n) * t');
    end
end
%}