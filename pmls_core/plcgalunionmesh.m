function S = plcgalunionmesh( Hc, premeshfix, premesh, apar, qpar, dpar )
%PLCGALUNIONMESH Summary of this function goes here
%   Detailed explanation goes here
trisc = cell(n,1);
vtc = cell(n,1);
for i = 1 : n
    trisc{i} = Hc{i}.tris;
    vtc{i} = Hc{i}.vt;
end
params.MeshfixParam = ' -a 1.0 ';
if premeshfix
    for i = 1:n
        [Hc{i}.vt, Hc{i}.tris]=meshcheckrepair(Hc{i}.vt,Hc{i}.tris,'meshfix', params);
        [Hc{i}.tris, Hc{i}.vt] = filterrefvertices( Hc{i}.tris, Hc{i}.vt );
    end
end
[vt, tris] = tetremeshunionc(trisc, vtc, premesh, apar, qpar, dpar);
name = '';
for i = 1 : n
    name = [name, Hc{i}.pmls_name, '_'];
end
S = struct('tris', tris, 'vt', vt, 'pmls_type', 'mesh', 'pmls_name', [name, 'union']);
S.pmls_type = 'deform_mesh';
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
    S.hedgehog = hedgesc{1};
elseif m > 1
    S.hedgehog = plmergehdgs(hedgesc);
end
hedgesc = cell(n,1);
logind = false(n,1);
for i = 1 : n
    if isfield(Hc{i}, 'anchor')
        hedgesc{i} = Hc{i}.anchor;
        logind(i) = true;
    end
end
hedgesc = hedgesc(logind);
m = nnz(logind);
if m == 1
    S.anchor = hedgesc{1};
elseif m > 1
    S.anchor = hedgesc{1};
    for j = 2 : m
        S.anchor.vt = [S.anchor.vt; hedgesc{j}.vt];
    end
end
S = clearanchors(S);
end


function S = clearanchors(S)
if ~isfield(S, 'anchor')
    return
end
allpnts = zeros(0,3);
feszpnts = allpnts;
if isfield(S, 'hedgehog')
    allpnts = cell2mat(S.hedgehog.rays);
end
if isfield(S, 'anchor')
    feszpnts = S.anchor.vt;
end
DT = delaunayTriangulation([feszpnts;allpnts]);
feszpnts = DT.Points;
rindices = int32(unique( nearestNeighbor(DT, allpnts) ));
erindices = int32(unique( nearestNeighbor(DT, feszpnts) ));
erindices = setdiff( erindices, rindices );
feszpnts = DT.Points(erindices,:);
S.anchor.vt = feszpnts;
end

