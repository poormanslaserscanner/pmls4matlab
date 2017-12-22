function T = plsurfacedeform( S, unilap, snaptol, samplesiz )
%PLSURFACEDEFORM Summary of this function goes here
%   Detailed explanation goes here
snaptol = snaptol / 100;
allpnts = zeros(0,3);
feszpnts = allpnts;
anchorvt = allpnts;
if isfield(S, 'hedgehog')
    allpnts = cell2mat(S.hedgehog.rays);
end
% if isfield(S, 'anchor')
%     feszpnts = S.anchor.vt;
% end
[tris, vt] = biharpnts_revdist( [anchorvt; allpnts; feszpnts], S.tris, S.vt, snaptol, allpnts, unilap );
if ~isempty(allpnts)
    if samplesiz > eps
        for i = 1 : 4
        opnts = getrayoutmax(tris, vt, S.hedgehog.base, S.hedgehog.rays, samplesiz);
        feszpnts = [feszpnts;opnts];
        DT = delaunayTriangulation([feszpnts;allpnts]);
        feszpnts = DT.Points;
        rindices = int32(unique( nearestNeighbor(DT, allpnts) ));
        erindices = int32(unique( nearestNeighbor(DT, feszpnts) ));
        erindices = setdiff( erindices, rindices );
        feszpnts = DT.Points(erindices,:);
        [tris, vt] = biharpnts_revdist( [anchorvt; allpnts; feszpnts], S.tris, S.vt, snaptol, allpnts, unilap );
        end
    end
    [tris, vt] = viewfrombase( S.hedgehog.base, S.hedgehog.rays, tris, vt );
end
T = struct('tris', tris, 'vt', vt, 'pmls_type', 'deform_mesh', 'pmls_name', [S.pmls_name, '_smooth']);
if ~isempty(feszpnts)
    T.anchor = struct('tris', zeros(0,3), 'vt', feszpnts, 'pmls_type', 'mesh', 'pmls_name', [S.pmls_name, '_anchor']);   
end
if isfield(S, 'hedgehog')
    T.hedgehog = S.hedgehog;
end
end

