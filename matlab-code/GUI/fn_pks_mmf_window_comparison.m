function fn_pks_mmf_window_comparison(w_data,varargin)
%FN_PKS_MMF_COMPARISON Compare the window variation in subplots
%   Usage: 
%    fn_pks_mmf_window_comparison(w_data,[window1 window2 ...]);
%
%    fn_pks_mmf_window_comparison(w_data,[10 50 100]);
%
%   where w_data is defined by: DEF_DATA_STRUCTURE
%
%   
%   See also: DEF_DATA_STRUCTURE, PLOT_PEAKS_SELECTION_PREVIEW,
%   FN_PKS_SELECT_MM
%
%   by: calebebrim@gmail.com

figure;
w_data.params = def_mm_selection_params;
w_data.params.pwd = 1;
w_data.params.allocation = 0.05;
for i = 1:nargin-1
    subplot(nargin-1,1,i);
    
    
    tw_data = w_data;
    tw_data.params.fuzzyWindow = varargin{i};
    tw_data.all = cellfun(@(x) fn_norm_max_min(x),tw_data.all,'UniformOutPut',false);
    plot_peaks_selection_preview(fn_pks_select_mm(tw_data,vect2index(length(tw_data.all),1)));
    title(['Fuzzy Moving Average Window: ' num2str(varargin{i})]);

end
xlabel(['x = ( x = M/Z | 1 < x < ' num2str(w_data.mz{1}(end)) ' )']);
ylabel('Normalised Intensity');
legend('Spectrum','FMA Cutline');
end

