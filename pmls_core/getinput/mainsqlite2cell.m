function out = mainsqlite2cell( sqfile )
%SELDAT Summary of this function goes here
%   Detailed explanation goes here
fp = which( 'sqlite3.exe' );
i = find(fp == '\');
if ~isempty(i)
    i = i(end) - 1;
    fp = fp(1:i);
    s = sqlite(sqfile, fp);
else
    s = sqlite(sqfile);
end
[~,str] = fprintf( s, sprintf('SELECT * FROM surveys') );
str = textscan(str,'%s', 'delimiter', '\n');
str = str{1};
n = numel(str);
out = cell(n,8);
for i = 1 : n
    lin = textscan(str{i},'%s', 'delimiter', '|');
    lin = lin{1};
    if (numel(lin) ~= 7 )
        continue;
    end
    out(i,:) = [lin', false];
end
end

