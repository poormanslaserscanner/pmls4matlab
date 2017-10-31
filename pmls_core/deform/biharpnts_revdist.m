function [ntris,hvt] = biharpnts_revdist( pnts, ntris, nvt, limit, movablepnts )
%REMESHANDFILTER Summary of this function goes here
%   Detailed explanation goes here
%[nvt,ntris]=meshcheckrepair(nvt,ntris,'meshfix');

DT = DelaunayTri( pnts );
PI = nearestNeighbor(DT,nvt);
PIu = unique(PI);
m = numel(PIu);
sourcei = zeros(m,1);
dest = zeros(m,3);
PIm = nearestNeighbor(DT,movablepnts);
PIm = unique(PIm);
for j = 1 : m
    logind = ( PI == PIu( j ) );
    srci = find(logind);
    src = nvt( srci, : );
    dst = repmat( DT.X( PIu(j), : ), size( src, 1), 1 );
    d = dst - src;
    d = sqrt( dot( d, d, 2 ) );
    [mind,ind] = min( d );
    sourcei(j) = srci(ind);
    if mind < limit && any( PIm == PIu(j) ) 
        dest(j,:) = dst(ind,:);
    else
        dest(j,:) = src(ind,:);
    end
        
end
nvt(sourcei,:);
hvt = deform(ntris,nvt,sourcei,dest, 2 );
[hvt,ntris]=meshcheckrepair(hvt,ntris,'meshfix');
%displaymeshes( {ntris}, {nvt}, [] ); 
%[nvt,ntris]=meshcheckrepair(nvt,ntris,'dup');
[ntris, hvt] = filterrefvertices( ntris, hvt );

end

