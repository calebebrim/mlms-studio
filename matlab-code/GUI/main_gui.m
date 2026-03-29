function varargout = main_gui(varargin)
% MAIN_GUI MATLAB code for main_gui.fig
%      MAIN_GUI, by itself, creates a new MAIN_GUI or raises the existing
%      singleton*.
%
%      H = MAIN_GUI returns the handle to a new MAIN_GUI or the handle to
%      the existing singleton*.
%
%      MAIN_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MAIN_GUI.M with the given input arguments.
%
%      MAIN_GUI('Property','Value',...) creates a new MAIN_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before main_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to main_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help main_gui

% Last Modified by GUIDE v2.5 23-Jul-2015 17:14:49

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @main_gui_OpeningFcn, ...
    'gui_OutputFcn',  @main_gui_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);


if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before main_gui is made visible.
function main_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to main_gui (see VARARGIN)

% Choose default command line output for main_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes main_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = main_gui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in btn_import.
function btn_import_Callback(hObject, eventdata, handles)
% hObject    handle to btn_import (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
folder = uigetdir('.');

if(folder~=0)
    files = dir(folder);
    fl = length(files);
    fcidx = 1;
    H = waitbar(1);
    w = cell(1,3);
    fnames = {};
    for f = files'
        if(strfind(f.name,'.txt')>0)
            p = (fcidx/fl);
            waitbar(p,H,[ sprintf('%.2f', p*100) '% Importing File: ' f.name])
            w(fcidx,[1 2]) = fn_raw_file2w([folder '/' f.name]);
            fcidx = 1+fcidx;
            fnames = [fnames; f.name];
        end
    end
    waitbar(1,H,'finnished!');
    w_data = def_data_structure;
    w_data.files = fnames;
    w_data.all = w(:,2);
    w_data.mz = w(:,1);
    %w_data.class = w(:,3);
    set_override_or_update_data(handles,w_data);
    
    msgbox('Save the import progress before continue!','Hint');
end


function update_list_string_files(handles)
set(handles.list_w_data,'String',handles.w_data.files);
val = get_val_wdata_list(handles);
lfiles = length(handles.w_data.files);
if(lfiles==0)
    lfiles = 1;
    set(handles.list_w_data,'String','empty list');
end
if(val>lfiles)
    val = lfiles;
end
set(handles.list_w_data,'Value',val);

function valid = validate_w_data(handles)
isf = isfield(handles,'w_data');
valid = isf && ~isempty(handles.w_data.all);
if(~isf)
    handles.w_data = def_data_structure;
    guidata(handles.btn_load_data,handles);
end

function [w_data,handles] = set_override_or_update_data(handles,w_data)
try
    if(validate_w_data(handles))
        button = questdlg('Did you want to:','New Data','Replace all data','Join with current',[]);
        if(~strcmp('Replace all data',button))
            
            
            if(~isempty(handles.w_data.idx))
                w_data.idx = [handles.w_data.idx; w_data.idx];
                w_data.cut_off = [handles.w_data.cut_off; w_data.cut_off];
                w_data.selected_mz = [handles.w_data.selected_mz; w_data.selected_mz];
                w_data.selected_i = [handles.w_data.selected_i; w_data.selected_i];
                w_data.Aux = [];
                
            end
            if(~isempty(handles.w_data.all))
                w_data.all = [handles.w_data.all; w_data.all];
                w_data.files = [handles.w_data.files; w_data.files];
                w_data.mz = [handles.w_data.mz; w_data.mz];
                w_data.class = [handles.w_data.class(:); w_data.class(:)] ;
            end
        else
            
%             remove_all_w_data(handles);     
        end
    end
    handles.w_data = w_data;
    guidata(handles.btn_import,handles);
catch e
    e;
end
update_w_data_list(handles);



% --- Executes on selection change in list_w_data.
function list_w_data_Callback(hObject, eventdata, handles)
% hObject    handle to list_w_data (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns list_w_data contents as cell array
%        contents{get(hObject,'Value')} returns selected item from list_w_data
% set(handles.graph_preview,'ButtonDownFcn',@(x,y,e)graph_preview_ButtonDownFcn(handles.graph_preview,handles));
% guidata(hObject,  handles);
update_w_data_list(handles);

function update_w_data_list(handles)
if(isfield(handles,'w_data') &&~isempty(handles.w_data.all))
    
    val = get_val_wdata_list(handles);
    try
        YY = handles.w_data.all(val);
    catch e 
        if(~isempty( handles.w_data.all))
            YY = handles.w_data.all(1);
            val = 1;
        else
            YY = [];
        end
    end
    sizes = cellfun(@(x) length(x),YY);
    lusizes = length(unique(sizes));
    if(lusizes==1)
        plot(handles.graph_preview,cell2mat(handles.w_data.all(val))')
    else
        log(handles,'Spectrums must be the same size. Try resample.');
    end
    
    try
        update_pks_select_params(handles,false,false);
    catch e 
        log(handles,'peaks selection params update error');
    end
    try
        update_svd_plot(handles,val,false);
    catch e 
        log(handles,'SVD update error');
    end
    try
        update_sample_info(handles);
    catch e
        log(handles,'Sample data update error');
    end
%     set(handles.lbl_max,'String',['Max: ' num2str(unique(sizes'))]);
    
end
update_list_string_files(handles)



function val = get_val_wdata_list(handles)
val = get(handles.list_w_data,'Value');
if(sum(val>length(handles.w_data.all))>0)
    val = length(handles.w_data.all);
end
if(val == 0)
    val = 1;
end

function update_sample_info(handles)
val = get_val_wdata_list(handles);
YY = handles.w_data.all(val);
sizes = cellfun(@(x) length(x),YY);

[usizes,uszcount] = fn_count_unique(sizes);
if(size(handles.w_data.class,1)>0)
    [uclass,uclcount] = fn_count_unique([handles.w_data.class{val}]);

    class = [num2str(uclass) repmat(':',length(uclcount),1) num2str(uclcount)];
    
    set(handles.txt_class,'String',class);
end
sizes = [num2str(usizes) repmat(':',length(uszcount),1) num2str(uszcount)];
if(length(val)>3)
    ids = [ num2str(val(1)) ':' num2str(val(end))];
else
    ids = num2str(val);
end
   
set(handles.lbl_max,'String',sizes);
set(handles.lbl_sample_idx,'String',['Sample id:' ids]);




% --- Executes during object creation, after setting all properties.
function list_w_data_CreateFcn(hObject, eventdata, handles)
% hObject    handle to list_w_data (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
set(hObject,'Max',2,'Min',0)




function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over btn_import.
function btn_import_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to btn_import (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in btn_save.
function btn_save_Callback(hObject, eventdata, handles)
% hObject    handle to btn_save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[filename, pathname] =  uiputfile('*.mat','Save Imported Data','data.mat');
sfile = [pathname filename];
w_data = handles.w_data;
if(0~=filename)
    save(sfile , 'w_data');
end



% --- Executes on button press in btn_remove_w_data.
function btn_remove_w_data_Callback(hObject, eventdata, handles)
% hObject    handle to btn_remove_w_data (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = get_val_wdata_list(handles);
remove_w_data(handles,val)

function remove_w_data(handles,val)

if(isfield(handles,'w_data'))
    if(~isempty(handles.w_data.idx))
        handles.w_data.idx(val) = [];
        handles.w_data.cut_off(val) = [];
        handles.w_data.selected_mz(val) = [];
        handles.w_data.selected_i(val) = [];
        
    end
    if(~isempty(handles.w_data.all))
        handles.w_data.all(val) = [];
        handles.w_data.files(val) = [];
        handles.w_data.mz(val) = [];
        
        
    end
    if(~isempty(handles.w_data.class))
        handles.w_data.class(val) = [];
    end
end
guidata(handles.btn_remove_w_data,handles);

update_list_string_files(handles);



% --- Executes on button press in btn_load_data.
function btn_load_data_Callback(hObject, eventdata, handles)
% hObject    handle to btn_load_data (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[file, path] = uigetfile('*.mat','Choose .mat Spectrum Data File','data.mat');



if(file~=0)
%     fname = [path file];
    cd(path)
    H = waitbar(0.5,'Loading data...');
    load(file);
    waitbar(1,H,'Done!');
    try
        w_data = fn_fix_w_data(w_data);
        [~,handles] = set_override_or_update_data(handles,w_data);
    catch e
        msgbox('This file could not be imported!');
    end
end

list_w_data_Callback(hObject, eventdata, handles);

function w_data = fn_fix_w_data(w_data)
if(size(w_data.class,2)>size(w_data.class,1))
    w_data.class = w_data.class';
end



% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over list_w_data.
function list_w_data_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to list_w_data (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


function txt_class_Callback(hObject, eventdata, handles)
% hObject    handle to txt_class (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_class as text
%        str2double(get(hObject,'String')) returns contents of txt_class as a double


% --- Executes during object creation, after setting all properties.
function txt_class_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_class (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btn_allign_spctr.
function btn_allign_spctr_Callback(hObject, eventdata, handles)
% hObject    handle to btn_allign_spctr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if(isfield(handles,'w_data'))
    try
        val = get_val_wdata_list(handles);
        if(length(val) == 1)
            val = 1:length(handles.w_data.all);
        end
        up = 0.000000000001;
        [AlignedWineData, intervals, indexes] = icoshift (get_pop_align_mode(handles), cell2mat(handles.w_data.all(val))+up, get_txt_alignment_field(handles) , get_pop_align_fb(handles), [2 1 0]);
        
    catch e
        log(handles,e.message);
        log(handles,get_txt_alignment_field(handles));
        msgbox('Verify the align value or try apply the resample first');

    end
end

function mret = get_pop_align_fb(handles)
strg = get(handles.pop_align_fb,'String');
strg = strg(get(handles.pop_align_fb,'Val'));
if(strcmp(strg,'best ( b )'));
    mret = 'b';
else
    mret = 'f';
end

function mret = get_pop_align_mode(handles)
strg = get(handles.pop_align_mode,'String');
mret = strg(get(handles.pop_align_mode,'Val'));



function value = get_txt_alignment_field(handles)
strg = get(handles.txt_align_interval,'String');
value = eval(strg);


function log(handles,msg)
set(handles.lbl_logger,'String',msg);
disp(msg);


% --- Executes on button press in btn_norm.
function btn_norm_Callback(hObject, eventdata, handles)
% hObject    handle to btn_norm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
H = waitbar(0.5,'Normalising');
val = get_val_wdata_list(handles);
% [all,mz] = fn_resize(val,handles,H);
% handles.w_data.all(val) = all;
% handles.w_data.mz(val)  = mz;

handles.w_data.all(val) = cellfun(@(x) fn_norm_max_min(x), handles.w_data.all(val),'UniformOutPut',false);
guidata(hObject,handles);
list_w_data_Callback(hObject, eventdata, handles);
waitbar(1,H);
delete(H);

% --- Executes on button press in btn_pks_select.
function btn_pks_select_Callback(hObject, eventdata, handles)
% hObject    handle to btn_pks_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
update_pks_select_params(handles);




function txt_pwr_pks_select_Callback(hObject, eventdata, handles)
% hObject    handle to txt_pwr_pks_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_pwr_pks_select as text
%        str2double(get(hObject,'String')) returns contents of txt_pwr_pks_select as a double
update_pks_select_params(handles);

% --- Executes during object creation, after setting all properties.
function txt_pwr_pks_select_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_pwr_pks_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txt_line_move_Callback(hObject, eventdata, handles)
% hObject    handle to txt_line_move (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_line_move as text
%        str2double(get(hObject,'String')) returns contents of txt_line_move as a double
update_pks_select_params(handles);


% --- Executes during object creation, after setting all properties.
function txt_line_move_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_line_move (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txt_sensibility_pks_slct_Callback(hObject, eventdata, handles)
% hObject    handle to txt_sensibility_pks_slct (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_sensibility_pks_slct as text
%        str2double(get(hObject,'String')) returns contents of txt_sensibility_pks_slct as a double
update_pks_select_params(handles);


% --- Executes during object creation, after setting all properties.
function txt_sensibility_pks_slct_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_sensibility_pks_slct (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function txt_start_interval_Callback(hObject, eventdata, handles)
% hObject    handle to txt_start_interval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_start_interval as text
%        str2double(get(hObject,'String')) returns contents of txt_start_interval as a double
update_pks_select_params(handles);


% --- Executes during object creation, after setting all properties.
function txt_start_interval_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_start_interval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function slider3_Callback(hObject, eventdata, handles)
% hObject    handle to slider3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function slider3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function txt_stop_interval_Callback(hObject, eventdata, handles)
% hObject    handle to txt_stop_interval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_stop_interval as text
%        str2double(get(hObject,'String')) returns contents of txt_stop_interval as a double
update_pks_select_params(handles);


% --- Executes during object creation, after setting all properties.
function txt_stop_interval_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_stop_interval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function disable_pnl_pks_slct(handles)
set(findall(handles.pnl_peaks_selection, '-property', 'enable'), 'enable', 'off')

function enable_pnl_pks_slct(handles)
set(findall(handles.pnl_peaks_selection, '-property', 'enable'), 'enable', 'on')
set(findall(handles.pnl_peaks_selection, '-property', 'enable'), 'BackgroundColor', [ 0.92941     0.92941     0.92941]);


function handles = set_pks_select_params(handles,params)

set(handles.txt_pwr_pks_select,'String',params.pwd);
if(~isempty(params.range))
    set(handles.txt_start_interval,'String',params.range(1));
    set(handles.txt_stop_interval,'String', params.range(2));
end

set(handles.txt_line_move,'String',params.allocation);
set(handles.txt_sensibility_pks_slct,'String',params.fuzzyWindow);
set(handles.txt_base_line_param,'String',params.base_line_correction_val);
set(handles.ckb_use_abs_val,'Value',params.use_abs_val);
set(handles.chck_use_min_bot_ln,'Value',params.use_min_as_bottonline);
update_pks_select_params(handles,false,true);

function [data, params] = update_pks_select_params(handles,all,force)
% disable_pnl_pks_slct(handles);
params = def_mm_selection_params;
params.pwd = str2double(get(handles.txt_pwr_pks_select,'String'));
params.range = [str2double(get(handles.txt_start_interval,'String')),...
    str2double(get(handles.txt_stop_interval,'String'))];
params.allocation = str2double(get(handles.txt_line_move,'String'));
params.fuzzyWindow = str2double(get(handles.txt_sensibility_pks_slct,'String'));
% params.resample_rate = str2double(get(handles.txt_resample_rate,'String'));
params.base_line_correction_val = str2double(get(handles.txt_base_line_param,'String'));
params.use_abs_val = get(handles.ckb_use_abs_val,'Value');
params.use_min_as_bottonline =  get(handles.chck_use_min_bot_ln,'Value');
if(nargin<3)
    force = false;
end
if(nargin<2)
    all = false;
end
params.show = false;
if(get(handles.chck_preview_pks_select_auto  ,'Value') || force )
    log(handles,'processing....');
    
    try
        wait_bar = false;
        if(nargin>1 && all)
            wait_bar = true;
            
            selector = 1:length(get(handles.list_w_data,'String'));
        else
            selector = get_val_wdata_list(handles);
            selector = selector(1:min(10,length(selector)));
        end
        
        handles.w_data.params = params;
        
        data = fn_pks_select_mm(handles.w_data,selector,wait_bar);
        
        
        plot_peaks_selection_preview(data,handles.peaks_selection_preview);
        log(handles,'ok....');
        try
            update_svd_plot(handles,selector,false);
            log(handles,'svd done');
        catch e
            log(handles,'svd needs peaks selection');
        end
    catch e
        log(handles,['Internal Error.' e.message ' ' e.stack(1).name ':' e.stack(1).line] );
    end
    
    
else
    try
        if(nargin>1 && all)
            
            selector = 1:length(get(handles.list_w_data,'String'));
        else
            selector = get_val_wdata_list(handles);
            selector = selector(1:min(10,length(selector)));
        end
        data = def_data_structure;
        data.all = handles.w_data.all(selector);
        data.selected_mz = handles.w_data.selected_mz(selector);
        data.cut_off = handles.w_data.cut_off(selector);
        plot_peaks_selection_preview(data,handles.peaks_selection_preview);
    catch e
        e.message;
    end
end

enable_pnl_pks_slct(handles);


% --- Executes on button press in ckb_use_abs_val.
function ckb_use_abs_val_Callback(hObject, eventdata, handles)
% hObject    handle to ckb_use_abs_val (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ckb_use_abs_val
update_pks_select_params(handles);



function txt_base_line_param_Callback(hObject, eventdata, handles)
% hObject    handle to txt_base_line_param (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_base_line_param as text
%        str2double(get(hObject,'String')) returns contents of txt_base_line_param as a double
update_pks_select_params(handles);


% --- Executes during object creation, after setting all properties.
function txt_base_line_param_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_base_line_param (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btn_apply_pks_slct.
function btn_apply_pks_slct_Callback(hObject, eventdata, handles)
% hObject    handle to btn_apply_pks_slct (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = update_pks_select_params(handles,true,true);
handles.w_data = data;
handles = update_svd_plot(handles,[],true);
guidata(hObject,handles);

% set(handles.chck_preview_pks_select_auto,'Value',false);
% update_svd_plot(handles,[],true);

function handles = update_svd_plot(handles,selector,wait_bar,adicional_data)

if(nargin<3)
    wait_bar = false;
end
if(wait_bar)
%     H = waitbar(0,'Computing SVD');
end
Aux = [];
if(wait_bar)
    svddata = cell2mat(handles.w_data.idx);
    if(nargin>3)
        svddata = adicional_data;
    end
    [U,s,Aux] = msvd(svddata,3);
    handles.w_data.Aux = Aux;
    
    guidata(handles.btn_train,handles);
    plot_svd3_classes(Aux,handles.w_data.class,selector);
    
elseif(isfield(handles.w_data,'Aux'))
    Aux = handles.w_data.Aux;
end
% i = 1;

if(~isempty(Aux))
    plot_svd2_classes(Aux,handles.w_data.class,selector,handles.peaks_svd_preview);
%     if(isempty([handles.w_data.class]))
%         plot_aux2(Aux,'',handles.peaks_svd_preview);
%     else
%         classes = [handles.w_data.class{:}];
%         cuni = unique(classes);
%         plot(handles.peaks_svd_preview,0,0)
%         hold(handles.peaks_svd_preview,'on')
%         for i = 1:length(cuni)
%             if(wait_bar)
%                 waitbar(i/length(cuni),H,'Computing SVD');
%             end
%             idx = cuni(i)==classes;
%             plot_aux2(Aux(:,idx),plot_options(i),handles.peaks_svd_preview);
%         end
%         if(wait_bar)
%             waitbar(1,H,'SVD Done!');
%         end
%     end
%     if(nargin>1 && ~isempty(selector))
%         plot_aux2(Aux(:,selector),plot_options(i+1),handles.peaks_svd_preview)
%     end
%     hold(handles.peaks_svd_preview,'off')
end

% --- Executes on button press in btn_preview_pks_slct.
function btn_preview_pks_slct_Callback(hObject, eventdata, handles)
% hObject    handle to btn_preview_pks_slct (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
update_pks_select_params(handles,false,true);


% --- Executes on button press in chck_preview_pks_select_auto.
function chck_preview_pks_select_auto_Callback(hObject, eventdata, handles)
% hObject    handle to chck_preview_pks_select_auto (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chck_preview_pks_select_auto


% --- Executes on button press in chck_use_min_bot_ln.
function chck_use_min_bot_ln_Callback(hObject, eventdata, handles)
% hObject    handle to chck_use_min_bot_ln (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chck_use_min_bot_ln
update_pks_select_params(handles);



function txt_resample_rate_Callback(hObject, eventdata, handles)
% hObject    handle to txt_resample_rate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_resample_rate as text
%        str2double(get(hObject,'String')) returns contents of txt_resample_rate as a double
update_pks_select_params(handles);

% --- Executes during object creation, after setting all properties.
function txt_resample_rate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_resample_rate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function pnl_peaks_selection_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pnl_peaks_selection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in chck_show_pks_selector.
function chck_show_pks_selector_Callback(hObject, eventdata, handles)
% hObject    handle to chck_show_pks_selector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chck_show_pks_selector
if(get(hObject,'Value'))
    update_pks_select_params(handles,true,true);
    set(handles.chck_preview_pks_select_auto,'Value',0)
end

% --- Executes on button press in btn_save_pks_select_config.
function btn_save_pks_select_config_Callback(hObject, eventdata, handles)
% hObject    handle to btn_save_pks_select_config (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[~,params] = update_pks_select_params(handles);

[filename, pathname] =  uiputfile('*.mat','Save peaks selection configuration','pks_select_config.mat');
sfile = [pathname filename];
if(filename~=0)
    log(handles,'Saving peaks selection configuration on... (now working)');
    save(sfile , 'params');
else
    log(handles,'Cancel.');
end


% --- Executes on button press in btn_load_pks_select_config.
function btn_load_pks_select_config_Callback(hObject, eventdata, handles)
% hObject    handle to btn_load_pks_select_config (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[file, path] = uigetfile('*.mat','Choose configuration file','pks_select_config.mat');
if(file~=0)
    fname = [path file];
    load(fname);
    try
        set_pks_select_params(handles,params);
        
    catch e
        msgbox('This file could not be imported!');
    end
end


% --- Executes on mouse press over axes background.
function graph_preview_ButtonDownFcn(hObject, handles)
% hObject    handle to graph_preview (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
axesHandle  = get(hObject,'Parent');
coordinates = get(axesHandle,'CurrentPoint');
coordinates = coordinates(1,1:2);
if(hasfield(handles,'align_pos'))
    cpos = handles.align_pos==coordinates(1);
    if(sum(cpos)>0)
        handles.align_pos(cpos) = [];
    else
        handles.align_pos = [handles.align_pos coordinates(1)];
    end
else
    handles.align_pos = coordinates(1);
end
guidata(hObject,handles)
v_markers = handles.align_pos;
val = get_val_wdata_list(handles);
hold(handles.graph_preview,'on')
plot(handles.graph_preview,handles.w_data.w{val(1),1},cell2mat(handles.w_data.w(val,2)))

for i = v_markers
    plot([i i],[1 0],'-r');
end
hold(handles.graph_preview,'off');
disp(['clicked on: ' num2str(coordinates(1))]);
set(handles.graph_preview,'ButtonDownFcn',@(x,y,e)graph_preview_ButtonDownFcn(handles.graph_preview,handles))


% --- Executes during object creation, after setting all properties.
function graph_preview_CreateFcn(hObject, eventdata, handles)
% hObject    handle to graph_preview (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate graph_preview



% --- Executes on button press in btn_resample.
function btn_resample_Callback(hObject, eventdata, handles)
% hObject    handle to btn_resample (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    val = get_val_wdata_list(handles);
    [all,mz] = fn_reshape(val(1),handles.w_data,str2double(get(handles.txt_resample_rate,'String')));
    figure; plot(all{1}');
catch e
    msgbox('Verify the resample value');
    disp(e.message)
end



function txt_align_interval_Callback(hObject, eventdata, handles)
% hObject    handle to txt_align_interval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_align_interval as text
%        str2double(get(hObject,'String')) returns contents of txt_align_interval as a double


% --- Executes during object creation, after setting all properties.
function txt_align_interval_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_align_interval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btn_apply_resample.
function btn_apply_resample_Callback(hObject, eventdata, handles)
% hObject    handle to btn_apply_resample (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try
    val = get_val_wdata_list(handles);
    [all,mz] = fn_reshape(val,handles.w_data,str2double(get(handles.txt_resample_rate,'String')));
    figure; plot(all{1}');
    
    handles.w_data.all(val) = all;%<<<<<<<<<<<<<<<<<<
    handles.w_data.mz(val) = mz;
    guidata(hObject,handles);
    list_w_data_Callback(hObject,eventdata,handles);
catch e
    msgbox('Verify the resample value');
end

% --- Executes on button press in btn_apply_align.
function btn_apply_align_Callback(hObject, eventdata, handles)
% hObject    handle to btn_apply_align (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = get_val_wdata_list(handles);
if(length(val) == 1)
    val = 1:length(handles.w_data.all);
end

if(isfield(handles,'w_data'))
    try
        up = 0.000000000001;
%         [AlignedWineData, intervals, indexes] = icoshift ('max', cell2mat(handles.w_data.all)+up, get_txt_alignment_field(handles) , 'b', [2 1 0]);
        [AlignedWineData, intervals, indexes] = icoshift (get_pop_align_mode(handles), cell2mat(handles.w_data.all(val))+up, get_txt_alignment_field(handles) , get_pop_align_fb(handles), [2 1 0]);

        for i = 1:size(AlignedWineData,1)
            all{i,1} = AlignedWineData(i,:)-up;
        end
        handles.w_data.all(val) = all;%<<<<<<<<<<<<<<<<<<
        guidata(hObject,handles);
    catch e
        msgbox('Verify the resample value');
    end
end


% --- Executes on button press in btn_train.
function btn_train_Callback(hObject, eventdata, handles)
% hObject    handle to btn_train (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
features = handles.feature_list;

w_data = handles.w_data;

[train_structure] = nn_train(get_tr_selector(handles),[1 2 3 7 11],features,w_data);

handles.train_structure = train_structure;

update_confusion_mat(handles,train_structure.tr.conf);

% fn_transform(features,w_data);

[~,~,all] = make_wtrts(get_tr_selector(handles),features,w_data);

update_svd_plot(handles,get_val_wdata_list(handles) ,true,all(:,1:end-1));

guidata(hObject,handles);


function handles = update_confusion_mat(handles,data)
set(handles.tbl_confusion_mat,'Data',data);





% --- Executes on button press in btn_test.
function btn_test_Callback(hObject, eventdata, handles)
% hObject    handle to btn_test (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if(validate_nn(handles))
    train_structure = handles.train_structure;
    update_confusion_mat(handles,train_structure.ts.conf);
else
    msgbox('Must Train First');
    log(handles,'The neural network is not trained, try click on Train Button before');
end
function logic = validate_nn(handles)
logic = isfield(handles,'train_structure') && ~isempty(handles.train_structure);


% --- Executes on button press in btn_save_nn.
function btn_save_nn_Callback(hObject, eventdata, handles)
% hObject    handle to btn_save_nn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if(validate_feature_list(handles))
    [filename, pathname] =  uiputfile('*.mat','Save Network','network.mat');
    sfile = [pathname filename];
    train_structure = handles.train_structure;
    if(0~=filename)
        save(sfile , 'train_structure');
    end
    log(handles,'Network Saved');
else
    log(handles,'No network to save');
end



% --- Executes on button press in btn_load_nn.
function btn_load_nn_Callback(hObject, eventdata, handles)
% hObject    handle to btn_load_nn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[file, path] = uigetfile('*.mat','Choose .mat Neural Network File','network.mat');

if(file~=0)
    fname = [path file];
    try
        log(handles,'loading...');
        pointer_watch(handles);
        load(fname);
        log(handles,'loaded!');
        pointer_arrow(handles);
    catch e
        log(handles,e.message);
    end
    try
        set_neural_network(handles,train_structure);
    catch e
        log(handles,e.message);
        msgbox('This file could not be imported!');
    end
end
function handles = set_neural_network(handles,train_structure)
if(validate_nn(handles))
    button = questdlg('Did you want to:','Loading Neural Network','Replace Current Neural Network','Cancel',[]);
    if(strcmp('Replace Current Neural Network',button))
        handles = replace_nn(handles,train_structure);
    else
        log(handles,'Load neural network cancelled');
    end        
else
    handles = replace_nn(handles,train_structure);
end

function handles = replace_nn(handles,train_structure)
handles.train_structure = train_structure;
guidata(handles.btn_load_nn,handles);
log(handles,'Neural networt loaded');

function pointer_watch(handles)
pointer_type(handles,'watch');

function pointer_arrow(handles)
pointer_type(handles,'arrow');

function pointer_type(handles,type,parent)
if(nargin<3 || isempty(parent))
    parent = handles.figure1;
end

set(parent,'Pointer',type)
children = get(parent,'children');
for i = children
    try
        pointer_type(handles,type,i);
    catch e
        log(handles,e.message);
    end
end


% --- Executes on button press in btn_test_on_list.
function btn_test_on_list_Callback(hObject, eventdata, handles)
% hObject    handle to btn_test_on_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if(validate_nn(handles))
    val = get_val_wdata_list(handles);
    selected_data = recriate_w_data(handles.w_data,val);
    test_structure = nn_test(get_ecospec(handles),handles.train_structure,selected_data);
    msgbox([ repmat('Sample: ',length(val),1) num2str(val') repmat(' Class: ',length(val),1) num2str(test_structure.tr.Result')],'Class.'); 
%     update_confusion_mat(handles,test_structure.tr.conf);
    
else
    msgbox('Must Train First');
    log(handles,'The neural network is not trained, try click on Train Button before');
end

% --- Executes on selection change in list_features.
function list_features_Callback(hObject, eventdata, handles)
% hObject    handle to list_features (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: contents = cellstr(get(hObject,'String')) returns list_features contents as cell array
%        contents{get(hObject,'Value')} returns selected item from list_features
update_pop_features(handles);
update_feature_fields(handles);

function mret = validate_feature_list(handles)
mret = isfield(handles,'feature_list') && ~isempty(handles.feature_list);



function update_feature_fields(handles)
val = get_feature_list_val(handles);
val = ift(isempty(val),1,val);
if(validate_feature_list(handles))
    flist = get_feature_list(handles);
    feature = flist(val);
    if(feature.use_cross_validation)
        if(isempty(feature.cross_validation_rate))
            [handles, feature]= set_feature_attribute_value(handles,val,'cross_validation_rate',0.1);
        end
        set(handles.txt_cross_val,'String',feature.cross_validation_rate);
        set(handles.lbl_cross_val,'Visible','on');
        set(handles.txt_cross_val,'Visible','on');
        
    else
        set(handles.lbl_cross_val,'Visible','off');
        set(handles.txt_cross_val,'Visible','off');
    end
    
    set(handles.chck_feature_processed,'Val',feature.processed);
    
    if(~isempty(feature.parameter_name))
        
        
        if(isempty(feature.parameter_value))
            [handles, feature]= set_feature_attribute_value(handles,val,'parameter_value',10);
        end
        set(handles.lbl_feature_parameter,'String',feature.parameter_name);
        set(handles.txt_feature_parameter,'String',feature.parameter_value);
        set(handles.txt_feature_parameter,'Visible','on');
        set(handles.lbl_feature_parameter,'Visible','on');
    else
        set(handles.lbl_feature_parameter,'Visible','off');
        set(handles.txt_feature_parameter,'Visible','off');
    end
    
    if(feature.use_feature_selection)
        set(handles.pnl_feature_selection,'Visible','on');
        if(~isempty(feature.feature_selection_function))
            set(handles.txt_cut_line_parameter,'String',feature.feature_selection_function.cut_line);
            [~,hash] = best_peaks_selection_set;
            f = hash(feature.feature_selection_function.function_name);
            if(~isempty(f.idx) && f.idx>0)
                set(handles.pop_best_peaks_selection,'Val',f.idx);
            end
        end
        
    else
        set(handles.pnl_feature_selection,'Visible','off');
    end
    if(feature.use_cicles)
        set(handles.lbl_feature_cicles,'Visible','on');
        set(handles.txt_feature_cicles,'Visible','on');
        if(isempty(feature.cicles))
            [handles, feature]= set_feature_attribute_value(handles,val,'cicles',10);
        end
        set(handles.txt_feature_cicles,'String',feature.cicles);
    else
        set(handles.lbl_feature_cicles,'Visible','off');
        set(handles.txt_feature_cicles,'Visible','off');
    end
    if(~isempty(feature.tr))
        set(handles.txt_train_correlation,'String',num2str(mean(abs(feature.tr.strg))))
    else
        set(handles.txt_train_correlation,'String','');
    end
    if(~isempty(feature.ts))
        set(handles.txt_test_correlation,'String',num2str(mean(abs(feature.ts.strg))))
    else
        set(handles.txt_test_correlation,'String','');
    end
end

function [handles, feature] = set_feature_attribute_value(handles,feature_pos,field,value)
feature = get_feature_on_list(handles,feature_pos);
feature = setfield(feature,field,value);
handles = save_feature(handles,feature,feature_pos);

function [handles, feature] = set_feature_selection_value(handles,feature_pos,field,value)
feature = get_feature_on_list(handles,feature_pos);
feature.feature_selection_function = setfield(feature.feature_selection_function,field,value);
handles = save_feature(handles,feature,feature_pos);


function feature = get_feature_on_list(handles,val)
flist = get_feature_list(handles);
feature = [];
if(isempty(flist))
    msgbox('Internal error: feature list is empty. Contact the system developer to more information.');
elseif (length(flist)<val)
    msgbox('Internal error: selected index is out of bounds of feature list. Contact the system developer.');
else
    feature = flist(val);
end


% --- Executes during object creation, after setting all properties.
function list_features_CreateFcn(hObject, eventdata, handles)
% hObject    handle to list_features (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btn_add_feature.
function btn_add_feature_Callback(hObject, eventdata, handles)
% hObject    handle to btn_add_feature (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[~,str] = get_pop_feature_val(handles);
[~, hash] = feature_set(handles);
try 
    
    feature = hash(str);
    feature.id = get_next_feature_id(handles,true);
    if(strcmp(feature.fname,'Fr. Watch Point Intensities')  || strcmp(feature.fname,'Fr. Watch Point M/Z'))
        cval = get_feature_list_val(handles);
        cfeat = handles.feature_list(cval);
        feature.reproces_feature_id = cfeat.id;
    elseif(strcmp(feature.fname,'Combine features'))
        feature.reproces_feature_id = 'all';
    end
    try
        handles = fn_add_feature(handles,feature);
    catch e 
        if(isempty(handles.features_list))
            handles.features_list = [];
            handles = fn_add_feature(handles,feature);
        else
            log(handles,['add feature error: ' e.message ]);
        end
        
        
    end
catch e
    log(handles,['internal error feature not found on hash: ' e.message]);
end
update_pop_features(handles);
update_feature_fields(handles);
set_best_peaks_selection_fields(handles)




function id = get_next_feature_id(handles,count)
if(~isfield(handles,'next_fid'))
    id = 1;
else
    id = handles.next_fid;
end
handles.next_fid = id + (1*count);
guidata(handles.list_features,handles);
    
function [flist, handles] = get_feature_list(handles)
if(~isfield(handles,'feature_list'))
    handles.feature_list = [];
    guidata(handles.list_features,handles);
end
flist = handles.feature_list;
if(isempty(flist))
    flist = [];
end


function handles = fn_add_feature(handles,feature)
[flist,handles] = get_feature_list(handles);
handles.feature_list = [flist feature];
guidata(handles.list_features,handles);
update_features_name_list(handles);
% set(handles.list_features,'Val',length(handles.feature_list));
update_feature_fields(handles);

function handles = save_feature(handles,feature,val)
feat = get_feature_list(handles);
feat(val) = feature;
handles.feature_list = feat;
guidata(handles.list_features,handles);

function update_features_name_list(handles)
fnames = {};
for i = handles.feature_list;
    fnames = [fnames; i.fname];
end
set(handles.list_features,'String',fnames);

function fn_rm_feature(handles,idx)
if(validate_feature_list(handles))
    handles.feature_list(idx) = [];
    set(handles.list_features,'Val',max(1,idx-1));
    guidata(handles.list_features,handles);
    update_features_name_list(handles);
end



function [val, str] = get_pop_feature_val(handles)
val = get(handles.pop_features,'Value');
all = get(handles.pop_features,'String');
str = all{val};


% --- Executes on button press in btn_rm_feature.
function btn_rm_feature_Callback(hObject, eventdata, handles)
% hObject    handle to btn_rm_feature (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = get_feature_list_val(handles);
fn_rm_feature(handles,val);
update_pop_features(handles);
update_feature_fields(handles);

% --- Executes on button press in btn_save_features.
function btn_save_features_Callback(~, ~, handles)
% hObject    handle to btn_save_features (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
fn_save_features(handles);


    

% --- Executes on selection change in pop_features.
function pop_features_Callback(hObject, ~, ~)
% hObject    handle to pop_features (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pop_features contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pop_features


% --- Executes during object creation, after setting all properties.
function pop_features_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pop_features (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

fset = feature_set;
str = {};
for i = fset(1:7)
    str = [str; i.fname];
end
set(hObject,'String',str);


function update_pop_features(handles)
features = feature_set(handles);
fnames = cell(7,1);

for i = 1:7
    fnames{i} = features(i).fname;
end
flist = get_feature_list(handles);
if(~isempty(get_feature_list_val(handles)) && ~isempty(flist))
    extra = flist(get_feature_list_val(handles)).reprocess;
    
    for i = extra
        fnames = [features(i).fname; fnames];
    end
    fnames(cellfun(@(x) isempty(x),fnames)) = [];
    
    set(handles.pop_features,'String',fnames);
    set(handles.pop_features,'Val',1);
end

function val = get_feature_list_val(handles)
val = get(handles.list_features,'Val');


function [features, hash, keys]= feature_set(handles)
bfs = best_peaks_selection_set;
currfeature = [];
if(nargin>0)
    currfeature = get_current_feature(handles);
end

features(1) = def_ui_feature_structure;
features(1).fname = 'Best Peaks Selection Feature';
features(1).reprocess = 10;
features(1).processed = false;
features(1).use_feature_selection = true;
features(1).use_cicles = false;
features(1).use_cross_validation = false;
features(1).feature_selection_function = bfs(1);
features(1).function = ...
    @(handles,feature)fn_best_peaks_selection_feature(...
        get_tr_selector(handles),...
        feature,...
        handles.w_data ...
    );

features(2) = def_ui_feature_structure;
features(2).fname = 'Watch Points';
features(2).reprocess = [8 9 10];
features(2).use_feature_selection = true;
features(2).use_cicles = true;
features(2).feature_selection_function = bfs(1);
features(2).use_cross_validation = true;
features(2).function = @(handles,feature)...
    ga_watch_points(...
        get_tr_selector(handles),...
        feature.cicles,...
        feature.feature_selection_function.function(...
            get_tr_selector(handles),...
            feature.feature_selection_function.cut_line,...
            handles.w_data... %biomarker
        ),...
        handles.w_data,...
        feature.cross_validation_rate,...
        feature.background...
    );



features(3) = def_ui_feature_structure;
features(3).fname = 'Fr all intensities';
features(3).reprocess = [10];
features(3).parameter_name = 'Waves:';
features(3).use_feature_selection = false;
features(3).use_cicles = true;
features(3).use_cross_validation = true;
features(3).function = @(handles,feature)...
    ga_fr_all_intensities(...
        get_tr_selector(handles),...
        feature.cicles,...
        feature.parameter_value, ... %biomarker
        handles.w_data,...
        feature.cross_validation_rate,...
        feature.background...
    );
features(4) = def_ui_feature_structure;
features(4).fname = 'Fr. Selected Intensity';
features(4).reprocess = [10];
features(4).parameter_name = 'Waves:';
features(4).use_feature_selection = false;
features(4).use_cicles = true;
features(4).use_cross_validation = true;
features(4).function = @(handles,feature)...
    ga_fr_selected_intensities(...
        get_tr_selector(handles),...
        feature.cicles,...
        feature.parameter_value, ...
        handles.w_data,...
        feature.cross_validation_rate,...
        feature.background...
    );

features(5) = def_ui_feature_structure;
features(5).fname = 'Fr. Selected M/Z';
features(5).reprocess = [10];
features(5).parameter_name = 'Waves:';
features(5).use_feature_selection = false;
features(5).use_cicles = true;
features(5).use_cross_validation = true;
features(5).function = @(handles,feature)...
    ga_fr_selected_x(...
        get_tr_selector(handles),...
        feature.cicles,...
        feature.parameter_value, ...
        handles.w_data,...
        feature.cross_validation_rate,...
        feature.background...
    );

features(6) = def_ui_feature_structure;
features(6).fname = 'Fr. Best Peaks intensities';
features(6).reprocess = [10];
features(6).parameter_name = 'Waves:';
features(6).use_feature_selection = true;
features(6).use_cicles = true;
features(6).use_cross_validation = true;
features(6).function = ...
@(handles,feature)...
    ga_fr_biomarker_intensities( ...
        get_tr_selector(handles),...
        feature.cicles,...
        feature.parameter_value,...
        feature.feature_selection_function.function(...
            get_tr_selector(handles),...
            feature.feature_selection_function.cut_line,...
            handles.w_data... 
        ),...
        handles.w_data,...
        feature.cross_validation_rate,...
        feature.background...
    );


features(7) = def_ui_feature_structure;
features(7).fname = 'Fr. Best Peaks M/Z';
features(7).reprocess = [10];
features(7).parameter_name = 'Waves:';
features(7).use_feature_selection = true;
features(7).use_cicles = true;
features(7).use_cross_validation = true;
features(7).function = ...
@(handles,feature)...
    ga_fr_biomarkers(...
        get_tr_selector(handles),...
        feature.cicles,...
        feature.parameter_value,...
        feature.feature_selection_function.function(...
            get_tr_selector(handles),...
            feature.feature_selection_function.cut_line,...
            handles.w_data... 
        ), ...
        handles.w_data,...
        feature.cross_validation_rate,...
        feature.background...
    );


if(~isempty(currfeature))
    features(8) = def_ui_feature_structure;
    features(8).fname = 'Fr. Watch Point M/Z';
    features(8).reprocess = [10];
    features(8).parameter_name = 'Waves:';
    features(8).use_feature_selection = false;
    features(8).use_cross_validation = true;
    features(8).use_cicles = true;
    features(8).function = ...
        @(handles,feature)...
            ga_fr_watch(...
            get_ecospec(handles),...
            feature.cicles,...
            feature.parameter_value,...
            currfeature, ...
            feature.cross_validation_rate,...
            feature.background...
        );
    
    
    features(9) = def_ui_feature_structure;
    features(9).fname = 'Fr. Watch Point Intensities';
    features(9).reprocess = [10];
    features(9).parameter_name = 'Waves:';
    features(9).use_feature_selection = false;
    features(9).use_cross_validation = true;
    features(9).use_cicles = true;
    % features(9).function = @ga_fr_watch_ii(ECOSPEC,gen,sins,watchFit,xpop);
    
    features(9).function = ...
        @(handles,feature)...
        ga_fr_watch_ii(...
        get_ecospec(handles),...
        feature.cicles,...
        feature.parameter_value,...
        currfeature,...
        feature.background...
        );
    
    features(10) = def_ui_feature_structure;
    features(10).fname = 'Combine features';
    features(10).reprocess = [];
    features(10).use_feature_selection = false;
    features(10).use_cross_validation = true;
    features(10).use_cicles = true;
    % features(10).function = @ga_combined_features(ECOSPEC,nger,features);
    features(10).function = ...
        @(handles,feature)...
            ga_combined_features(...
                get_tr_selector(handles),...
                handles.w_data,...
                feature.cicles,...
                get_non_combined_features(handles), ...
                feature.cross_validation_rate,...
                feature.background...
        );
end

lf = length(features);

keys = cell(lf,1);

cf = cell(1,lf);
for i = 1:lf
    keys{i} = features(i).fname;
    features(i).processed = false;
    cf{i} = features(i);
    
end
hash = containers.Map(keys, cf);

function best = run_best_pks_select(feature)
try
ecospec = get_ecospec(handles);
catch e
    msgbox('There is a problem with core object, contacto the developer');
    throw(e);
end
try
feature_selection_data = feature.feature_selection_function;
cutline = feature_selection_data.cut_line;
catch e
    msgbox('There is no feature selection data, try to configure best peaks selection params.');
    throw(e);
end
try
w_data = handles.w_data;
catch e
    msgbox('There is no data to process, if you have selected sample data and the error persists contact the developer.');
    throw(e);
end
try
    best = feature.feature_selection_function.function(ecospec,cutline,w_data);
catch e
    msgbox('There is a problem during the best peaks selection execution, please contact the developer.');
    throw(e);
end

function feature = get_current_feature(handles)
val = get_feature_list_val(handles);
if(length(val)>1)
   val = val(1);
end
if(validate_feature_list(handles))
    feature = handles.feature_list(val);
else
    feature = [];
end

function features  = get_non_combined_features(handles)
features = [];
for feature = handles.feature_list
    if(~strcmp('Combine features',feature.fname))
        features = [features, feature];
    end
end




function [ mret ] = fn_best_peaks_selection_feature(tr_selector,feature,w_data)
%FN_BEST_PEAKS_SELECTION_FEATURE Summary of this function goes here
%   Detailed explanation goes here
disp('processing');

func = feature.feature_selection_function.function;
cut_line = feature.feature_selection_function.cut_line;
output_args = func(tr_selector,cut_line,w_data);
mret = fn_best_peaks_feature(tr_selector,output_args,w_data);



function transf = transform_function(data)
all = cell2mat(data.all);
transf = all(:,pks_idx);
    









        

% --- Executes on button press in btn_export_features.
function btn_export_features_Callback(hObject, eventdata, handles)
% hObject    handle to btn_export_features (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[filename, pathname] =  uiputfile('*.txt','Export Features','features.txt');

[wtr,wts] = make_wtrts(get_tr_selector(handles),get_feature_list(handles),handles.w_data);

if(0~=filename)
    save([pathname 'tr_' filename], 'wtr', '-ascii', '-double', '-tabs');
    save([pathname 'ts_' filename], 'wts', '-ascii', '-double', '-tabs');
end
log(handles,['Features exported to: ' pathname]);


function txt_train_correlation_Callback(hObject, eventdata, handles)
% hObject    handle to txt_train_correlation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_train_correlation as text
%        str2double(get(hObject,'String')) returns contents of txt_train_correlation as a double


% --- Executes during object creation, after setting all properties.
function txt_train_correlation_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_train_correlation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txt_test_correlation_Callback(hObject, eventdata, handles)
% hObject    handle to txt_test_correlation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_test_correlation as text
%        str2double(get(hObject,'String')) returns contents of txt_test_correlation as a double


% --- Executes during object creation, after setting all properties.
function txt_test_correlation_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_test_correlation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function pnl_machine_learning_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pnl_machine_learning (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


function txt_train_test_rate_Callback(hObject, eventdata, handles)
% hObject    handle to txt_train_test_rate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_train_test_rate as text
%        str2double(get(hObject,'String')) returns contents of txt_train_test_rate as a double
try
    value = str2double(get(hObject,'String'));
catch e
    log(handles, e.message);
    value = 0.8;
end

if(isfield(handles,'w_data'))
    
    handles.tr_selector = fn_percent_select_data(value,handles.w_data);
    guidata(hObject,handles);
    log(handles, 'train/test rate reset.');
else
    message = 'Try load or import data before use apply this configuration';
    msgbox(message);
    log(handles,message);
end


% --- Executes during object creation, after setting all properties.
function txt_train_test_rate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_train_test_rate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btn_save_all.
function btn_save_all_Callback(hObject, eventdata, handles)
% hObject    handle to btn_save_all (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
folder = uigetdir('.');

if(folder~=0)
    
    
    itens = 5;
    
    %     network
    H = waitbar(0,'Saving Workspace');
    try
        w_data = handles.w_data;
        save([folder '/wdata'], 'w_data','-v6');
        clear w_data;
    catch e
        log(handles,'could not save w_data');
    end
    waitbar(1/itens,H);
    try
        feature_list = fn_feature_cleaner(handles.feature_list);
        save([folder '/feature_list'],'feature_list','-v6');
        clear feature_list;
    catch e
        log(handles,'could not save feature list');
    end
    
    waitbar(2/itens,H);
    try
        [~,params] = update_pks_select_params(handles);
        save([folder '/params'],'params','-v6');
        clear params;
    catch e
        log(handles,'could not save Peaks Selection.');
    end
    waitbar(3/itens,H);
    try
        tr_selector = get_tr_selector(handles);
        save([folder '/tr_selector'], 'tr_selector','-v6');
        clear tr_selector;
    catch e
        log(handles,'could not save tr_selector');
    end
    
    waitbar(3/itens,H);
    try
        network = handles.train_structure;
        save([folder '/network'], 'network','-v6');
        clear network;
    catch e
        log(handles,'could not save the network');
    end
    
    waitbar(4/itens,H);
    
    log(handles,['workspace saved on: ' folder]);
    waitbar(1,H,'Done!');
end

% --- Executes on button press in btn_run_feature_extraction.
function btn_run_feature_extraction_Callback(hObject, eventdata, handles)
% hObject    handle to btn_run_feature_extraction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
selection = [];
if(get(handles.chck_run_continue,'Value'))
    selection = 1:length(handles.feature_list);
else
    selection = get_feature_list_val(handles);
end
features = handles.feature_list;
for i = selection
    set(handles.list_features,'Val',i);
    handles.feature_list(i) = run_feature(handles,features(i));
    guidata(hObject,handles);
end
update_feature_fields(handles);

function feature = run_feature(handles,feature)
    background = get(handles.ck_background,'Value');
    feature.background = background;
    nf = feature.function(handles,feature);
    feature = catstruct(feature,nf);
    feature.processed = true;
%     [(fields(catstruct(feature,nf))) (struct2cell(catstruct(feature,nf))), struct2cell(catstruct(def_ui_feature_structure,feature)), (struct2cell(catstruct(def_ui_feature_structure,nf)))]

% --- Executes on button press in chck_run_continue.
function chck_run_continue_Callback(hObject, eventdata, handles)
% hObject    handle to chck_run_continue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chck_run_continue


% --- Executes on button press in chck_cross_validation.
function chck_cross_validation_Callback(hObject, eventdata, handles)
% hObject    handle to chck_cross_validation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chck_cross_validation
val = get_feature_list_val(handles);
if(validate_feature_list(handles))
    feature = handles.feature_list(val);
    feature.use_cross_validation = get(handles.chck_cross_validation,'Val');
    handles.feature_list(val) = feature;
    guidata(handles.chck_cross_validation,handles);
end

% --- Executes on button press in btn_load_all.
function btn_load_all_Callback(hObject, eventdata, handles)
% hObject    handle to btn_load_all (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

  
folder = uigetdir('.');
cd(folder);
if(folder~=0)
   
    itens = 4;
    try
        H = waitbar(0,'loading files');
        try
            load([folder '/wdata']);
            [~,handles] = set_override_or_update_data(handles,w_data);
            list_w_data_Callback(hObject, eventdata, handles);
        catch e 
            log(handles,'w_data not existento on specified folder.');
        end
        clear w_data;
        
        try
            waitbar(1/itens,H);
            load([folder '/params']);
            handles = set_pks_select_params(handles,params);
        catch e 
            log(handles,'Params loading error.');
        end
        clear params
        
        waitbar(2/itens,H);
        try
            load([folder '/feature_list']);
            handles = set_feature_list(handles,feature_list);
        catch e 
            log(handles,'Feature List Loading Error.');
        end
        clear feature_list;
        
        waitbar(4/itens,H);
        try
            
            load([folder '/tr_selector']);
            get_tr_selector(handles)
            handles = set_tr_selector(handles,tr_selector);
        catch e 
            log(handles,'tr_selector loading error.');
        end
        clear tr_selector;
        waitbar(5/itens,H);
        
        try
            
            load([folder '/network']);
            get_tr_selector(handles)
            handles = set_neural_network(handles,network);
        catch e 
            log(handles,'tr_selector loading error.');
        end
        clear network;
        
        
        
% %         load([folder '/ECOSPEC']);
        
        
        
        
%         handles = set_ecospec(handles,ECOSPEC);

%         handles.w_data = workspace.w_data;
        
        
        waitbar(1,H,'Done!');
    catch e
        log(handles,e.message);
        msgbox('This file could not be readed. Make shure that it is the workspace file.');
    end
end

function handles = set_ecospec(handles,ecospec)
handles.ECOSPEC = ecospec;
guidata(handles.btn_load_all,handles);
        

function txt_feature_cicles_Callback(hObject, eventdata, handles)
% hObject    handle to txt_feature_cicles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_feature_cicles as text
%        str2double(get(hObject,'String')) returns contents of txt_feature_cicles as a double
val = get_feature_list_val(handles);
feature = handles.feature_list(val);
feature.cicles = str2double(get(hObject,'String'));
handles.feature_list(val) = feature;
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function txt_feature_cicles_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_feature_cicles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txt_feature_parameter_Callback(hObject, eventdata, handles)
% hObject    handle to txt_feature_parameter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_feature_parameter as text
%        str2double(get(hObject,'String')) returns contents of txt_feature_parameter as a double
val = get_feature_list_val(handles);
feature = handles.feature_list(val);
feature.parameter_value = str2double(get(hObject,'String'));
handles.feature_list(val) = feature;
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function txt_feature_parameter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_feature_parameter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txt_cut_line_parameter_Callback(hObject, eventdata, handles)
% hObject    handle to txt_cut_line_parameter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_cut_line_parameter as text
%        str2double(get(hObject,'String')) returns contents of txt_cut_line_parameter as a double
set_best_peaks_selection_fields(handles)


function set_best_peaks_selection_fields(handles)

cut_line = str2double(get(handles.txt_cut_line_parameter,'String'));
if(isempty(cut_line))
cut_line = 0.5;
end

val = get_feature_list_val(handles);



[~,ff] =  get_func_pop_feature_selection(handles);
handles = set_feature_attribute_value(handles,val,'feature_selection_function',ff);
handles = set_feature_selection_value(handles,val,'cut_line',cut_line);
func = ff.function;
if(validate_w_data(handles))
    
    selected = func(get_tr_selector(handles),cut_line,handles.w_data,handles.graph_preview);
    set(handles.txt_best_peaks_count,'String',['Bests: ' num2str(selected.peaks_count)]);
    plot_selected_peaks(handles,selected);
    
end
guidata(handles.txt_best_peaks_count,handles);
% tw = cell2mat(handles.w_data.all);
% ccr = zeros(size(tw,2));
% for i = 1:size(tw,2)
%     ccr(i,:) = corr(tw(:,i),tw);
% end


function plot_selected_peaks(handles,selection)

val = get_val_wdata_list(handles);
data = def_data_structure;
data.all = handles.w_data.all(val);
data.selected_mz = handles.w_data.selected_mz(val);
data.cut_off = handles.w_data.cut_off(val);

plot_peaks_selection_preview(data,handles.peaks_selection_preview);

hold(handles.peaks_selection_preview,'on')

curr_spec = handles.w_data.all{val(1)};
plot(handles.peaks_selection_preview,find(selection.selected_peaks),curr_spec(selection.selected_peaks),'go');

hold(handles.peaks_selection_preview,'off')


function val = get_val_pop_feature_selection(handles)
val = get(handles.pop_best_peaks_selection,'Val');



function [best_peaks_selection_function,best_peaks_selection_structure] = get_func_pop_feature_selection(handles)
[~,hash,keys] = best_peaks_selection_set;
best_peaks_selection_structure = hash(keys{get_val_pop_feature_selection(handles)});
best_peaks_selection_function = best_peaks_selection_structure.function;


function ECOSPEC = get_ecospec(handles)
if(~isfield(handles,'ECOSPEC') || isempty(handles.ECOSPEC))
    handles.ECOSPEC = peaksclass;
    if(validate_w_data(handles))
        handles.ECOSPEC.tr_selector = fn_percent_select_data(0.9,handles.w_data);
        log(handles,'train/test selection changed!');
    else
        message = 'Does not have data or the classes was not set';
        log(handles,message);
    end

    
   
    
end
if(validate_w_data(handles))
    handles.ECOSPEC.data = handles.w_data;
end
handles.ECOSPEC.plot_idx1 = handles.graph_preview;
handles.ECOSPEC.plot_idx2 = handles.peaks_selection_preview;
handles.ECOSPEC.plot_idx3 = handles.peaks_svd_preview;
handles.ECOSPEC.useplotfunc = true;
ECOSPEC = handles.ECOSPEC;

guidata(handles.txt_train_test_rate,handles);

function [tr_selector,handles]= get_tr_selector(handles)
    if(~isfield(handles,'tr_selector'))
        handles = set_tr_selector(handles,fn_percent_select_data(str2double(get(handles.txt_train_test_rate,'String')),handles.w_data));
    elseif(isfield(handles,'tr_selector') && isempty( handles.tr_selector))
        handles = set_tr_selector(handles,fn_percent_select_data(str2double(get(handles.txt_train_test_rate,'String')),handles.w_data));
    end
    tr_selector = handles.tr_selector;

function handles = set_tr_selector(handles,tr_selector)
    handles.tr_selector = tr_selector;
    guidata(handles.txt_train_test_rate,handles);

    
    
function [f, hash, keys] = best_peaks_selection_set()
f(1) = def_ui_best_feature_structure;
f(1).function_name = 'Correlation';
f(1).function = @find_biomarker_correlation_based;
f(1).idx = 1;

f(2) = def_ui_best_feature_structure;
f(2).function_name = 'Probability';
f(2).function = @find_biomarker_prob_based;
f(2).idx = 2;

% f(3).function_name = 'Linear Regression';
% f(3).function = @find_biomarker_regression;


lf=length(f);
keys = cell(lf,1);
cf = cell(lf,1);
for i = 1:length(f)
    keys{i} = f(i).function_name;
    cf{i} = f(i);
    
end
hash = containers.Map(keys, cf);
% f(3).function_name = 'Linear regression';





% --- Executes during object creation, after setting all properties.
function txt_cut_line_parameter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_cut_line_parameter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox8.
function checkbox8_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox8


% --- Executes on button press in checkbox9.
function checkbox9_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox9


% --- Executes on button press in checkbox10.
function checkbox10_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox10


% --- Executes on button press in pushbutton30.
function pushbutton30_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton30 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in btn_load_features.
function btn_load_features_Callback(hObject, eventdata, handles)
% hObject    handle to btn_load_features (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
fn_load_features(handles);

function fn_save_features(handles,pathname,wbarhandler)
if(validate_feature_list(handles))
    if(nargin<2 || isempty(pathname))
        [pathname] =  uigetdir('.');
    end
    if(nargin<3)
        wbarhandler = waitbar(0, 'saving');
    end
    if(0~=pathname)
        sfile = [pathname '/features'];
        feature_list = handles.feature_list;
        ok = mkdir(sfile);
        lf = length(feature_list);
        if(ok)
            for i = 1:lf
                features = feature_list(i);
                features.tr.w = [];
                features.ts.w = [];
                features.feat_corr = [];
                waitbar(i/lf,wbarhandler,['Saving: ' features.fname]);
                save([sfile '/' num2str(i)] , 'features','-v7.3');
                
            end
        end
        log(handles,'Features Saved');
    end
else
    log(handles,'No feature to save');
end


function fn_load_features(handles,path,wbarhandler)
if(nargin<2 || isempty(path))
    [path] = uigetdir('.');
end


if(path~=0)
    if(nargin<3)
        wbarhandler = waitbar(0,'loading features');
    end
    files = dir(path);
    lf = length(files);
    feature_list = [];
    for i = 1:lf
        if(~files(i).isdir & strfind(files(i).name,'.mat'))
            load([path '/' files(i).name])
            feature_list = [feature_list features];
            clear features;
            waitbar(i/lf,wbarhandler);
        end
    end
    try
            set_feature_list(handles,feature_list);
        catch e
            log(handles,e.message);
            msgbox('This file could not be imported!');
        end
end

function handles = set_feature_list(handles,feature_list)
handles.feature_list = feature_list;
update_features_name_list(handles);
update_feature_fields(handles);
guidata(handles.btn_load_data,handles)



% --- Executes on button press in btn_dwn_feature_list.
function btn_dwn_feature_list_Callback(hObject, eventdata, handles)
% hObject    handle to btn_dwn_feature_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = get_feature_list_val(handles);
if(val<length(handles.feature_list))
    tfeat = handles.feature_list([val val+1]);
    handles.feature_list(val+1) = tfeat(1);
    handles.feature_list(val) = tfeat(2);
    set(handles.list_features,'Val',val+1)
    guidata(handles.list_features,handles);
end
update_features_name_list(handles)

% --- Executes on button press in btn_up_feature_list.
function btn_up_feature_list_Callback(hObject, eventdata, handles)
% hObject    handle to btn_up_feature_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = get_feature_list_val(handles);
if(val>1)
    tfeat = handles.feature_list([val val-1]);
    handles.feature_list(val-1) = tfeat(1);
    handles.feature_list(val) = tfeat(2);
    set(handles.list_features,'Val',val-1)
    guidata(handles.list_features,handles);
end
update_features_name_list(handles)


% --- Executes on button press in chck_feature_processed.
function chck_feature_processed_Callback(hObject, eventdata, handles)
% hObject    handle to chck_feature_processed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chck_feature_processed


% --- Executes on button press in checkbox12.
function checkbox12_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox12



function txt_cross_val_Callback(hObject, eventdata, handles)
% hObject    handle to txt_cross_val (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_cross_val as text
%        str2double(get(hObject,'String')) returns contents of txt_cross_val as a double
set_feature_attribute_value(handles,get_feature_list_val(handles),'cross_validation_rate',str2double(get(hObject,'String')));

% handles.feature_list(val) = feature;
% guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function txt_cross_val_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_cross_val (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in pop_best_peaks_selection.
function pop_best_peaks_selection_Callback(hObject, eventdata, handles)
% hObject    handle to pop_best_peaks_selection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pop_best_peaks_selection contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pop_best_peaks_selection
set_best_peaks_selection_fields(handles)

% --- Executes during object creation, after setting all properties.
function pop_best_peaks_selection_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pop_best_peaks_selection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
[~,~,keys] = best_peaks_selection_set;
set(hObject,'String',keys);



function txt_best_peaks_count_Callback(hObject, eventdata, handles)
% hObject    handle to txt_best_peaks_count (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_best_peaks_count as text
%        str2double(get(hObject,'String')) returns contents of txt_best_peaks_count as a double


% --- Executes during object creation, after setting all properties.
function txt_best_peaks_count_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_best_peaks_count (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in pop_align_mode.
function pop_align_mode_Callback(hObject, eventdata, handles)
% hObject    handle to pop_align_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pop_align_mode contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pop_align_mode


% --- Executes during object creation, after setting all properties.
function pop_align_mode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pop_align_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in pop_align_fb.
function pop_align_fb_Callback(hObject, eventdata, handles)
% hObject    handle to pop_align_fb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pop_align_fb contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pop_align_fb


% --- Executes during object creation, after setting all properties.
function pop_align_fb_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pop_align_fb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btn_w2weka.
function btn_w2weka_Callback(hObject, eventdata, handles)
% hObject    handle to btn_w2weka (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[filename, pathname] =  uiputfile('*.arff','Export Features','features');

[wtr,wts] = make_wtrts(get_tr_selector(handles),get_feature_list(handles),handles.w_data);

if(0~=filename)
    w2weka(wtr, [pathname 'tr_' filename]);
    w2weka(wts, [pathname 'ts_' filename]);
end
log(handles,['Features exported to: ' pathname]);


% --- Executes during object creation, after setting all properties.
function axes7_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes7
axes(hObject)
imshow('logoP.png');


% --- Executes on button press in btn_sort.
function btn_sort_Callback(hObject, eventdata, handles)
% hObject    handle to btn_sort (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
class = [handles.w_data.class{:}];
[~,sorted] = sort(class); 
handles.w_data = fn_resample_data(handles.w_data,sorted);
guidata(handles.btn_sort,handles);
update_list_string_files(handles);


% --- Executes on key press with focus on list_w_data and none of its controls.
function list_w_data_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to list_w_data (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
isnumeric(eventdata.Character)



function txt_class_edit_Callback(hObject, eventdata, handles)
% hObject    handle to txt_class_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_class_edit as text
%        str2double(get(hObject,'String')) returns contents of txt_class_edit as a double
val = get_val_wdata_list(handles);
cval = str2num(get(hObject,'String'));

try
    if(length(cval)>1)
        button = questdlg(['The value ' num2str(cval) 'can not me accepted!'],'Class Error',['Use: ' num2str(cval(1)) ' instead'],'cancel',[]);
        if(strcmp(button,'cancel'))
            ex = MException(1,'Wrong Class Selection: Class must be an integer value major than one')
            throw(ex);
        else
            update_sample_info(handles,cval(1));
            cval = cval(1);
        end
    elseif(isempty(cval))
        list_w_data_Callback(hObject, eventdata, handles);
    end
    handles.w_data.class(val',1)= repmat({cval},length(val),1);
    guidata(hObject,handles);
    log(handles,[num2str(val) ' - class changed!']);
    
catch e
    log(handles,'Class change cancelled.')
end

% --- Executes during object creation, after setting all properties.
function txt_class_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_class_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function btn_allign_spctr_CreateFcn(hObject, eventdata, handles)
% hObject    handle to btn_allign_spctr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in ck_background.
function ck_background_Callback(hObject, eventdata, handles)
% hObject    handle to ck_background (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ck_background
 
