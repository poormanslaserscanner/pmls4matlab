function nrays = filternearrays( rays, V )
%FILTERNEARRAYS Summary of this function goes here
%   Detailed explanation goes here
n = numel( rays );
nrays = cell(n,1);
for i = 1 : n
    nrays{i} = zeros(0,3);
end
DT = DelaunayTri(V);
for i = 1 : n
    [~,D] = nearestNeighbor(DT,rays{i});
    nrays{i} = rays{i}( D < 0.02, : );
end
end

