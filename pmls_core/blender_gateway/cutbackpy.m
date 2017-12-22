function T = cutbackpy( SO )
%CUTBACKPY Summary of this function goes here
%   Detailed explanation goes here
disp(mfilename());
disp('input:');
SO %#ok<NOPRT>
S = py2matlab(SO);
T = S.hedgehog;
[allpnts,rayindices] = rays2indices(T.rays);
n = numel(T.rays);
basepnts = zeros(size(allpnts,1),3);
for i = 1 : n
    basepnts( rayindices{i}, : ) = repmat( T.base(i,:), numel( rayindices{i} ), 1 );
end
%[projpnts, logind] = projfromoutside(basepnts,allpnts,S.tris,S.vt);
[projpnts, logind] = castrayssimple(basepnts,allpnts,S.tris,S.vt);
m = nnz(logind);
% sd = signed_distance([allpnts(logind,:); 
%                       allpnts(logind,:) + 2 * (allpnts(logind,:) - projpnts(logind,:))],... 
%                       S.vt, S.tris, 'SignedDistanceType', 'winding_number');
% indices = find(logind);
%logind(indices(sd((1:m)') < sd((m+1:2*m)'))) = false;
%logind(indices(0 < sd((m+1:2*m)'))) = false;
indices = cell2mat(SO.hedgehog.rays_i);
SO.hedgehog.verts(indices(logind),:) = projpnts(logind,:);
T = matlab2py(py2matlab(SO.hedgehog));
DT = delaunayTriangulation(T.vt);
vti = nearestNeighbor(DT, T.vt);
pri = nearestNeighbor(DT, projpnts(logind,:));
indices = find(ismember(vti,pri));
T.selhdgvt = int32(indices - 1);
disp('output:');
T %#ok<NOPRT>
end

