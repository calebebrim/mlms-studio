function [ mret ] = fn_raw_file2w( file )
%FN_RAW_FILES2W Summary of this function goes here
%   Detailed explanation goes here
    fid = fopen(file,'r');
    ftext = textscan(fid, '%f%f');
    fclose(fid);
    mret{1} = [ftext{1}]';
    mret{2} = [ftext{2}]';
    
    
    
end

