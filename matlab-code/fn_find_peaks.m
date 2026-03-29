function [x,y] = fn_find_peaks(vect,varargin)
%1-'high' 2-'low' 3-'all'
mdo = 3; %'all';
if ~isempty(varargin)
    mdo = varargin{1};
end
[z ,iz] = findpeaks(vect);
[x ,ix] = findpeaks(-vect);
u = [z -x]';
iu = [iz ix]';
u = [iu u];
if mdo==1
    iu = iz';
    u = [iu z'];
elseif mdo==2
    iu = ix';
    u = [iu -x'];
end
[~,ii] = sort(iu);
mret = u(ii,:);
x = mret(:,1);
y = mret(:,2);
end