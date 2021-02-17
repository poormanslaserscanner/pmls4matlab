function T = plgetinput( csvfile, truemin, poligonfile )
%GETINPUTPY Summary of this function goes here
%   Detailed explanation goes here
try
if nargin > 2
    [T.vid, T.base, T.edges, T.rays, T.zeroshots ] = getinputmainblind( csvfile, poligonfile );
else
    [T.vid, T.base, T.edges, T.rays, T.zeroshots ] = getinputmainblind( csvfile );
end
catch ME
    fclose('all');
    rethrow(ME);
end
[T.base, T.rays, T.vid, T.edges, T.zeroshots] = truehedgehogs(T.base, T.rays, T.vid, T.edges, T.zeroshots, truemin);
T.pmls_type = 'hedgehog';
fp = csvfile;
if any(fp=='\')
    i = find(fp == '\');
    i = i(end);
    fp = fp(i+1:end);
end
if any(fp=='.')
    i = find(fp == '.');
    i = i(end);
    fp = fp(1:i-1);
end
T.pmls_name = [fp, '_hdg'];
end

