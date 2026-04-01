function p = plot_sins_waves(obj,params,wtr,ctr,axx)

% axes(fidx)
l = floor(length(params)/3);
idx = wtr;
resolution = 1000;
mimx = minmax([wtr{:}]);
domain = linspace(mimx(1),mimx(2),resolution);
class = ctr;



m = zeros(1,length(domain));
for i = 1:3:l-1
    a = params(i);
    b = params(i+1);
    c = params(i+2);
    %     ssin(count,:) = (x.*(c*sin(a+b*x)));
    m = m+(c*sin(a+b*domain));
end
% gca;
axes(axx)
plot(0,0);
hold on;
plot(m);

colors = 'rmgbyc';
simbol = 'ox*.pv';
all = [];
for i = 1:size(idx,1)
    nx = min(resolution,max(1,fix((([idx{i}]-mimx(1))*resolution)/diff(mimx))));
    plot(nx,m(nx),[simbol(class(i)) colors(class(i))])
    all = [all nx];
end

% for i = unique(all)
%     text(i+0.1,m(i)+0.1,sprintf('%4.2f',m(i)))
% end
allvalues = [];
uclass = unique(class);
for i = 1:length(uclass)
    cidx = class==uclass(i);
    tidx = idx(cidx);
    values = zeros(1,sum(cidx));
    
    for j = 1:sum(cidx)
        tv = max(1,min(resolution,fix((([tidx{j}]-mimx(1))*resolution)/diff(mimx))));
        values(j) = sum(m(tv));
    end
    allvalues = [allvalues values];
    [u] = unique(values);
    plot(-(i*resolution/10)*ones(1,length(u)),u,['>' colors(i)]);
    
    plot(0,mean(values),['>' colors(i)]);
end
% [u,uu] = count_unique(allvalues);
% 
% for j = 1:length(u)
%     text(-30,u(j),sprintf('%4d',uu(j)))
% end
% plot(m);
hold off;
refresh;
drawnow;
end