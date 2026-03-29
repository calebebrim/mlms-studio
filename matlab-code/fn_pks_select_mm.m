function w_data = fn_pks_select_mm(w_data,selector,wait_bar)
if(nargin<3)
    wait_bar = false;
end
%mret.transform.params = params;
if(wait_bar)
    H = waitbar(0,'preprocessing');
end

% class = [];
% if(size(data,2)==2)
%
%     class = data2(:,end);
%     data2 = data2(:,1:end-1);
% end

data = w_data.all(selector);
data_mz = w_data.mz(selector);
params = w_data.params;
data = cell2mat(data);
data_mz= cell2mat(data_mz);
ldata = size(data,1);

pwr = params.pwd;

df = params.fuzzyWindow;
img = params.show;
range = params.range;
if(isempty(range) || sum(range)==0)
    range = [1 size(data,2)];
end
mret = def_data_structure;
% mret.class = class;
mret.params = params;
% data = fn_norm_max_min(data);
interval_idx = min(max(range(1),1),size(data,2)):max(min(range(2),size(data,2)),size(data,2));
data = data(:,interval_idx);
data_mz = data_mz(:,interval_idx);

if(params.use_min_as_bottonline)
    if(wait_bar)
        waitbar(0.1,H,'Pre: Botton Line');
    end
    data = data-repmat(min(data,[],2),1,size(data,2));
end

if(~isempty(params.base_line_correction_val) && params.base_line_correction_val>0)
    if(wait_bar)
        waitbar(0.2,H,'Pre: Base Line Correction');
    end
    data = data-fn_mmv_fuzzy(data,params.base_line_correction_val,5);
end

if(params.use_abs_val)
    if(wait_bar)
        waitbar(0.3,H,'Pre: Absolute Values');
    end
    data = abs(data);
end

if(wait_bar)
    waitbar(0.4,H,'Pre: Cut Line');
end
mmall = fn_mmv_fuzzy(data,df,5)+params.allocation;
% tsmovavg(w_data.all{1}(1:4000),'s',5)

w_data.idx = [];            %.idx
w_data.cut_off = [];        %.cut_off
w_data.selected_mz = [];    %.selected_mz
w_data.selected_i = [];     %.selected_i
w_data.mz = [];
w_data.transformed = [];
w_data.all = {};

for i = 1:ldata
    if(wait_bar)
        waitbar(i/ldata,H,'Peaks Selection');
    else
%         disp(i);
    end
   
    pks = data(i,:);
    mm = mmall(i,:);
    sspk = (mm*pwr);% aplicacao de forca na curva
    
    
%     idx = fn_find_peaks(fn_mmv_fuzzy(pks,10,5),1);
    idx = fn_find_peaks(pks,1);
    nidx = idx(pks(idx)>(sspk(idx)));
   
    pos = zeros(size(pks));
    pos(nidx) = 1;
    
    w_data.idx{i,1} = double(pos);          %.idx
    w_data.cut_off{i,1} = sspk;             %.cut_off
    w_data.selected_mz{i,1} = nidx';        %.selected_mz
    w_data.selected_i{i,1} = pks(nidx);     %.selected_i
    w_data.all{i,1} = pks;                  %.all
    w_data.mz{i,1} = data_mz(i,:);          %.mz
end

if(img)
    plot_peaks_selection_preview(w_data)
end
if(wait_bar)
    delete(H);
end
end