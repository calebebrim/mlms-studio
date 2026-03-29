function plot_correlation_cutline( correlation,cutline,plot_idx )
%FN_PLOT_CORRELATION_CUTLINE Summary of this function goes here
%   Detailed explanation goes here
    
if(nargin<2)
    
    plot(abs(correlation));
    hold on
    ln_correlation = length(correlation);
    plot([1 ln_correlation],[cutline cutline],'r');
%     plot([1 ln_correlation],[-0.01 max(max(correlation))+0.01],'.b');
    

    plot([1 ln_correlation],[-cutline -cutline],'r');
    xlabel('m/z');
    ylabel('correlation');
    hold off
    
else
    plot(plot_idx,correlation');
    hold(plot_idx, 'on')
    ln_correlation = length(correlation);
    plot(plot_idx,[1 ln_correlation],[cutline cutline],'r');
    plot(plot_idx,[1 ln_correlation],[-cutline -cutline],'r');
    plot(plot_idx,[1 ln_correlation],[-0.01 max(max(correlation))+0.01],'.b');
    hold(plot_idx, 'off')
    
end

end

