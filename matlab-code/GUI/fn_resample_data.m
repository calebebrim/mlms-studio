function [ ndata ] = fn_resample_data( w_data,selector )
%FN_RESAMPLE_FEATURE Summary of this function goes here
%   Detailed explanation goes here
ndata = structfun(@transform,w_data,'UniformOutPut',false);

 

    function nf = transform(field)
        if(iscell(field) && ~isempty(field) && length(selector)==length(field))
            nf = field(selector);
        else
            nf = [];
        end
    end

end

