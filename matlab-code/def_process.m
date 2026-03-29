%clear

load('WmfOC.mat')

clear peaks
clear net

%data = WmfOC(end,[1,4]);
%[B,S] = waveletSmoothAndBaselineCorrect(WmfOC{1,1},6,2500,10);

params = def_mm_selection_params;
params.alocation = 0.2;
params.pwd = 1.1;
params.fuzzyWindow = 50;
params.range = [1 15000];
params.show = 1;

peaks = peaksclass();
peaks.data = pks_select_mm(peaks,WmfOC(:,[1,4]),params);
peaks.peaks_dfuzzy = 10;
peaks.tr_selector = fn_percent_select_data(peaks,0.8);
peaks.useplotfunc = true;





%%
%%
[allyfeaturetrts, xpopall] = peaks.gaFRAllIntensities(10,10,[]);
[selectedyfeaturetrts, xpopselectedy] = peaks.gaFRSelectedIntensities(10,10,[]);
%%
% b6 = peaks.findBiomarkersDiffProb(0.6);
% b5 = peaks.findBiomarkersDiffProb(0.5);
% b4 = peaks.findBiomarkersDiffProb(0.4);

p3 = find_biomarkers_prob_based(peaks,0.3);
p2 = find_biomarkers_prob_based(peaks,0.2);
p1 = find_biomarkers_prob_based(peaks,0.1);

c1 = find_biobarker_correlation_based(peaks,0.1);
c2 = find_biobarker_correlation_based(peaks,0.2);
c3 = find_biobarker_correlation_based(peaks,0.3);
c4 = find_biobarker_correlation_based(peaks,0.4);
c5 = find_biobarker_correlation_based(peaks,0.5);

%%
% [fwp1, xpopp1] = peaks.gaWatchPoints(20,p1,[]);
% [fwp2, xpopp2] = peaks.gaWatchPoints(20,p2,[]);
% [fwc1, xpopwatch1] = peaks.gaWatchPoints(20,c1,[]);
% [fwc2, xpopwatch2] = peaks.gaWatchPoints(20,c2,[]);
[fwc3, xpopwatch3] = peaks.gaWatchPoints(20,c3,[]);
% [fwc4, xpopwatch4] = peaks.gaWatchPoints(20,c4,[]);
%[fwc5, xpopwatch5] = peaks.gaWatchPoints(5,c5,[]);
%%
[fwatchP03, xpopwatch3] = peaks.gaWatchPoints(10,p3,[]);
% [fwatchP04, xpopwatch4] = peaks.gaWatchPoints(10,b4,[]);
% [fwatchP05, xpopwatch5] = peaks.gaWatchPoints(10,b5,[]);
% [fwatchP06, xpopwatch6] = peaks.gaWatchPoints(10,b6,[]);

% [frp1, xpopbioselectedxb1] = peaks.gaFRBiomarkers(10,10,p1,[]);
% [frp2, xpopbioselectedxb2] = peaks.gaFRBiomarkers(10,10,p2,[]);
% 
% [frc1, xpopbioselectedxc1] = peaks.gaFRBiomarkers(10,10,c1,[]);
% [frc2, xpopbioselectedxc2] = peaks.gaFRBiomarkers(10,10,c2,[]);
[frc3, xpopbioselectedxc3] = peaks.gaFRBiomarkers(10,10,c3,[]);
% [frc4, xpopbioselectedxc4] = peaks.gaFRBiomarkers(10,10,c4,[]);
%[frc5, xpopbioselectedxc5] = peaks.gaFRBiomarkers(100,10,c5,[]);

%
% [fbiomarkerxfeaturetrts03, xpopbioselectedx3] = peaks.gaFRBiomarkers(100,10,b3,[]);
% [fbiomarkerxfeaturetrts04, xpopbioselectedx4] = peaks.gaFRBiomarkers(100,10,b4,[]);
% [fbiomarkerxfeaturetrts05, xpopbioselectedx5] = peaks.gaFRBiomarkers(100,10,b5,[]);
% [fbiomarkerxfeaturetrts06, xpopbioselectedx6] = peaks.gaFRBiomarkers(100,10,b6,[]);
%%
[fselectedxfeaturetrts, bxpopselectedx] = peaks.gaFRselectedX(10,10,[]);
%% [watchfrfeatures, waxpopselectedx] = peaks.gaFRWatch(10,10,[]);
% [fwP1, xpopselectedx1] = peaks.gaFRWatch(100,15,fwp1,[]);
% [fwP2, xpopselectedx2] = peaks.gaFRWatch(100,15,fwp2,[]);

% [fwC1, xpopselectedx1] = peaks.gaFRWatch(100,15,fwc1,[]);
% [fwC2, xpopselectedx2] = peaks.gaFRWatch(100,15,fwc2,[]);
[fwC3, xpopselectedx1] = peaks.gaFRWatch(20,15,fwc3,[]);
% [fwC4, xpopselectedx2] = peaks.gaFRWatch(100,15,fwc2,[]);
% [fwatchfrfeatures3, xpopselectedx3] = peaks.gaFRWatch(100,10,fwatchP03,[]);
% [fwatchfrfeatures4, xpopselectedx4] = peaks.gaFRWatch(100,10,fwatchP04,[]);
% [fwatchfrfeatures5, xpopselectedx5] = peaks.gaFRWatch(100,10,fwatchP05,[]);
% [fwatchfrfeatures6, xpopselectedx6] = peaks.gaFRWatch(100,10,fwatchP06,[]);

%%

% [combfeat] = peaks.combine_features(50,[fselectedxfeaturetrts, fwatchfrfeatures6, fwatchfrfeatures5, fwatchfrfeatures1, fwatchfrfeatures2, fwatchfrfeatures3, fwatchfrfeatures4, fwatchP06,fwatchP05, fwatchP04, fwatchP03, fwatchP02, fwatchP01, fbiomarkerxfeaturetrts06, fbiomarkerxfeaturetrts05, fbiomarkerxfeaturetrts04, fbiomarkerxfeaturetrts03, fbiomarkerxfeaturetrts02, fbiomarkerxfeaturetrts01]);
[combfeat] = peaks.combine_features(100,[fwc3, fwC3]);



[train_structure] = peaks.train(combfeat);
[wtr,wts] = peaks.buildWtrts([]);
w2weka(wts,'wts');
w2weka(wtr,'wtr');
%%
result = peaks.test(train_structure,peaks.pks_select_mm(WmfOC([1],1),params))
result = peaks.test(train_structure,peaks.pks_select_mm(WmfOC([1,216],1),params))
result = peaks.test(train_structure,peaks.pks_select_mm(WmfOC([216],1),params))
%%
tic
while(train_structure.ts.certos<95)
    [fwatchP05, xpopwatch5] = peaks.gaWatchPoints(5,b5,xpopwatch5);
    [fwatchP04, xpopwatch4] = peaks.gaWatchPoints(5,b4,xpopwatch4);
    [fwatchP03, xpopwatch3] = peaks.gaWatchPoints(5,p3,xpopwatch3);
    [fwatchP02, xpopwatch2] = peaks.gaWatchPoints(5,p2,xpopwatch2);
    [fwatchP01, xpopwatch1] = peaks.gaWatchPoints(5,p1,xpopwatch1);
    
    [fbiomarkerxfeaturetrts01, xpopbioselectedx1] = peaks.gaFRBiomarkers(5,10,p1,xpopbioselectedx1);
    [fbiomarkerxfeaturetrts02, xpopbioselectedx2] = peaks.gaFRBiomarkers(5,10,p2,xpopbioselectedx2);
    [fbiomarkerxfeaturetrts03, xpopbioselectedx3] = peaks.gaFRBiomarkers(5,10,p3,xpopbioselectedx3);
    [fbiomarkerxfeaturetrts04, xpopbioselectedx4] = peaks.gaFRBiomarkers(5,10,b4,xpopbioselectedx4);
    [fbiomarkerxfeaturetrts05, xpopbioselectedx5] = peaks.gaFRBiomarkers(5,10,b5,xpopbioselectedx5);
    
    [fselectedxfeaturetrts, bxpopselectedx] = peaks.gaFRselectedX(5,10,bxpopselectedx);
    %[watchfrfeatures, waxpopselectedx] = peaks.gaFRWatch(10,10,[]);
    [fwatchfrfeaturesP1, xpopselectedx1] = peaks.gaFRWatch(5,10,fwatchP01,xpopselectedx1);
    [fwatchfrfeaturesP2, xpopselectedx2] = peaks.gaFRWatch(5,10,fwatchP02,xpopselectedx2);
    [fwatchfrfeatures3, xpopselectedx3] = peaks.gaFRWatch(5,10,fwatchP03,xpopselectedx3);
    [fwatchfrfeatures4, xpopselectedx4] = peaks.gaFRWatch(5,10,fwatchP04,xpopselectedx4);
    [fwatchfrfeatures5, xpopselectedx5] = peaks.gaFRWatch(5,10,fwatchP05,xpopselectedx5);
    
    
    
    [combfeat] = peaks.combine_features(50,[fwatchfrfeatures5, fwatchfrfeaturesP1, fwatchfrfeaturesP2, fwatchfrfeatures3, fwatchfrfeatures4, fwatchP05, fwatchP04, fwatchP03, fwatchP02, fwatchP01, fbiomarkerxfeaturetrts05, fbiomarkerxfeaturetrts04, fbiomarkerxfeaturetrts03, fbiomarkerxfeaturetrts02, fbiomarkerxfeaturetrts01]);
    
    
    [train_structure] = peaks.train(combfeat);
end
%%

[wtr, wts] = peaks.buildWtrts([selectedyfeaturetrts, watchPtrts, fselectedxfeaturetrts, biomarkerxfeaturetrts, allyfeaturetrts,combfeat]);
%%



params.alocation = 0
params.pwd = 1.7
params.fuzzyWindow = 100;
peaks.data = peaks.pks_select_mm(WmfOC(:,[1,4]),params);

idx = achapicos(WmfOC{1,1});
y = peaks.data.all{:};
ct = peaks.data.cut_off{:};
figure
hold on
plot(y)
plot(ct, 'm')


nidx = idx(y(idx)>ct(idx))
plot(idx,y(idx),'ro')
plot(nidx,y(nidx),'go')

%%
for i = 1:length(combfeat.transform.features)
    combfeat.transform.features(i).tr = combfeat.transform.features(i).alltr;
end
