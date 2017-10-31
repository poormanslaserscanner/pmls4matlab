function [base, rays, zeroshots, erays] = py2hedges(  verts, base_i, rays_i, zeroshots_i, erays_i )
%PY2HEDGES Summary of this function goes here
%   Detailed explanation goes here
base = verts( base_i, : );
n = numel( rays_i );
rays = cell(n,1);
for i = 1 : n
    rays{i} = zeros(0,3);
end
erays = rays;
zeroshots = rays;
for i = 1 : n
    index = zeroshots_i{i};
    if numel(index)
        xyz = verts( index(1), : ) - base(i,:);
        [th,ph] = cart2sph( xyz(:,1), xyz(:,2), xyz(:,3) );
        zeroshots{i} = [i, th, ph];
    end
end
for i = 1 : n
    rays{i} = verts( rays_i{i}, : );
end
if nargin > 4
    for i = 1 : n
        erays{i} = verts( erays_i{i}, : );
    end
end
