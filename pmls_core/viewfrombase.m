function [ tris, vt, nsucc, badpoints ] = viewfrombase( base, rays, tris, vt )
%VIEWFROMBASE Summary of this function goes here
%   Detailed explanation goes here
[allpnts, rayindices] = rays2indices(rays);
basepnts = zeros(size(allpnts,1),3);
n = numel(rays);
for i = 1 : n
    basepnts( rayindices{i}, : ) = repmat( base(i,:), numel( rayindices{i} ), 1 );
end
TR = TriRep(tris,vt);
tris = TR.Triangulation;
vt = TR.X;
indices = revdistnn(allpnts,vt);
logind = ( indices > 0 );
nsucc = nnz(logind);
badpoints = allpnts( ~logind,: );
indices = indices(logind);
basepnts = basepnts(logind,:);
indices = vertexAttachments(TR,indices);
n = numel( indices );
basec = cell(n,1);
for i = 1 : n
    m = numel(indices{i});
    basec{i} = repmat(basepnts(i,:),m,1);
end
indices = (cell2mat(indices'))';
basepnts = cell2mat( basec );
fn = faceNormals( TR, indices );
ic = incenters( TR, indices );
ic = ic - basepnts;
dotp = dot( ic, fn, 2 );
if nnz( dotp >= 0 ) >= numel( dotp ) / 2
    disp('faces may be ok');
    return
else
    disp( 'all faces will be turned' );
    tris = tris( :, [3, 2, 1] );
end

end

