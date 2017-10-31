function [ trisc, vtc, H, A ] = py2deformmesh( Hc )
%PY2DEFORMMESH Summary of this function goes here
%   Detailed explanation goes here
H = -1;
A = -1;
n = numel(Hc);
trisc = cell(n,1);
vtc = cell(n,1);
for i = 1 : n
    Hc{i}.pmls_type = 'mesh';
    mesh = py2matlab(Hc{i});
    trisc{i} = mesh.tris;
    vtc{i} = mesh.vt;
end

hedgesc = cell(n,1);
logind = false(n,1);
for i = 1 : n
    if isfield(Hc{i}, 'hedgehog')
        logind(i) = true;
        hedgesc{i} = Hc{i}.hedgehog;
    end
end
hedgesc = hedgesc(logind);
m = nnz(logind);
if m == 1
    H = py2matlab(hedgesc{1});
elseif m > 1
    H = mergehdggeneral(hedgesc);
end

hedgesc = cell(n,1);
logind = false(n,1);
for i = 1 : n
    if isfield(Hc{i}, 'anchor')
        hedgesc{i} = py2matlab(Hc{i}.anchor);
        logind(i) = true;
    end
end
hedgesc = hedgesc(logind);
m = nnz(logind);
if m == 1
    A = hedgesc{1};
elseif m > 1
    A = hedgesc{1};
    for i = 2 : m
        A.vt = [A.vt; hedgesc{2}.vt];
    end
end
[H, A] = clearanchors(H, A);

end

function [H, A] = clearanchors(H, A)
if ~isstruct(A)
    return
end
allpnts = zeros(0,3);
feszpnts = allpnts;
if isstruct(H)
    allpnts = cell2mat(H.rays);
end
if isstruct(A)
    feszpnts = A.vt;
end
DT = delaunayTriangulation([feszpnts;allpnts]);
feszpnts = DT.Points;
rindices = int32(unique( nearestNeighbor(DT, allpnts) ));
erindices = int32(unique( nearestNeighbor(DT, feszpnts) ));
erindices = setdiff( erindices, rindices );
feszpnts = DT.Points(erindices,:);
A.vt = feszpnts;


end

