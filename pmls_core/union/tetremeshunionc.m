function [ vt, tris ] = tetremeshunionc( trisc, vtc, premesh, apar, qpar, dpar )
%TETREMESHUNION Summary of this function goes here
%   Detailed explanation goes here
n = numel(trisc);
if premesh
    for i = 1 : n
         [v, tetr] = tetremesh(trisc{i}, vtc{i}, apar, qpar, dpar);
         [trisc{i}, vtc{i}] = getsurface( tetr, v );
    end
end
if n == 0
    vt = zeros(0,3);
    tris = zeros(0,3);
elseif n == 1
    vt = vtc{1};
    tris = trisc{1};
elseif n == 2
    [vt,tris] = mesh_boolean(vtc{1}, trisc{1}, vtc{2}, trisc{2}, 'union');
else
    [vt,tris] = mesh_boolean(vtc, trisc, 'union');
end
[vt, tris]=meshcheckrepair(vt, tris, 'meshfix');
[tris, vt] = filterrefvertices( tris, vt );
end

