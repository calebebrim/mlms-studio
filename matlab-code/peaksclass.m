classdef peaksclass
    %peaksclass is a object that hold peaks data and realize operations
    %with its data
    
    
    
    properties
        use; % class selection ex: use = [1 3];
        use_labels;
        used_biomarkers;
        biomarkers_probability = 0.5;
        peaks_dfuzzy = 100;% peks half fuzzy distance, shoud be grater than 1
        wp_dfuzzy = 0; % watch points half fuzzy distance, set 0 to random
        ufuzzy % fuzzy universe especification
        same_stop_limit = 5;
        tr_percent = 0.7;
        
        
        tr_crossvalidation = 5;
        
        tr_selector = [];
        ga_optimset = def_gaopt;
        ga_watch_points = 10;
        ga_watch_points_nger = 1;
        ga_sins_nger = 20;
        tf_set;
        
        mlp_layers = [5 7 13];
        useplotfunc = false;
        plot_idx1 = [];
        plot_idx2 = [];
        plot_idx3 = [];
        
        data;
        
        selection_strategy = def_mm_selection_params;
    end
    
    methods(Static)
        
        
        
        
        
        
        function [x, y] = suavizapks(pks,window,show)
            %Feita para an?lise espectrometria de massa
            [x,y] = peaksclass.achapicos(peaksclass.mmvfuzzy2(pks,window),1);
            if(show)
                figure
                hold on
                plot(pks);
                plot(x,pks(x),'xr');
                hold off
            end
        end
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        function state = plotfunc(options,state,flag,w,tr,cl)
            
            persistent best_at_all; % Best score in the previous generation
            persistent wp;
            persistent wptf;
            
            best = min(state.Score); % Best score in the current generation
            if state.Generation == 0 % Set last_best to best.
                best_at_all = best;
                wp = state.Population(state.Score == min(state.Score),:);
                wp = bits2num(vet2mat(wp,15))';
                wptf = triangf(wp(1:end-1), max(1, mod(wp(end), 1000)), 20000);
            else
                % change = last_best - best; % Change in best score
                if(best_at_all>best)
                    best_at_all=best;
                    wp = state.Population(state.Score == min(state.Score),:);
                    wp = bits2num(vet2mat(wp,15))';
                    wptf = triangf(wp(1:end-1), max(1, mod(wp(end), 1000)), 20000);
                end
                
                nclass = unique(cl);
                lclass = length(nclass);
                classNames = unique(w(:,3));
                %trsz = size(w);
                for ic = 1:lclass
                    class = nclass(ic);
                    
                    figure(1);
                    
                    subplot(lclass,1,ic,'replace');
                    select = cl == class;
                    
                    pk = tr(select,:);
                    hold on
                    for pki = pk'
                        plot(pki,'b');
                    end
                    plot(wptf, 'r');
                    t = classNames{ic};
                    t = replace(t,'_',' ');
                    title(lower(t));
                    
                end
                
            end
            
        end
        
        
        
        
        
        
        function mret = readfile(Arq)
            fid = fopen(Arq, 'r');
            F = fread(fid, '*char')';
            fclose(fid);
            F(F==13) = [];
            F1 = F-0;
            nbreak = find(F1 == 10);
            maxlin = max(abs(diff(nbreak)));
            n = length(nbreak);
            m = maxlin;
            %nbreak = [1 nbreak];
            nbreak = [0 nbreak]; %corrigido em 01/08/2013
            matriz = 32*ones(n,m);
            io = 0;
            for i=1:(length(nbreak)-1)
                matriz(i,1:(nbreak(i+1)-nbreak(i)-1)) = F1((nbreak(i)+1):(nbreak(i+1)-1));
            end
            mret = char(matriz);
            
        end
        
    end
    
    methods
        function obj = peaksclass(file)
            if(nargin>0)
                config_file = peaksclass.readfile(file);
                peaksclass.setup(obj,config_file)
            end
            obj.ga_optimset = def_gaopt;
            obj.tf_set = def_triang_fuzzy_hash(2000);
            
        end
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
       
        
        
        
        
        
        function idented = report(result_data)
            [~,idented] = obj.tostring;
            idented = [ idented ,['Train score: ' num2str(result_data.certos)]];
            idented = [ idented ,'Confusion: '];
            idented = [ idented ,[num2str(result_data.conf) zeros(size(result_data.conf)) num2str(dts.conf)]];
            
            disp('====================================');
            
            for i = 1:length(idented)
                disp(idented{i});
            end
            disp('====================================');
        end
        
%         function [mret] = combine_features(obj,gens,features)
%             
%             [mret] = obj.gcombfeat(gens,features);
%         end
        
        
        
        
        
        
        function mret = get.ufuzzy(obj)
            if(isempty(obj.ufuzzy))
                % mx = round(obj.selected_maxmin);
                % mx = round(mx);
                % mret = mx+1;
                mret = length([obj.data.mz{1}]);
            else
                mret = obj.ufuzzy;
            end
        end
        
        function [net, result] = quickMLPTrainTest(obj,interSpec,layers)
            % Take interSpec struct data into MLP neural network, with default or preset layers
            % the output is an trained network and the result of test based in interSpec.ts.w
            if(nargin>=3)
                l = layers;
            else
                l = obj.mlp_layers;
            end
            net = mlp_tr(interSpec.tr.w,l);
            result = mlp_ts(interSpec.ts.w,net);
        end
        
        function mret = peaks(obj)
            w = obj.selectData();
            
            rows_ln = size(w,1);
            dots_ln = max(unique([w{:,1}]));
            dots = zeros(rows_ln,dots_ln);
            for i = 1:rows_ln
                dots(i,round(w{i,1}))=1;
            end
            mret = dots;
            
        end
        
        function mret = classLabels(obj)
            mret = obj.data.class;
            
        end
        
        function plot(obj,subselection)
            if(nargin<2)
                plotpeaks(selectData(obj));
            else
                plotpeaks(selectData(obj,subselection));
            end
        end
        
        
      
        function mret = alignspecs(obj)
            disp('starting align function');
            cltr = obj.selectLabels(obj.tr_selector);
            clts = obj.selectLabels(~obj.tr_selector);
            
            wtr = obj.selectData(obj.tr_selector);
            %wts = w_all(~obj.tr_selector);
            sztr = size(wtr);
            %nger = gen;
            gaopt = gaoptimset;
            gaopt.PopulationType = 'doubleVector';
            gaopt.InitialPopulation = [];
            gaopt.StallTimeLimit = 100000;
            gaopt.PopulationSize = 30;
            gaopt.Generations = 50;
            gaopt.Display='off';
            
            [x, fval, ~, ~, xpop] = ga(@(arg) fitness_fr(obj,arg),sztr(1),gaopt);
            
            
        end
        
        function mret = selectData(obj,subselection)
            selection = obj.selector();
            if(nargin>=2)
                selection(selection==1) = subselection;
            end
            mret = obj.data(selection==1,:);
        end
        
        
        
        function mret = selectBiomarkersByClass(obj,data)
            idx = obj.data.idx;
            lidx = length(idx);
            mret = cell(lidx,1);
            cl = data.class();
            ucl = unique(cl);
            
            for i = 1:lidx
                mret{i} = find([data.idx{i}]==1 & obj.used_biomarkers{cl(i)==ucl,1}==1);
            end
            
        end
        
        function mret = selectClass(obj,subselection)
            selection = obj.selector();
            if(nargin>=2)
                selection(selection==1) = subselection;
            end
            cl = obj.data_class;
            mret = cl(selection==1);
        end
        
        function mret = selectLabels(obj,subselection)
            selection = obj.selector();
            if(nargin>=2)
                selection(selection==1) = subselection;
            end
            cl = obj.classLabels();
            mret = cl(selection==1);
        end
        
        function mret = get.use(obj)
%             if(isempty(obj.use))
%                 if(isempty( obj.data.class))
%                     mret = unique(obj.data.class');
%                 end
%             else
%                 mret = obj.use;
%             end
            mret = obj.use;
        end
        
        
        function save(peaks,interSpec,xpop)
            % save current experiment with current date on current folder.
            % xpop = GA last population
            % interSpec = Object representing the intersection of watchpoint with fuzzy peak universe
            % peaks = this object
            
            date = datestr(now);
            if(exist('saved','file')==0)
                mkdir saved
            end
            try
                cmmand = ['save saved/' replace(date,' ','-') '-tr.strg[' num2str(interSpec.tr.strg) ']ts.strg[' num2str(interSpec.ts.strg) ']' replace(peaks.tostring,' ','') '.mat interSpec peaks xpop'];
            catch e
                disp('make shure if ''saved'' folder is''nt in your path')
            end
            disp(cmmand);
            eval(replace(cmmand,':','.'));
        end
        
        function [str , ident] = tostring(obj)
            %Return an abstract identification of this object.
            str = [];
            
            
            ident{1} = ['Used classes: [' num2str(obj.use) ']'];
            ident{2} = ['Train set size: [' num2str(sum(obj.tr_selector)) ']'];
            ident{3} = ['Test set size: [' num2str(sum(~obj.tr_selector)) ']'];
            ident{4} = ['Validation size: [' num2str(sum(obj.tr_selector)*obj.tr_crossvalidation) ']'];
            
            for i = ident
                str = [str ' ' [i{:}]];
            end
        end
        
    end
end




