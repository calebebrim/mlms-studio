function [struct, vector,position ] = find_biomarker_prob_based(tr_selector,cut_line,w_data,plot_idx)
%findBiomarkersDifProb return a simple vector with probability of a peak happen
%   input objective is a matrix with dimension NxM and comparison should be
%   a matrix with dimension JxM
%
%   Both data should have the same format.
%   Each line represent a spectrum.
%   Each line is a boolean vector (with zeros and ones) representing peak
%   existence.
%   mret is a vector with probabilities P(i) = NOi/N;


if(iscell(w_data.class))
    cltr = cell2mat(w_data.class(tr_selector));
else
    cltr = w_data.class(tr_selector);
end

ucl = unique(cltr);
lcl = length(ucl);
ldata = length(w_data.mz{1});

for i = 1:lcl
    tr = w_data.idx(tr_selector);
    
    target = cell2mat(tr(cltr==ucl(i)));
    compare = cell2mat(tr(cltr~=ucl(i)));
    
    star = sum(target,1);
    scomp = sum(compare,1);
    
    ntar = size(target);
    ncomp = size(compare);
    for j = 1:ntar(2)
        %pi(j) = (star(j)/ntar(1))-(scomp(j)/ncomp(1));
        pi(i,j) = (star(j)/(ntar(1)+ncomp(1)))-(scomp(j)/(ntar(1)+ncomp(1)));
    end
    
%     vector = vector | (abs(pi(i,:))>cut_line);
end
% pi(pi<0) = 0;
vector = abs(max(pi,[],1))>=cut_line;
if(nargout>1)
    position = find(vector);
end

struct = def_biomarker_structure;
struct.selected_peaks = vector;
struct.peaks_count = sum(vector);
struct.values = pi;
struct.all_peaks_count = sum(sum(pi>0));
struct.cut_line = cut_line;
struct.description = (disp_biomarker_info(struct));
disp(struct.description);
if(nargin>3)
    plot_correlation_cutline(pi,cut_line,plot_idx);
end

end