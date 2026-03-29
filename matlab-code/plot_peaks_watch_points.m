function plot_peaks_watch_points( class, idx, params ,axx)
%plot position of peaks for each class


mycolors = 'ryg';
uclass = unique(class);

if(nargin<3)
    params = [];
end

lclass = length(uclass);

o = double(cell2mat(idx));
mx = size(o,2);

if(nargin<4)
    figure;
else
    axes(axx);
end
if(~isempty(class))
    for i = 1:lclass
        idx = uclass(i)==class;
        subplot(lclass,1,i);
        plotwp();
    end
else
    idx = 1:size(o,1);
    plotwp();
end




    function plotwp()
        
        hold('on');        
        to = max(o(idx,:),[],1);
        if(~isempty(params))
            [c,d] = fn_wp_params(params);
            lwp = length(c);
            for j = 1:lwp
                t =to.*repmat(fn_triang_fuzzy(c(j), d(j), mx),size(to,1),1);
                plot(t', mycolors(max(1, mod(j, 4))));
            end
        else
            t =to.* 1;
            plot(t', mycolors(1));
            
        end
        hold('off');
    end
end

