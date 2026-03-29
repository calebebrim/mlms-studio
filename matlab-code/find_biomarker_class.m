function [mret, vector] = find_biomarkers_class(obj,prob)
%findBiomarkersDifProb return a simple vector with probability of a peak happen
%   input objective is a matrix with dimension NxM and comparison should be
%   a matrix with dimension JxM
%
%   Both data should have the same format.
%   Each line represent a spectrum.
%   Each line is a boolean vector (with zeros and ones) representing peak
%   existence.
%   mret is a vector with probabilities P(i) = NOi/N;

if(nargin < 2)
    prob = obj.biomarkers_probability;
end
cltr = obj.selectLabels(obj.tr_selector);
tr = obj.data.idx(obj.tr_selector);
ucl = unique(cltr);
lnc = length(ucl);
vector = cell(lnc,1);
position = cell(lnc,1);
ntar = size([tr{1}]);
mret = zeros(1,ntar(2));
for c = 1:lnc
    target = cell2mat(tr(cltr==ucl(c)));
    star = sum(target,1);
    
    ntar = size(target);
    pi = zeros(1,ntar(2));
    for i = 1:ntar(2)
        pi(i) = (star(i)/ntar(1));
    end
    vector(c,1) = {abs(pi)>prob};
    vector(c,2) = {find(vector{c})};
    mret = sum([mret ;vector{c,1}],1);
    
end
mret = mret>0;
end