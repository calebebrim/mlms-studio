function [feature,params] = ga_fr(tr_selector,class,w_all,cicles,sins,cross_validation_rate,run_background)
disp('starting frequence processor');

selector = tr_selector;

trd = w_all(selector);

cltr = cell2mat(class(selector));

%[wtr,wval,ctr,cval,cross_selector] = make_train_validation(cross_validation_rate,trd,cltr);

[w,c] = make_train_validation(cross_validation_rate,trd,cltr);

gaopt = gaoptimset;
gaopt.PopulationType = 'doubleVector';
gaopt.InitialPopulation = [];
gaopt.StallTimeLimit = 100000;
gaopt.PopulationSize = 30;
gaopt.Generations = 50;
gaopt.Display='off';
if(~run_background)
    gaopt.PlotFcns = {@testplot,@plotbest,@performance,@gaplotrange};
end




disp('Generation  Best.Train Cor.Train  Cor.Val   Best.Val Same.Count');


bestx = [];

figures =  findobj('type','figure');
nfigures = length(figures);
bestval_strg = 1000000;
besttr_strg = 1000000;
same_count = 0;

wtr = w{1:end-1};
wval = w{end};
ctr = c{1:end-1};
cval = c{end};


beststr = 1000000;
currenttr = 1000000;
currentval  = 1000000;
bestval = 100000;



for ii=1:cicles
    
    if(cross_validation_rate>1)
        ix = randperm(cross_validation_rate,cross_validation_rate);
        wtr = w{ix(1:end-1)};
        wval = w{ix(end)};
        ctr = c{ix(1:end-1)};
        cval = c{ix(end)};
    end
    [x, fval, ~, ~, xpop] = ga(@(arg) fitness_fr(arg,wtr,ctr),sins*3,gaopt);
    
    gaopt.InitialPopulation = xpop;
    atribval = fn_get_fr_cell_atrib(x, wval,cval);
    
    
    wtrcorr = 100*fval;
    wvalcorr = 100*-atribval.strg;
    
    if(bestval_strg == wvalcorr && besttr_strg==wtrcorr)
        same_count = same_count +1;
        if(same_count >= 4)
            
            break;
        end
    elseif(mean([bestval_strg besttr_strg]) > mean([wvalcorr ,wtrcorr]))
        %     elseif( bestval_strg>=wvalcorr && besttr_strg>=wtrcorr )
        besttr_strg = wtrcorr;
        bestval_strg = wvalcorr;
        bestx = x;
        same_count = 0;
        
    else
        same_count = 0;
    end
    disp([ii besttr_strg wtrcorr wvalcorr bestval_strg same_count]);
    beststr(ii)     = besttr_strg;
    currenttr(ii)   = wtrcorr;
    currentval(ii)  = wvalcorr;
    bestval(ii)     = bestval_strg;
    
    gaopt.InitialPopulation = bestx;
    
    
    
    
end




figure;
axi = gca;
plot_cross_validation_performace(abs(beststr),abs(currenttr),abs(currentval),abs(bestval),axi,true);
params = bestx;

feature = make_fr_feature_structure(tr_selector,w_all,class,bestx);

% mret.tr.hash = hashtrstr;

% mret.hash = hashii;

feature.params = params;
feature.cicles = cicles;
feature.transform.params = params;
feature.transform.function = @transform;
feature.transform.name = 'fn_sum_sins(params, data)';

    function state = testplot(options,state,flag)
        
        axx = findobj('Tag','ga_fr/testplot');
        set(axx,'NextPlot','replacechildren');
        axes(axx);
        title('Performing Peaks Weights.');
        if(~isempty( state.Best))
            best = find(state.Best(end)==state.Score, 1 );
            
            if(~isempty(best))
                
                switch flag
                    case 'init'
                        
                    
                    case 'iter'
                        
                        
                        if(~isempty(axx))
                            axes(axx)
                            plot_sins(state.Population(best,:),wtr,ctr,axx);
                        end
                end
            end
        end
    end
    function state = plotbest(options,state,flag)
        axx = findobj('Tag', 'ga_fr/plotbest');
        set(axx,'NextPlot','replacechildren');
        axes(axx);
        title('Best Peaks weights');
        switch flag
            case 'init'
                %                 axx = findobj('Tag', 'ga_fr/plotbest');
                %                 if(~isempty(axx))
                %                     axes(axx)
                %                     a = plot_sins(ECOSPEC,bestx,wtr,ctr);
                %                     set(a,'DisplayName','best');
                %                 end
            case 'iter'
                
                if(~isempty(axx))
                    %                     axes(axx)
                    plot_sins(bestx,wtr,ctr,axx);
                end
        end
    end

    function state = performance(options,state,flag)
        axx = findobj('Tag', 'ga_fr/performance');
        set(axx,'NextPlot','replacechildren');
        axes(axx);
        
        title('Cross Validation Performace');
        
        switch flag
            case 'init'
                %
            case 'iter'
                
                if(~isempty(axx))
                    %                     axes(axx)
                    plot_cross_validation_performace(abs(beststr),abs(currenttr),abs(currentval),abs(bestval),axx,false);
                end
        end
    end
    function data = transform(params,cell_data)
        data = def_feature_structure();
        data.w = cell2mat(cellfun(@(x) fn_sum_sins(params,x), cell_data, 'UniformOutput',false));
    end

    

end