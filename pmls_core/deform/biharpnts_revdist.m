function [ntris,hvt,movableoutliers] = biharpnts_revdist( pnts, ntris, nvt, limit, movablepnts, unilap, raw )
%REMESHANDFILTER Summary of this function goes here
%   Detailed explanation goes here
%[nvt,ntris]=meshcheckrepair(nvt,ntris,'meshfix');
if nargin < 6
    unilap = true;
end
if nargin < 7
    raw = false;
end
DT = delaunayTriangulation( pnts );
PI = nearestNeighbor(DT,nvt);
PIu = unique(PI);
m = numel(PIu);
sourcei = zeros(m,1);
dest = zeros(m,3);
PIm = nearestNeighbor(DT,movablepnts);
%PIm = unique(PIm);
tomove = zeros(m,1);
for j = 1 : m
    logind = ( PI == PIu( j ) );
    srci = find(logind);
    src = nvt( srci, : );
    dst = repmat( DT.Points( PIu(j), : ), size( src, 1), 1 );
    d = dst - src;
    d = sqrt( dot( d, d, 2 ) );
    [mind,ind] = min( d );
    sourcei(j) = srci(ind);
    logind = ( PIm == PIu(j) );
    anyl = any(logind);
    if anyl
        srci = find(logind);
        tomove(j) = srci(1);
    end
    if mind < limit && anyl
        dest(j,:) = dst(ind,:);
    else
        dest(j,:) = src(ind,:);
    end
        
end
nvt(sourcei,:);
if unilap
    hvt = deformunilap(ntris,nvt,sourcei,dest, 2 );
else
    hvt = deform(ntris,nvt,sourcei,dest, 2 );
end
if nargout > 2
    indices = sourcei(tomove > 0);
    [s1vt,s0vt,stris] = submesh(hvt, nvt, ntris, indices);
    m = numel(indices);
    sindices = getmesharearatio(s1vt, s0vt, stris, 0.01, m);
    movableoutliers = tomove(sindices(sindices <= m ));
end
if raw
    return
end
[hvt,ntris]=meshcheckrepair(hvt,ntris,'meshfix');

%displaymeshes( {ntris}, {nvt}, [] ); 
%[nvt,ntris]=meshcheckrepair(nvt,ntris,'dup');
[ntris, hvt] = filterrefvertices( ntris, hvt );

end

% function indices = getmeshpeaks(vt, tris, internal)
% angles = internalangles(vt,tris) * 180 / pi;
% indices = tris(angles > internal);
% indices = unique(indices(:));
% m = size(vt,1);
% logind = true(m,1);
% logind(indices) = false;
% indices = find(logind);
% end

function indices = getmesharearatio(vt1, vt0, tris, internal, maxindex)
area1tr = doublearea(vt1, tris);
area0tr =  doublearea(vt0, tris);
TR = triangulation(tris,vt1);
ti = vertexAttachments(TR,(1:maxindex)');
area1 = zeros(maxindex,1);
area0 = zeros(maxindex,1);
for i = 1 : maxindex
    area1(i) = sum(area1tr(ti{i}));
    area0(i) = sum(area0tr(ti{i}));
end
logind = (area1 ./ area0) < internal;
indices = find(logind);
end

function [s1vt,s0vt,stris] = submesh(hvt, nvt, ntris, indices)
n = size(hvt,1);
transindices = zeros(n,1);
m = numel(indices);
transindices(indices) = (1 : m)';
logind = any(transindices(ntris),2);
stris = ntris(logind,:);
C = setdiff(stris(:), indices);
m2 = numel(C);
transindices(C) = (m+1:m+m2)';
s1vt = hvt([indices;C],:);
s0vt = nvt([indices;C],:);
stris = transindices(stris);

end