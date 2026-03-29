function [mret]= fn_triang_fuzzy(xvect,dvect,varargin)
%x vetor com floats; s?o os centros dos conjuntos difusos
%d ? o numero de vizinhos a serem considerados de cada lado
%varargin = range;

szx = size(xvect);
% szd = size(dvect);
if ~isempty(varargin)
    range = varargin{1};
else
    range = max(szx);
end
mret = zeros(szx(1),range);
for v = 1:szx(1)
    x = xvect(v,:);
    try
        d = dvect(v,:);
    catch e
        e
    end
    n = length(x);
    if(length(d)~=n)
        d = ones(1,n)*d;
    end
    wsups = zeros(1,range);
    for i=1:n
        suport = zeros(1,range);
        %{
        tf = ECOSPEC.tf_set.get(d(i))';
       
        %}
        tf = [0 triang((2*d(i))+1)' 0];
        io = fix(x(i))-d(i)-1;
        ie = fix(x(i))+d(i)+1;
        isup = io:ie;
        iisup = (isup>0 & isup<=range);
        suport(isup(iisup)) = tf(iisup);
        wsups = max(wsups,suport);
    end
    mret(v,1:range) = wsups;
end
end