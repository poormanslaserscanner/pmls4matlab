function H = plclarifyinput( H, vox )
%PLCLARIFYINPUT Summary of this function goes here
%   Detailed explanation goes here
H.rays = shortenrays(H.base, H.rays, vox / 2);
H = plremoveoutliers(H, 2, 2);
H = plextendvisible(H);
H = plremoveoutliers(H, 5, 5);
[H,n] = rmsingularities(H, vox);
if n > 0
    H = plextendvisible(H);
    [H,n] = rmsingularities(H, vox);
    if n > 0
        H = plextendvisible(H);
    end
end
% n = numel(H.rays);
% nrays = cell(n,1);
% [mmb,indices] = gettasks(H.eedges);
% n = numel(mmb);
% for i = 1 : n
%     [~,locb] = ismember(mmb{i},indices{i});
%     nrays(mmb{i}) = cutback(H.base(indices{i},:),H.rays(indices{i}),H.erays(indices{i}),...
%                H.zeroshots(indices{i}),vox, locb);
% end
% n = numel(H.rays);
% for i = 1 : n
%     H.rays{i} = nrays{i};
% end
% H = plextendvisible(H);
% [H,n] = rmsingularities(H, vox);
% if n > 0
%     H = plextendvisible(H);
% end
end

function nrays = cutback( base, rays, erays, zeroshots, vox, locb)
    [tris,vt] = remeshunion(base, erays, zeroshots, vox, 0, true, true, 3);
    [allpnts,rayindices] = rays2indices(rays(locb));
    n = numel(locb);
    basepnts = zeros(size(allpnts,1),3);
    for i = 1 : n
        basepnts( rayindices{i}, : ) = repmat( base(locb(i),:), numel( rayindices{i} ), 1 );
    end
    [projpnts, logind] = projfromoutside(basepnts,allpnts,tris,vt);
    m = nnz(logind);
    sd = signed_distance([allpnts(logind,:); allpnts(logind,:) + (allpnts(logind,:) - projpnts(logind,:))],... 
                      vt, tris, 'SignedDistanceType', 'winding_number');
    indices = find(logind);
    logind( indices( sd((1:m)') < sd((m+1:2*m)') ) ) = false;
    allpnts(logind,:) = projpnts(logind,:);
    nrays = indices2rays(allpnts, rayindices);
end

function [mmb, indices] = gettasks(edges)
n = max(edges(:));
indices0 = cell(n,1);
for i = 1 : n
    indices0{i} = [i; edges( edges(:,1) == i, 2 );edges( edges(:,2) == i, 1 )];
end
mmb = cell(0,1);
for i = 1 : n
    ismax = true;
    v = zeros(0,1);
    actindices = indices0{i};
    for j = 1 : n
        if all(ismember( indices0{j}, indices0{i}))
            v = [v;j];
            if all(ismember( indices0{i}, indices0{j})) && j < i
                ismax = false;
                break;
            end
        elseif all(ismember( indices0{i}, indices0{j})) 
            ismax = false;
            break;
        end
    end
    if ismax
        m = numel(mmb);
        for j = 1 : m
            v = setdiff(v, mmb{j});
        end
        mmb = [mmb;{v}];
    end
end
n = numel(mmb);
indices = cell(n,1);
for i = 1 : n
    indices{i} = unique(cell2mat(indices0(mmb{i})));
end
end

function [H, nrm] = rmsingularities(H, vox)
n = numel(H.rays);
todel = cell(n,1);
[mmb,indices] = gettasks(H.eedges);
n = numel(mmb);
for i = 1 : n
    [tris,vt] = remeshunion(H.base(indices{i},:),H.erays(indices{i}),H.zeroshots(indices{i}),... 
                vox, 0, true, true, 0.7, {});
    [allpnts, rayindices] = rays2indices(H.rays(indices{i}));
    [~, ~, outrays] = biharpnts_revdist( allpnts, tris, vt, 4 * vox, allpnts, true, true );
    m = numel(mmb{i});
    for j = 1 : m
        todel{mmb{i}(j)} = ismember(rayindices{indices{i} == mmb{i}(j)},outrays);
    end
end
nrm = 0;
n = numel(H.rays);
for i = 1 : n
    nrm = nrm + nnz(todel{i});
    H.rays{i} = H.rays{i}(~todel{i},:);
end
end
