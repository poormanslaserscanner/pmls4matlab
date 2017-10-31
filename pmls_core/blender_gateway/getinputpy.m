function T = getinputpy( csvfile, truemin, poligonfile )
%GETINPUTPY Summary of this function goes here
%   Detailed explanation goes here
if nargin > 2
    [T.vid, base, edges, rays, zeroshots ] = getinputmain( csvfile, poligonfile );
else
    [T.vid, base, edges, rays, zeroshots ] = getinputmain( csvfile );
end
erays = cell(numel(rays),1);
[base, rays, T.vid, ~, zeroshots] = truehedgehogs(base, rays, T.vid, edges, zeroshots, truemin);
[T.vt, T.bindices, T.vzindices, T.edges, T.extindices, T.ezindices] = ...
    hedges2py(  base, rays, erays, zeroshots );
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

