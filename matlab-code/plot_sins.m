function p = plot_sins(params,wtr,ctr,axx)

axes(axx)
data = [wtr{:}];
[domain,count] = fn_count_unique(data);
lwtr = length(domain);
l = floor(length(params)/3);

m = zeros(1,lwtr);
for i = 1:3:l-1
    a = params(i);
    b = params(i+1);
    c = params(i+2);
    %     ssin(count,:) = (x.*(c*sin(a+b*x)));
    m = m+(c*sin(a+b*domain'));
end
% gca;
% uclass = unique(ctr);
% lc = length(uclass);
% class_count = zeros(lc,length(domain));
% 
% for i = 1:lc
%  [d,count] = count_unique([wtr{ctr==uclass(i)}]);
%     for j = 1:length(domain)
%         da = count(d'==domain(j));
%         if(isempty(da))
%             da = 0;
%         end
%         class_count(i,j) = da;
%     end
% end
% m = [m;class_count];
axes(axx)
if(~isempty(m))
    bar(m);
end

end