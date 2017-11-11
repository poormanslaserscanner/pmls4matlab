function [ntris,nvt,nsucc] = remeshunionbiharc( base, rays, trisc, vtc, bpar, bdist, premesh, unilap )
%[trisc, vtc ] = hedgehogs( base, erays, zeroshots );
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%displaymeshes(trisc,vtc,[]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 7 || numel(trisc) > 1
    premesh = true;
end
if nargin < 8
    unilap = true;
end
if premesh
[v, bb0, grs] = binunion( trisc, vtc, bpar, bdist );
%[nvt, elem]=v2m( v, 0.5, 2, 3, 'cgalmesh');
[nvt, elem]=v2m( v, 0.5, 2, 10, 'cgalmesh');

%[nvt,elem]=surf2mesh(vtc{1},trisc{1},min(vtc{1}) - 0.2,max(vtc{1}) + 0.2,1.0,0.5);

elem = elem(:,1:4);
nvt = nvt(:,1:3);
[elem, nvt] = filterrefvertices( elem, nvt );
nvt = ( nvt + 1.5 ) * grs + repmat( bb0, size(nvt,1),1 );

[surftris,surfvt] = getsurface( elem, nvt );
else
    surftris = trisc{1};
    surfvt = vtc{1};
end
%TR = TriRep( elem,nvt );
%E = edges(TR);
%fid = dxf_open( 'tetra.dxf' );
%n = size( E, 1 );
%for i = 1 : n
%        sgm = [nvt(E(i,1),:);nvt(E(i,2),:)];
%        dxf_polyline( fid, sgm(:,1), sgm(:,2), sgm(:,3) ); 
%end
%dxf_close(fid);



[allpnts,rayindices] = rays2indices(rays);
n = numel(rays);
basepnts = zeros(size(allpnts,1),3);
for i = 1 : n
    basepnts( rayindices{i}, : ) = repmat( base(i,:), numel( rayindices{i} ), 1 );
end
projpnts = projfromoutside(basepnts,allpnts,surftris,surfvt);
%indices = revdistnn(allpnts,surfvt);
indices = revdistnn(projpnts,surfvt);
logind = ( indices > 0 );
nsucc = nnz(logind);
indices = indices(logind,:);
allpnts = allpnts(logind,:);
basepnts = basepnts(logind,:);
targetpnts = zeros(0,3);
handlepnts = zeros(0,3);
%targetpnts = allpnts;
%handlepnts = surfvt(indices,:);
n = numel( indices );
for i = 1 : n
    p0 = basepnts(i,:);
    ph = surfvt(indices(i),:);
    pt = allpnts(i,:);
    d = norm( pt - p0 );
    N = ceil( d / 0.1 );
    v = pt - ph;
    if N > 0
        lin1 = linspace( 0, v(1), N );
        lin2 = linspace( 0, v(2), N ); 
        lin3 = linspace( 0, v(3), N );
        lin = [lin1',lin2',lin3'];
        targetpnts = [targetpnts;lin];
        lin1 = linspace( p0(1), ph(1), N );
        lin2 = linspace( p0(2), ph(2), N ); 
        lin3 = linspace( p0(3), ph(3), N );
        lin = [lin1',lin2',lin3'];
        handlepnts = [handlepnts;lin];
    end
end
DT = DelaunayTri( handlepnts );
PI = nearestNeighbor(DT,handlepnts);
[~, ia] = unique(PI);
handlepnts = handlepnts( ia, : );
targetpnts = targetpnts( ia, : );

%[nvt,elem]=surf2mesh([surfvt;handlepnts],surftris,min(surfvt) - 0.2,max(surfvt) + 0.2,1.0,0.5);
%[nvt,elem] = tetremesh( surftris, [surfvt;handlepnts], 0.5 );
[nvt,elem] = tetremesh( surftris, surfvt, 0.5 );
%elem = elem(:,1:4);
%nvt = nvt(:,1:3);
%[elem, nvt] = filterrefvertices( elem, nvt );

indices = revdistnn(handlepnts,nvt);
logind = (indices > 0 );

indices = indices(logind,:);
targetpnts = targetpnts(logind,:);
handlepnts = handlepnts(logind,:);


[nvt,elem] = tetremesh( surftris, [surfvt;handlepnts], 0.5 );
%elem = elem(:,1:4);
%nvt = nvt(:,1:3);
%[elem, nvt] = filterrefvertices( elem, nvt );

indices = revdistnn(handlepnts,nvt);
logind = (indices > 0 );

indices = indices(logind,:);
targetpnts = targetpnts(logind,:);
handlepnts = handlepnts(logind,:);


[indices,m] = unique(indices);
targetpnts = targetpnts(m,:);
handlepnts = handlepnts(m,:);
a = handlepnts + targetpnts - nvt(indices,:);
a = dot( a, targetpnts, 2 ) ./ dot(targetpnts,targetpnts,2);
a = max( min(a,1), 0 );
targetpnts = targetpnts .* [a,a,a];
%targetpnts = nvt(indices,:) + targetpnts;

% fid = dxf_open( 'deform.dxf' );
% n = numel( indices );
% for i = 1 : n
%         sgm = [nvt(indices(i),:);targetpnts(i,:)];
%         dxf_polyline( fid, sgm(:,1), sgm(:,2), sgm(:,3) ); 
% end
% dxf_close(fid);

if unilap
    hvt = deformunilap(elem,nvt,indices,targetpnts, 2 );
else
    hvt = deform(elem,nvt,indices,targetpnts, 2 );
end
hvt = hvt + nvt;
%hvt = deformlim(elem,nvt,indices,targetpnts);
n = size(elem,1);
logind = true(n,1);
for i = 1 : n
    act = elem(i,:);
    a = hvt( act(2),: ) - hvt( act(1),: );
    b = hvt( act(3),: ) - hvt( act(1),: );
    c = hvt( act(4),: ) - hvt( act(1),: );
    logind(i) = det( [a;b;c] ) > 0;
end
elem = elem( logind,:);
% fid = dxf_open( 'tetradef.dxf' );
% n = size( E, 1 );
% for i = 1 : n
%         sgm = [hvt(E(i,1),:);hvt(E(i,2),:)];
%         dxf_polyline( fid, sgm(:,1), sgm(:,2), sgm(:,3) ); 
% end
% dxf_close(fid);


%[hvt,ntris]=meshcheckrepair(hvt,ntris,'meshfix');
%displaymeshes( {ntris}, {nvt}, [] ); 
%[nvt,ntris]=meshcheckrepair(nvt,ntris,'dup');
[elem, hvt] = filterrefvertices( elem, hvt );



%[elem,nvt] = biharpnts( pnts, elem, nvt, 1000 );

[ntris,nvt] = getsurface( elem, hvt );
%savestl( nvt,ntris, 'd0.stl' );
%[ntris, nvt] = filterrefvertices( ntris, nvt );
[ntris,nvt] = remeshunionc({ntris},{nvt}, bpar, bdist);
%[ntris, nvt] = filterrefvertices( ntris, nvt );
%savestl( nvt,ntris, 'd1.stl' );

%[nvt,ntris]=meshcheckrepair(nvt,ntris,'meshfix');
%[nvt,ntris]=meshcheckrepair(nvt,ntris,'dup');
%[ntris, nvt] = filterrefvertices( ntris, nvt );
%savestl( nvt,ntris, 'd2.stl' );

%for iiii = 1 : 3
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%displaymeshes( {ntris}, {nvt}, [] ); 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return
DT = DelaunayTri( nvt );
QX = cell2mat( rays );
PI = nearestNeighbor(DT,QX);
n = size( nvt,1);
modified = false( n, 1 );
modified( PI ) = true;
ntris = discretevoronoi( ntris, nvt, modified );
displaymeshes( {ntris}, {nvt}, [] );
nvt(PI,:) = QX;
displaymeshes( {ntris}, {nvt}, [] ); 
[ntris,nvt] = filterrefvertices( ntris,nvt );
displaymeshes( {ntris}, {nvt}, [] ); 
[nvt,ntris]=meshcheckrepair(nvt,ntris,'meshfix');
displaymeshes( {ntris}, {nvt}, [] ); 
[nvt,ntris]=meshcheckrepair(nvt,ntris,'dup');
displaymeshes( {ntris}, {nvt}, [] ); 
[ntris, nvt] = filterrefvertices( ntris, nvt );

displaymeshes( {ntris}, {nvt}, [] ); 
%end
end


