function [ recall, precision , accuracy, jaccard] =  recall_precision_acurracy_jaccard( confusion_matrix )
%[recall,precision,accuracy,cjaccard] = ...
% recall_precision_acurracy_cjaccard(confusion_matrix);
% 
% confusion_matrix = NxN;
%=======================================================
% Developed using by reference: 
% EVALUATION: FROM PRECISION, RECALL AND F-MEASURE TO ROC,  INFORMEDNESS, MARKEDNESS & CORRELATION
% http://dspace2.flinders.edu.au/xmlui/bitstream/handle/2328/27165/Powers%20Evaluation.pdf?sequence=1
% 
p = sum(confusion_matrix,2);
r = sum(confusion_matrix,1);
nclass = size(confusion_matrix,2);
recall      = zeros(nclass,1); %sensivity
precision   = zeros(nclass,1); %confidence
% specificity = zeros(nclass,1); %inverse_recall = recall(~i)
jaccard     = zeros(nclass,1);
accuracy    = sum(confusion_matrix(eye(nclass)==1))/sum(sum(confusion_matrix));

for i = 1:nclass
    recall(i)       = confusion_matrix(i,i)/r(i);
    precision(i)    = confusion_matrix(i,i)/p(i);
%     specificity(i)  = confusion_matrix(i,i)/
    %jaccard = tp/(tp+fn+fp)
    jaccard(i)      = confusion_matrix(i,i)/(p(i)+r(i)-confusion_matrix(i,i));
end


end

