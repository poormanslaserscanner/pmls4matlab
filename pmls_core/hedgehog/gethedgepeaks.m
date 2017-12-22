function indicesc = gethedgepeaks( base, rays, erays, zeroshots, internal, dihedral )
%GETHEDGEPEAKS Summary of this function goes here
%   Detailed explanation goes here
if nargin < 5
    internal = 5.0;
end
if nargin < 6
    dihedral = internal;
end

n = numel(rays);
[trisc,vtc] = hedgehogs(base, erays, zeroshots);
indicesc = cell(n,1);
for i = 1 : n
    if numel(vtc{i}) == 0
        continue
    end
    DT = delaunayTriangulation(vtc{i});
    pind = nearestNeighbor(DT, vtc{i});
    vt = DT.Points;
    tris = pind(trisc{i});
    DA = adjacency_dihedral_angle_matrix(vt,tris) * 180 / pi;
    DA(DA>dihedral & DA < 360 - dihedral) = 0;
    [di,~] = find(DA);
    trlogind = true(size(tris,1),1);
    trlogind(di) = false;
    tris = tris(trlogind,:);
    angles = internalangles(vt,tris);
    angles = angles * 180 / pi;
    indices = tris(angles > internal);
    indices = unique(indices(:));
    m = size(vt,1);
    logind = false(m,1);
    logind(indices) = true;
    logind = ~logind;
    rind = nearestNeighbor(DT, rays{i});
    indicesc{i} = find(logind(rind));
end
end

