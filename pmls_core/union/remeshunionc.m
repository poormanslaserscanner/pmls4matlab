function [ntris,nvt] = remeshunionc( trisc, vtc, bpar, bdist )
[v, bb0, grs] = binunion( trisc, vtc, bpar, bdist );
%[nvt, elem]=v2m(v,0.5,0.1, 200, 'simplify' );%, 'cgalmesh');
[nvt, elem]=v2m( v, 0.5, 1, 10, 'cgalmesh');
%ntris = ntris(:,1:3);
elem = elem(:,1:4);
nvt = nvt(:,1:3);

%nvt = ( nvt + 1 ) * grs + repmat( bb0, size(nvt,1),1 );

%pnts = cell2mat(rays);
[elem, nvt] = filterrefvertices( elem, nvt );
%[elem,nvt] = biharpnts( pnts, elem, nvt, 0.1 );

[ntris,nvt] = getsurface( elem, nvt );

nvt = ( nvt + 1.5 ) * grs + repmat( bb0, size(nvt,1),1 );

[ntris, nvt] = filterrefvertices( ntris, nvt );

[nvt,ntris]=meshcheckrepair(nvt,ntris,'meshfix');
[nvt,ntris]=meshcheckrepair(nvt,ntris,'dup');
[ntris, nvt] = filterrefvertices( ntris, nvt );

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