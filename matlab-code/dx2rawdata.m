function dx2rawdata(destiny,origin)

%% Searching file
if(nargin>1)
    cd(origin)
end
files = searchForFileName('.dx',true);
%% 
if(isempty(destiny))
    folder = 'converted/';
else
    folder = [destiny '/'];
end
mkdir(folder);
lfs = length(files);
for i = 1:lfs
    disp(i);
    f = readfile( files{i});
    if(~isempty(f))
        nfiledata = char(java.lang.String(replace(f(23,:),',', ' ')).split(';'));
        fname = files{i};
        files_div = find(files{i}=='/');
        dots = find(files{i} == '.');
        
        filename = [folder  fname(files_div(1)+1:files_div(2)-1) fname(files_div(end)+1:dots(end)-1) '.txt'];
        writefile(nfiledata,filename);
    end
end
disp('Conversion Finnished.');
end