function plot_peaks_selection_preview(data,axis_handler)

axes(axis_handler);


all = cell2mat(data.all);
plot(max(all,[],1)','b')
hold('on');
plot(data.cut_off{1},'r')
%     plot(handles.graph_preview,data.cut_off{1},'r')
uidx = unique([data.selected_mz{:}]);
mx = max(all(:,uidx),[],1);
plot(uidx,mx,'ro')
hold('off')