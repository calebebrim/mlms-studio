function mret = fn_pks_select(data,params)
window = params.window;
show = params.show;
data = cell2mat(data);
class = data(:,end);
data = data(:,1:end-1);
ldata = size(data,1);
%mret = cell(ldata,1);
mret.idx = {};
mret.cut_off = {};
mret.selected_mz = {};
mret.selected_i = {};
mret.all = {};
mret.mz = {};
mret.class = class;

disp('loading data...');
for i = 1:ldata
    disp(i);
    pks = data(i,:);
    
    [mz,y ]= peaksclass.suavizapks(pks,window,false);
    spk = (pks*0)==1;
    spk(mz) = 1;
    mret.idx{i,1} = int16(spk);          %.idx
    mret.cut_off{i,1} = y;            %.cut_off
    mret.selected_mz{i,1} = find(spk);   %.selected_mz
    mret.selected_i{i,1} = pks(spk);     %.selected_i
    mret.all{i,1} = pks;                 %.all
    mret.mz{i,1} = 1:length(pks);        %.mz
end
if(show)
    peaksclass.suavizapks(pks,window,true);
    peaksclass.suavizapks(data(1,:),window,true);
end
end
