function [feature, pop] = ga_watch_points(tr_selector,nger, biomarker,w_data,cross_validation_rate,run_background)
%starts the genetic algoritm to find bests watchpoints.
%Optionally pass xpop as argument to feed ga initial population.
disp('Starting GAW processor');
%%disp(obj.tostring);
disp_biomarker_info(biomarker);
gaopt = def_gaopt;
params = [];



tr = tr_selector;


data = w_data;

trd = data.selected_mz(tr);
cltr = cell2mat(data.class(tr));

[w,c] = make_train_validation(cross_validation_rate,trd,cltr);

wtr = w{1:end-1};
wval = w{end};
ctr = c{1:end-1};
cval = c{end};

beststr = 0;
currenttr = 0;
currentval  = 0;
bestval = 0;

datatr = (fn_create_fuzzy_universe(wtr,length(w_data.mz{1})));
datats = (fn_create_fuzzy_universe(wval,length(w_data.mz{1})));

if(~run_background)
    gaopt.PlotFcns = {@testplot,@plotbest,@performance,@gaplotrange};
end



% hashtrstr = java.util.HashMap;
% hashtsstr = java.util.HashMap;
% hashii = java.util.HashMap;
bestx = [];
disp(biomarker.description);
biomarker = find(biomarker.selected_peaks);

bits_sz = 10;


bestval_strg = 0;
besttr_strg = 0;
same_count = 0;
for ii=1:nger
    tic
    gaopt.InitialPopulation = bestx;
    %                 if use_biomark
    [x, ~, ~, ~, pop,scores] = ga(@(arg) fitness_strg(fitness_wp_marked(arg,datatr,ctr,biomarker,bits_sz)),ift(~isempty(biomarker),bits_sz*length(biomarker),bits_sz*50),gaopt);
%     params = [biomarker bits2num(vet2mat(x,10))'];
    s = fitness_wp_marked(x,datats,cval,biomarker,bits_sz);
    r = fitness_wp_marked(x,datatr,ctr,biomarker,bits_sz);
    
    wvalcorr = fitness_strg(s);
    wtrcorr = fitness_strg(r);

%     hashtrstr.put(trstrg,params);
%     hashtsstr.put(tsstrg,params);
%     hashii.put(i,params);
    
    
    if(bestval_strg == wvalcorr && besttr_strg==wtrcorr)
        same_count = same_count +1;
        if(same_count >= 4)
            break;
        end
    elseif(bestval_strg>=wvalcorr && besttr_strg>=wtrcorr )
        besttr_strg = wtrcorr;
        bestval_strg = wvalcorr;
        bestx = x;
    
    else
        same_count = 0;
    end
    beststr(ii)     = besttr_strg;
    currenttr(ii)   = wtrcorr;
    currentval(ii)  = wvalcorr;
    bestval(ii)     = bestval_strg;
    
    disp(full([ii besttr_strg wtrcorr wvalcorr bestval_strg same_count]));
    params = [biomarker bits2num(bestx,bits_sz)];
end
%%m = size(datatr,2);
%%params(params>m) = m;

params = [biomarker bits2num(bestx,bits_sz)];




feature = make_wp_features_structure(tr_selector,data,params);
% feature.tr.hash = hashtrstr;

% feature.hash = hashii;
feature.cicles = ii;
feature.params = params;
feature.transform.params = params;
% feature.transform.function = @(params,data) fn_inter_spectrum(params,data);
% feature.transform.name = 'fn_inter_spectrum(params,data)';



plot_peaks_watch_points(cell2mat(data.class),data.idx,params);
disp_wp_feature(feature);
    function z = fitness_strg(mret)
          strg = [mret.strg];
          strg(isnan(strg)) = 0;
          z = -mean(abs(strg)) ;
    end
    function state = testplot(options,state,flag)
        if(~isempty( state.Best))
            best = find(state.Best(end)==state.Score, 1 ); 
            if(~isempty(best))
                
                axx = findobj(get(gca,'parent'),'Tag','ga_watch_points/testplot');
                if(~isempty(axx))
                    switch flag
                        case 'init'
%                             axes(axx)
%                             
%                             
%                             a = plot_peaks_watch_points([],data.idx,p);
%                             set(a,'Tag','ga_watch_points/testplot');
                        case 'iter'
                            axes(axx)
                            p = [biomarker bits2num(state.Population(best,:),bits_sz)];
                            plot_peaks_watch_points([],data.idx,p,axx);
                    end
                end
            end
        end
    end
    function state = performance(options,state,flag)
        axx = findobj('Tag', 'ga_watch_points/performance');
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
    function state = plotbest(options,state,flag)
         axx = findobj(get(gca,'parent'),'Tag','ga_watch_points/plotbest');
         if(~isempty(axx))
             axes(axx)
             plot_peaks_watch_points([],data.idx,params,axx);
         end
    end
    
end