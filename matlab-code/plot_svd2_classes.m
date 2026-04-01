function plot_svd2_classes( Aux,classes,selector,axis_handler )
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
if(nargin<4)
    figure;
else 
    axes(axis_handler);
end

if(isempty(classes))
    plot_aux2(Aux,'',axis_handler);
else
    classes = [classes{:}];
    cuni = unique(classes);
    plot(0,0)
    hold('on')
    for i = 1:length(cuni)
        idx = cuni(i)==classes;
        plot_aux2(Aux(:,idx),plot_options(i),axis_handler);
    end
end
if(nargin>1 && ~isempty(selector))
    plot_aux2(Aux(:,selector),plot_options(i+1),axis_handler)
end
hold(axis_handler,'off')
end

