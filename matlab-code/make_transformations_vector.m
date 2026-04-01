function [ transformations ] = make_transformations_vector(features)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
lnp = length(features);
transformations = cell(lnp,1);
for i = 1:lnp
    p = features(i);
    transformations{i} = @(data)p.transform.function(p.transform.params,p.transform.preprocess(data)); 
end
    
end

