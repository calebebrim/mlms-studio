function [mret] = ga_combined_features(tr_selector,data,nger,features,cross_validation_rate,background)
%afc e o aruquivo de padr?es com caracteristicas a combinar
%nger o numero de geracoes do AG
%global fc
% Em Fc vao as colunas a serem combinadas
% fcol e a funcao que combina o resultado de gcombfeat com o conjunto de
% treinamento
disp('combined feature');
%try
[dtr] = make_wtrts(tr_selector,features,data);
% [wtr,wval,ctr,cval] = make_train_validation(cross_validation_rate,dtr(:,1:end-1), dtr(:,end));
[w,c] = make_train_validation(cross_validation_rate,dtr(:,1:end-1), dtr(:,end));
wtr = w{1:end-1};
wval = w{end};
ctr = c{1:end-1};
cval = c{end};
%imx = length(fc(1,:));
nmx = size(dtr,2);
gaopt = gaoptimset;
gaopt.PopulationType = 'doubleVector';
gaopt.InitialPopulation = [];
gaopt.StallTimeLimit = 100000;
gaopt.PopulationSize = 30;
gaopt.Generations = 30;
gaopt.Display='off';
if(~background)
    gaopt.PlotFcns = {@performance,@gaplotrange};
end

hashtrstr = java.util.HashMap;
% hashvalstr = java.util.HashMap;
% hashii = java.util.HashMap;

beststr = 0;
currenttr = 0;
currentval  = 0;
bestval = 0;

bestx = [];
bestval_strg = 0;
besttr_strg = 0;
same_count = 0;
for ii=1:nger
    [x, fval, ~, ~, xpop] = ga(@(arg)fn_fcorr(arg,[wtr ctr]),3*nmx,gaopt);
    gaopt.InitialPopulation = bestx;
    wvalcorr = fn_fcorr(x,[wval cval]);
    wtrcorr = fn_fcorr(x,[wtr ctr]);
    %     hashtrstr.put(fval,x);
    %     hashvalstr.put(wvalcorr,x);
    %     hashii.put(ii,x);
    if(bestval_strg>=wvalcorr && besttr_strg>=wtrcorr )
        besttr_strg = wtrcorr;
        bestval_strg = wvalcorr;
        bestx = x;
    elseif(bestval_strg == wvalcorr && besttr_strg==wtrcorr)
        same_count = same_count +1;
        if(same_count >= peaks.same_stop_limit)
            break;
        end
    else
        same_count = 0;
    end
    disp([ii besttr_strg wtrcorr wvalcorr bestval_strg same_count]);
    beststr(ii)     = besttr_strg;
    currenttr(ii)   = wtrcorr;
    currentval(ii)  = wvalcorr;
    bestval(ii)     = bestval_strg;
    
end
params = bestx;
% conjunto que melhor repercurtiu nos testes
mret = make_combfit_feature_structure(tr_selector,data,params,features);


mret.cicles = nger;
%mret.tr.hash = hashtrstr;
%mret.ts.hash = hashvalstr;
% mret.hash = hashii;
mret.transform.features = features;

    function state = performance(options,state,flag)
        axx = findobj('Tag', 'ga_combined_features/performance');
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
end
