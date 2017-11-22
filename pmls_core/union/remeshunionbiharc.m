function [ntris,nvt,nsucc] = remeshunionbiharc( base, rays, trisc, vtc, bpar, bdist,...
    cuda, marcube, premesh, unilap )
%[trisc, vtc ] = hedgehogs( base, erays, zeroshots );
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%displaymeshes(trisc,vtc,[]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 7
    cuda = true;
end
if nargin < 8
    marcube = true;
end
if nargin < 9 || numel(trisc) > 1
    premesh = true;
end
if nargin < 10
    unilap = true;
end
if premesh
    [v, bb0, grs] = binunion( trisc, vtc, bpar, bdist );
    [nvt, elem]=v2m( v, 0.5, 2, 10, 'cgalmesh');
    elem = elem(:,1:4);
    nvt = nvt(:,1:3);
    [elem, nvt] = filterrefvertices( elem, nvt );
    nvt = ( nvt + 0.5 ) * grs + repmat( bb0, size(nvt,1),1 );

    [surftris,surfvt] = getsurface( elem, nvt );
    [surfvt,surftris]=meshcheckrepair(surfvt,surftris,'meshfix');
    [surfvt,surftris]=meshcheckrepair(surfvt,surftris,'dup');
    [surftris, surfvt] = filterrefvertices( surftris, surfvt );

else
    surftris = trisc{1};
    surfvt = vtc{1};
end

[allpnts,rayindices] = rays2indices(rays);
n = numel(rays);
basepnts = zeros(size(allpnts,1),3);
for i = 1 : n
    basepnts( rayindices{i}, : ) = repmat( base(i,:), numel( rayindices{i} ), 1 );
end
projpnts = projfromoutside(basepnts,allpnts,surftris,surfvt);
indices = revdistnn(projpnts,surfvt);
logind = ( indices > 0 );
nsucc = nnz(logind);
indices = indices(logind,:);
allpnts = allpnts(logind,:);
basepnts = basepnts(logind,:);
targetpnts = zeros(0,3);
handlepnts = zeros(0,3);
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
targetpnts = handlepnts + targetpnts;% - nvt(indices,:);
%a = dot( a, targetpnts, 2 ) ./ dot(targetpnts,targetpnts,2);
%a = max( min(a,1), 0 );
%targetpnts = targetpnts .* [a,a,a];
%targetpnts = nvt(indices,:) + targetpnts;

if unilap
    hvt = deformunilap(elem,nvt,indices,targetpnts, 2 );
else
    hvt = deform(elem,nvt,indices,targetpnts, 2 );
end
%hvt = hvt + nvt;
n = size(elem,1);
logind = true(n,1);
parfor i = 1 : n
    act = elem(i,:);
    a = hvt( act(2),: ) - hvt( act(1),: );
    b = hvt( act(3),: ) - hvt( act(1),: );
    c = hvt( act(4),: ) - hvt( act(1),: );
    logind(i) = det( [a;b;c] ) > 0;
end
elem = elem( logind,:);
[elem, hvt] = filterrefvertices( elem, hvt );
[ntris,nvt] = getsurface( elem, hvt );
[ntris,nvt] = remeshunionc({ntris},{nvt}, bpar, bdist, cuda, marcube);
end


