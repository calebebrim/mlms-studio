function [struct,speaks, correlation] = find_biomarker_correlation_based(tr_selector,cut_line,w_data,plot_idx)
if(nargin<2)
    cut_line = 0;
end
selector = tr_selector;


cl = cell2mat(w_data.class(selector));
if(size(cl,1)<size(cl,2))
    cl = cl'
end
idxs = w_data.idx(selector);
idxs = double(cell2mat(idxs));
ccr = corr(idxs,cl);
ccr(isnan(ccr)) = 0;

speaks = (abs(ccr)>cut_line)';
correlation = ccr(speaks)';

struct = def_biomarker_structure;
struct.peaks_count = sum(speaks);
struct.selected_peaks = speaks;
struct.values = ccr;
struct.all_peaks_count = sum(struct.values>0);
struct.cut_line = cut_line;

struct.description = (disp_biomarker_info(struct));
if(nargin>3)
    plot_correlation_cutline(ccr,cut_line,plot_idx);
end
disp(struct.description);
end