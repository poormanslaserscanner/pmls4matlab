function T = getoutlierspy( SO, internal, dihedral )
%MAPPNTSPY Summary of this function goes here
%   Detailed explanation goes here
disp(mfilename());
disp('input:');
SO %#ok<NOPRT>
S = py2matlab(SO);
if isfield( S, 'erays' )
    outrays = gethedgepeaks(S.base, S.rays, S.erays, S.zeroshots, internal, dihedral);
else
    outrays = gethedgepeaks(S.base, S.rays, S.rays, S.zeroshots, internal, dihedral);
end
DT = delaunayTriangulation(SO.verts);
pind = nearestNeighbor(DT,SO.verts);
indc = cell(size(DT.Points,1),1);
n = numel(pind);
for i = 1 : n
    indc{pind(i)} = [indc{pind(i)},i];
end
n = numel(S.rays);
indices = zeros(1,0);
for i = 1 : n
    if numel(outrays{i}) == 0
        continue
    end
    pnts = S.rays{i}(outrays{i},:);
    pind = nearestNeighbor(DT,pnts);
    aindc = cell2mat((indc(pind,:))');
    indices = [indices,aindc(1,:)];
end
T = (int32(indices(indices>0)) - 1)';
end

