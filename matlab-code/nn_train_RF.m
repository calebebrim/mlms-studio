function train_structure = nn_train_RF(peaks,combfeature,nTrees)
[wtr,wts] = make_wtrts(peaks,[combfeature combfeature.transform.features]);
features = wtr;
B = TreeBagger(nTrees,features(:,1:end-1),features(:,end), 'Method', 'classification');
 
% Given a new individual WITH the features and WITHOUT the class label,
% what should the class label be?
 
% Use the trained Decision Forest.
predChar1 = B.predict(wts(:,1:end-1));
 
% Predictions is a char though. We want it to be a number.
predictedClass = str2double(predChar1);
ccompare = ([wts(:,end) predictedClass]);
disp(ccompare);
errors = sum(abs(ccompare(:,1)-ccompare(:,2)));
disp(['errors: ' num2str(errors)]);

% % predictedClass =
% %      1
%  
% % So we predict that for our new piece of data, we will have a class label of 1 
%  
% % Okay let's try another piece of data.
% newData2 = [7, 1500];
%  
% predChar2 = B.predict(newData2);
% predictedClass2 = str2double(predChar2)

end