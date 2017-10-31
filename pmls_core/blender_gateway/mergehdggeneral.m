function T = mergehdggeneral( Hc )
%MERGEINPUTPY Summary of this function goes here
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
    if isfield( H, 'erays_i' )
        [obase, orays, ozeroshots, oerays] = py2hedges(  H.verts, H.base_i, H.rays_i, H.zeroshots_i, H.erays_i );
    else
        extended = false;
        [obase, orays, ozeroshots, oerays] = py2hedges(  H.verts, H.base_i, H.rays_i, H.zeroshots_i );
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
