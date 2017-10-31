function T = turtlepy( H )
%TURTLE2PY Summary of this function goes here
%   Detailed explanation goes here
disp(mfilename());
disp('input:');
H %#ok<NOPRT>
T.vid = H.vid;
H = uniquepy( H );
% base = H.verts( H.base_i, : );
% n = numel( H.rays_i );
% rays = cell(n,1);
% erays = cell(n,1);
% zeroshots = rays;
% for i = 1 : n
%     index = H.zeroshots_i{i};
%     if numel(index)
%         xyz = H.verts( index(1), : ) - base(i,:);
%         [th,ph] = cart2sph( xyz(:,1), xyz(:,2), xyz(:,3) );
%         zeroshots{i} = [i, th, ph];
%     end
% end
% for i = 1 : n
%     rays{i} = H.verts( H.rays_i{i}, : );
% end
pmlstype = 'turtle';
logind = H.selvt( H.base_i );
if isfield( H, 'erays_i' )
    pmlstype = 'eturtle';
%     for i = 1 : n
%         erays{i} = H.verts( H.erays_i{i}, : );
%     end
    [base, rays, zeroshots, erays] = py2hedges(  H.verts, H.base_i, H.rays_i, H.zeroshots_i, H.erays_i );
    [trisc,vtc] = hedgehogs(base(logind,:), erays(logind), zeroshots(logind));
else
    [base, rays, zeroshots, erays] = py2hedges(  H.verts, H.base_i, H.rays_i, H.zeroshots_i );
    [trisc,vtc] = hedgehogs(base(logind,:), rays(logind), zeroshots(logind));
end
[ T.vt, T.bindices, T.vzindices, T.edges, T.extindices, T.ezindices, DT ] = ...
    hedges2py(  base, rays, erays, zeroshots );
n = numel( vtc );
for i = 1 : n
    indices = int32(nearestNeighbor(DT, vtc{i}));
    trisc{i} = indices( trisc{i} );
end
T.tris = cell2mat( trisc ) - 1;
T.pmls_type = pmlstype;
T.pmls_name = H.pmls_name;
disp('output:');
T %#ok<NOPRT>