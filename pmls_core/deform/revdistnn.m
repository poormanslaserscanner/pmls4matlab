function indices = revdistnn( pnts, nvt )
%REVDISTNN Summary of this function goes here
%   Detailed explanation goes here
DT = DelaunayTri( pnts );
PI = nearestNeighbor(DT,nvt);
m = size(DT.X,1);
sourcei = zeros(m,1);
parfor j = 1 : m
    logind = ( PI == j );
    if any(logind)
        srci = find(logind);
        src = nvt( srci, : );
        dst = repmat( DT.X( j, : ), size( src, 1), 1 );
        d = dst - src;
        d = sqrt( dot( d, d, 2 ) );
        [~,ind] = min( d );
        sourcei(j) = srci(ind);
    end
end
PI = nearestNeighbor(DT,pnts);
indices = sourcei(PI,:);
end

