function [mret , pearson , spearman]  = fn_fcorr(arg, fc)
%nmx = length(fc(1,:))-1;
mc = [fn_fcol(arg,fc) fc(:,end)];
spearman = corr(mc,'type','Spearman'); %O Paulo A. falou que ? mais apropriado que Pearson

pearson = corr(mc,'type','Pearson');
%mr = corr(mc,'type','Kendall');
%[mr1 mr2]
%mret = -sqrt(abs(mr1(1,2))*abs(mr2(1,2)));
%mret = -(abs(mr2(1,2)));
mret = -(abs(pearson(1,2)));
end