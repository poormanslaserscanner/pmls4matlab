function S = libiglunionpy( HcO, pre )
%REMESHUNIONPY Summary of this function goes here
%   Detailed explanation goes here
disp(mfilename());
disp('input:');
n = numel(HcO);
for i = 1 : n
    HcO{i} %#ok<NOPRT>
end
pre %#ok<NOPRT>end
Hc = cell(n,1);
trisc = cell(n,1);
vtc = cell(n,1);
for i = 1 : n
    HcO{i}.pmls_type = 'mesh';
    Hc{i} = py2matlab(HcO{i});
    trisc{i} = Hc{i}.tris;
    vtc{i} = Hc{i}.vt;
end
if pre
    for i = 1:2
        [Hc{i}.vt, Hc{i}.tris]=meshcheckrepair(Hc{i}.vt,Hc{i}.tris,'meshfix');
        [Hc{i}.tris, Hc{i}.vt] = filterrefvertices( Hc{i}.tris, Hc{i}.vt );
    end
end
[vt,tris] = mesh_boolean(Hc{1}.vt, Hc{1}.tris, Hc{2}.vt, Hc{2}.tris, 'union');
[vt, tris]=meshcheckrepair(vt, tris, 'meshfix');
[tris, vt] = filterrefvertices( tris, vt );

name = '';
for i = 1 : n
    name = [name, Hc{i}.pmls_name, '_'];
end

S = struct('tris', tris, 'vt', vt, 'pmls_type', 'mesh', 'pmls_name', [name, 'union']);
S.pmls_type = 'deform_mesh';
hedgesc = cell(n,1);
logind = false(n,1);
for i = 1 : n
    if isfield(HcO{i}, 'hedgehog')
        logind(i) = true;
        hedgesc{i} = HcO{i}.hedgehog;
    end
end
hedgesc = hedgesc(logind);
m = nnz(logind);
if m == 1
    S.hedgehog = py2matlab(hedgesc{1});
elseif m > 1
    S.hedgehog = mergehdggeneral(hedgesc);
end

hedgesc = cell(n,1);
logind = false(n,1);
for i = 1 : n
    if isfield(HcO{i}, 'anchor')
        hedgesc{i} = py2matlab(HcO{i}.anchor);
        logind(i) = true;
    end
end
hedgesc = hedgesc(logind);
m = nnz(logind);
if m == 1
    S.anchor = hedgesc{1};
elseif m > 1
    S.anchor = hedgesc{1};
    S.anchor.vt = [S.anchor.vt; hedgesc{2}.vt];
end
S = matlab2py(clearanchors(S));
disp('output:');
S %#ok<NOPRT>

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
