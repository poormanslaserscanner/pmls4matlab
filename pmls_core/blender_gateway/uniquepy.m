function [H, DT] = uniquepy( H )
%UNIQUEPY Summary of this function goes here
%   Detailed explanation goes here
DT = delaunayTriangulation( H.verts );
indices = int32(nearestNeighbor(DT, H.verts));
H.verts = DT.Points;
n = size(H.verts,1);
ftmp = false(1,n);
ftmp( indices( H.selvt ) ) = true;
H.selvt = ftmp;
H.base_i = indices( H.base_i );
n = numel( H.rays_i );
for i = 1 : n
    H.rays_i{i} = unique(indices(H.rays_i{i}));
    H.zeroshots_i{i} = indices( H.zeroshots_i{i} );
end
if isfield(H, 'erays_i')
    for i = 1 : n
        H.erays_i{i} = unique(indices(H.erays_i{i}));
    end
end
end

