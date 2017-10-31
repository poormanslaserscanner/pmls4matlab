function data = separateturtles( H )
%TURTLE2PY Summary of this function goes here
%   Detailed explanation goes here
disp(mfilename());
disp('input:');
H %#ok<NOPRT>

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
pmlstype = 'hedgehog';
logind = H.selvt( H.base_i );
if isfield( H, 'erays_i' )
    pmlstype = 'ehedgehog';
%     for i = 1 : n
%         erays{i} = H.verts( H.erays_i{i}, : );
%     end
    [base, rays, zeroshots, erays] = py2hedges(  H.verts, H.base_i, H.rays_i, H.zeroshots_i, H.erays_i );
    [trisc,vtc] = hedgehogs(base(logind,:), erays(logind), zeroshots(logind));
else
    [base, rays, zeroshots, erays] = py2hedges(  H.verts, H.base_i, H.rays_i, H.zeroshots_i );
    [trisc,vtc] = hedgehogs(base(logind,:), rays(logind), zeroshots(logind));
end
n = nnz(logind);
data = cell(n,1);
logind = find(logind);
for i = 1 : n
    index = logind(i);
    D = struct('vt',        vtc{i},               ...
               'tris',      trisc{i},             ...
               'pmls_type', 'deform_mesh',        ...
               'pmls_name', [H.vid{index}, '_t'], ...
               'hedgehog',  struct('vid',       {H.vid(index)},      ...
                                   'base',      base(index,:),     ...
                                   'rays',      {rays(index)},       ...
                                   'zeroshots', {zeroshots(index)},  ...
                                   'erays',     {erays(index)},      ...
                                   'pmls_type', pmlstype,          ...
                                   'pmls_name', [H.vid{index}, '_h']) );
    data{i} = matlab2py( D );
       
end
disp('output:');
data %#ok<NOPRT>