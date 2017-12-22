function S = plrmsingularities( S, unilap, snaptol )
%PLSURFACEDEFORM Summary of this function goes here
%   Detailed explanation goes here
snaptol = snaptol / 100;
allpnts = zeros(0,3);
feszpnts = allpnts;
anchorvt = allpnts;
if isfield(S, 'hedgehog')
    [allpnts,rayindices] = rays2indices(S.hedgehog.rays);
end
[~, ~, outl] = biharpnts_revdist( [anchorvt; allpnts; feszpnts], S.tris, S.vt, snaptol, allpnts, unilap, true );
if isfield(S, 'hedgehog')
    n = numel(rayindices);
    for i = 1 : n
        S.hedgehog.rays{i} = S.hedgehog.rays{i}(~ismember(rayindices{i},outl),:);
    end
end
end

