function mret = fn_sum_sins(param,data)
data = sparse(data);
l = floor(length(param)/3);
ssin = zeros(l,length(data));
count = 1;
if(sum(data)>0)
for i = 1:3:l-1
    a = param(i);
    b = param(i+1);
    c = param(i+2);

    
    ssin(count,:) = (c*sin(a+b*data));
    count = count+1;
end
mret = sum(sum(ssin));
else
    mret = 0;
end
end