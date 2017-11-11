function [nvt, elem] = tetremesh( tris, vt, apar, qpar, dpar )
%TETREMESH Summary of this function goes here
%   Detailed explanation goes here
if nargin < 3
    apar = 0.5;
end
if nargin < 4
    qpar = 2.0;
end
if nargin < 5
    dpar = 0.0;
end
[tris, vt] = uniqueverts(tris, vt );
ISO2MESH_TETGENOPT = ['-A -q' num2str(qpar, 4) '/' num2str(dpar, 4) 'a' num2str(apar, 4) ];
[nvt,elem]=surf2mesh( vt, tris, min(vt) - 0.2, max(vt) + 0.2, 1.0, apar );
elem = elem(:,1:4);
nvt = nvt(:,1:3);
[elem, nvt] = filterrefvertices( elem, nvt );
end

