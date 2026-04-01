function [call,cmz] = fn_resize(val,handles,H)
    all =   handles.w_data.all(val);
    mz =    handles.w_data.mz(val);
    
    sizesall = cellfun(@(x) length(x),all,'UniformOutPut', true);
    call = cell(length(sizesall),1);
    cmz = cell(length(sizesall),1);
    
    
    
    waitbar(0,H,'Resizing...');
    for i = 1:length(sizesall)
        waitbar(i/length(sizesall),H) 
        z1 = zeros(1,max(sizesall));
        z1(1:sizesall(i)) = all{i};
        call{i} = z1;

        z1 = zeros(1,max(sizesall));
        z1(1:sizesall(i)) = mz{i};
        cmz{i} = z1;
    end
    waitbar(1,H,'Resizing Done!');
    
    function ii = reshape(matrix,mz,val)
        lmx = length(matrix);
        if(lmx>=2)
            half = fix(lmx/2);
            ii =[reshape(...
                        matrix(1:half)...
                        ,mz,val),...
                reshape(...
                    matrix(...
                        (half+1):end)...
                            ,mz,val)];
        else
            iii = (mz == matrix);
            if(sum(iii)>0)
                ii = val(iii);
            else
                ii = 0;
            end
            
        end
    end

     
end