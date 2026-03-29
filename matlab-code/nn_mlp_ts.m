function mret = nn_mlp_ts(w,net, varargin)
% Delta ? o fator de arredondamento [0 0.5]; se for
% positivo aumenta a tendencia da classe maior (rcpm)
delta = 0;
O = [];
if ~isempty(varargin)
    delta = varargin{1};
end
[n , m] = size(w);

testInputs = double(w(:,1:m-1))';
classes = double(w(:,m)');
nc = max(classes);

out0 = sim(net,testInputs);
out = round(out0+delta);
Result = out; % Get response of trained network
if min(classes) == 1
    classes = classes-1;
    out = out - 1;
    nc = nc-1;
    O = out0-1;
end
out(out>nc) = nc;
out(out<0) = 0;
conf = zeros(nc+1,nc+1);
for i=1:n
    conf(classes(i)+1,out(i)+1) = conf(classes(i)+1,out(i)+1)+1;
end
mret.conf = conf;
r = [];
for i=1:(nc+1)
    u = conf(i,i)/sum(conf(:,i));
    r = [r u];
end
certos = 100*(sum(out==classes))/n;
mret.certos = certos;
mret.prop = r;
mret.Result = Result;
mret.Res0 = out0;
mret.T = classes;
mret.O = O;
end