function sqlite2csvs( sqfile, maincsvfile, dir )
%SQLITE2CSVS Summary of this function goes here
%   Detailed explanation goes here
fid = fopen(maincsvfile,'rt'); 
textscan(fid,'%s', 1,'delimiter', '\n');
if nargin < 3
    dir = '';
end
while ~feof(fid)
    lin = textscan(fid,'%s', 1,'delimiter', '\n');
    lin = lin{1};
    if numel( lin ) < 1
        continue;
    end
    lin = lin{1};
    tmp = textscan( lin, '%s', 'delimiter', '|');
    if numel(tmp) < 1
        continue;
    end
    tmp = tmp{1};
    if numel(tmp) < 1
        continue
    end
    csvfile = [dir, tmp{1}, '.csv'];
    sqlite2csv( sqfile, round(str2double(tmp{1})), csvfile );      
end
fclose(fid);
end

