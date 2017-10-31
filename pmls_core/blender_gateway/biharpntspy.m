function T = biharpntspy( SO, snaptol, voxsiz, to_raycheck )
%BIHARPNTSPY Summary of this function goes here
%   Detailed explanation goes here
disp(mfilename());
disp('input:');
SO %#ok<NOPRT>
%HP %#ok<NOPRT>
snaptol %#ok<NOPRT>
voxsiz %#ok<NOPRT>
to_raycheck %#ok<NOPRT>
snaptol = snaptol / 100;
S = py2matlab(SO);
allpnts = zeros(0,3);
feszpnts = allpnts;
anchorvt = allpnts;
if isfield(S, 'hedgehog')
    allpnts = cell2mat(S.hedgehog.rays);
end
if isfield(S, 'anchor')
    feszpnts = S.anchor.vt;
end
if isfield(S, 'anchorvt')
    anchorvt = S.anchorvt;
end
% if isfield(HP, 'H')
%     H = py2matlab(HP.H);
%     allpnts = cell2mat(H.rays);
% end
% if isfield(HP, 'P')
%     P = py2matlab(HP.P);
%     feszpnts = P.vt;
% end
%feszpnts = [feszpnts; allpnts];
[tris, vt] = biharpnts_revdist( [anchorvt; allpnts; feszpnts], S.tris, S.vt, snaptol, allpnts );
if ~isempty(allpnts)
    if to_raycheck
        opnts = getrayoutmax(tris, vt, S.hedgehog.base, S.hedgehog.rays, voxsiz);
        feszpnts = [feszpnts;opnts];
        DT = delaunayTriangulation([feszpnts;allpnts]);
        feszpnts = DT.Points;
        rindices = int32(unique( nearestNeighbor(DT, allpnts) ));
        erindices = int32(unique( nearestNeighbor(DT, feszpnts) ));
        erindices = setdiff( erindices, rindices );
        feszpnts = DT.Points(erindices,:);
        [tris, vt] = biharpnts_revdist( [anchorvt; allpnts; feszpnts], S.tris, S.vt, snaptol, allpnts );
    end
    [tris, vt] = viewfrombase( S.hedgehog.base, S.hedgehog.rays, tris, vt );
end
T = struct('tris', tris, 'vt', vt, 'pmls_type', 'deform_mesh', 'pmls_name', [S.pmls_name, '_smooth']);
if ~isempty(feszpnts)
    T.anchor = struct('tris', zeros(0,3), 'vt', feszpnts, 'pmls_type', 'mesh', 'pmls_name', [S.pmls_name, '_anchor']);   
end
T = matlab2py(T);
if isfield(SO, 'hedgehog')
    T.hedgehog = false; 
end
disp('output:');
T %#ok<NOPRT>

end

