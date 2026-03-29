function mret = nn_mlp_tr(w,layers)
m = length(w(1,:));
P = double(w(:,1:m-1))';
T = double(w(:,m)');
rand('seed', 672880951); %To melt the training to be repeated
net = newff(P,T,layers); % create neural network
net.trainParam.max_fail = 10;
net.trainParam.epochs = 5500;
net.trainParam.showWindow = false;
[net,~] = train(net,P,T); % trains
mret = net;
end
