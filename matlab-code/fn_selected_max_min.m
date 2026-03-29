function [mx,mn] = selected_max_min(ECOSPEC)
%Show get the current max and min peak
%Result depends of selection
dt = ECOSPEC.data.selected_mz;
p = [dt{:}];
mx = max(p);
mn = min(p);
end