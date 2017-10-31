function T = extendvisiblepy( H )
%EXTENDVISIBLEPY Summary of this function goes here
%   Detailed explanation goes here
T.vid = H.vid;
H = uniquepy( H );
[base, rays, zeroshots] = py2hedges(  H.verts, H.base_i, H.rays_i, H.zeroshots_i );
edg = zeros(0,2);
[base, rays, T.vid, ~, zeroshots] = truehedgehogs(base, rays, T.vid,edg, zeroshots, 10);
erays = extendvisible( base, rays, zeroshots );
erays = minvisible( base, rays, erays, zeroshots );
[ T.vt, T.bindices, T.vzindices, T.edges, T.extindices, T.ezindices, DT ] = ...
    hedges2py(  base, rays, erays, zeroshots );
T.pmls_type = 'ehedgehog';
T.pmls_name = [H.pmls_name, '_e'];
end

