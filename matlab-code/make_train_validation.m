function [w,c] = make_train_validation(cross_validation_rate,trd,cltr)
if(size(cltr,1)<size(cltr,2))
cltr = cltr';
end
uclass = unique(cltr);
lc = length(uclass);
wtr = [];
wval = [];
ctr = [];
cval = [];
w = [];
c = [];
for cl = 1:lc
    cidx = cltr==uclass(cl);
    cdata = trd(cidx,:);
    cc = cltr(cidx,:);
    cross_selection = fn_cross_validation_selector(cross_validation_rate,size(cdata,1));
    if(cross_validation_rate<=0)
        wtr = [wtr; cdata];
        wval = [wval; cdata];
        
        ctr = [ctr; cc];
        cval = [cval; cc];
    elseif(cross_validation_rate<1)
        wtr = [wtr; cdata(~cross_selection,:)];
        wval = [wval; cdata(cross_selection,:)];
        
        ctr = [ctr; cc(~cross_selection,:)];
        cval = [cval; cc(cross_selection,:)];
    else
        lg = size(cross_selection,1);
        if(isempty(w))
            w = cell(lg,1);
            c = cell(lg,1);
        end
        for i = 1:lg
            idx = unique(cross_selection(i,:));
            w{i} = [w{i}; cdata(idx,:)];
            c{i} = [c{i}; cc(idx,:)];
        end
    end
end
if(cross_validation_rate<1)
    w{1} = wtr;
    w{2} = wval;
    c{1} = ctr;
    c{2} = cval;
end
end