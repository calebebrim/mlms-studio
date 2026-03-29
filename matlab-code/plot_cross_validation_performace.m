function plot_cross_validation_performace(beststr,currenttr,currentval,bestval,axx,leg)
    axes(axx);
    hold on;
    plot(beststr,'g');
    plot(bestval,'g--');
    plot(currenttr,'b');
    plot(currentval,'b--');
    
    idx = find(bestval == bestval(end) & beststr == beststr(end),1);
    bestmean = (beststr+bestval)/2;
    currmean = (currenttr+currentval)/2;
    plot(bestmean,':g');
    plot(currmean,':b');
    plot(idx,currenttr(idx),'or');
    plot(idx,currentval(idx),'or');
    plot(idx,bestmean(idx),'or');
    plot(idx,currmean(idx),'or');
    if(leg)
        legend('Best Score',...
            'Current Score',...
            'Current Validation Score',...
            'Best Validation Score',...
            'Best TR/VAL Mean Score',...
            'Current TR/VAL Mean Score',...
            'Selected Configuration','Location','southwest');
    end
    hold off;
end