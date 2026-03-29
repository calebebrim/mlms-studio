function mret = intervallist2inds(list)
%Define indices em range para os intervalos io:if de list nX2
%Ex.: 
% >> x = 1:20;
% >> x(intervallist2inds([1,5;7,8;11,14])) = 0
% x -> 0   0   0   0   0   6   0   0   9  10   0   0   0   0  15  16  17  18  19  20
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(list)
    n = length(list(:,1));
    lmax = max(list(:,2)-list(:,1)) + 1;
    imax = repmat(list(:,2),1,lmax);
    ivar = repmat(list(:,1),1,lmax)+repmat(0:lmax-1,n,1);
    mret = min(imax,ivar);
else
    mret = [];
end
