function [nvt, elem] = tetremesh( tris, vt, par )
%TETREMESH Summary of this function goes here
%   Detailed explanation goes here
if nargin < 3
    par = 0.5;
end
[tris, vt] = uniqueverts(tris, vt );
[nvt,elem]=surf2mesh( vt, tris, min(vt) - 0.2, max(vt) + 0.2, 1.0, par);
elem = elem(:,1:4);
nvt = nvt(:,1:3);
[elem, nvt] = filterrefvertices( elem, nvt );
end

