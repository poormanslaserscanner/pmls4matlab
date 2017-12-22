function T = plmergehdgs( Hc )
%PLMERGEHDGS Summary of this function goes here
%   Detailed explanation goes here
n = numel( Hc );
vid = cell(0,1);
base = zeros(0, 3);
rays = cell(0, 1);
erays = cell(0, 1);
zeroshots = cell(0, 1);
extended = true;
for i = 1 : n
    H = Hc{i};
    obase = H.base;
    orays = H.rays;
    ozeroshots = H.zeroshots;
    if isfield( H, 'erays' )
        oerays = H.erays;
    else
        extended = false;
        oerays = H.rays;
    end
    [vid, base, rays, erays, zeroshots] = mergehedgehog( vid, base, rays, erays, zeroshots, H.vid, obase, orays, oerays, ozeroshots );
end
if ~extended
    erays = cell(numel(rays),1);
    T.pmls_type = 'hedgehog';    
else
    T.pmls_type = 'ehedgehog';
end
% [ T.vt, T.bindices, T.vzindices, T.edges, T.extindices, T.ezindices ] = ...
%     hedges2py(  base, rays, erays, zeroshots );
T.base = base;
T.rays = rays;
T.erays = erays;
T.zeroshots = zeroshots;
T.vid = vid;
name = '';
for i = 1 : n
    name = [name, Hc{i}.pmls_name, '_'];
end
if n > 0
    T.pmls_name = [name, 'merge'];
end


end

