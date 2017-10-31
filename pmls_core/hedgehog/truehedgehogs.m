function [base,rays,vid, nedges, zeroshots, erays] = truehedgehogs( base, rays, vid, edges, zeroshots, truemin, erays )
if nargin < 6
    truemin = 20;
end
n = numel( rays );
hedgeindices = false(n,1);
for i = 1 : n
    hedgeindices(i) = ( size( rays{i}, 1 ) >= truemin );  
end
base = base( hedgeindices, : );
rays = rays(hedgeindices);
if nargin > 2
    vid = vid( hedgeindices );
end
if nargin > 3
    nedges = edges( hedgeindices( edges(:,1) ) & hedgeindices( edges(:,2 ) ), : );
    bool = int32( hedgeindices );
    count = 0;
    for i = 1 : n
        count = count + bool(i);
        bool( i ) = count;
    end
    m = numel( nedges );
    for i = 1 : m
        nedges(i) = bool( nedges(i) );
        assert( nedges(i) > 0 );
    end
end
if nargin > 4
    zeroshots = zeroshots( hedgeindices );
end
if nargin > 6
    erays = erays(hedgeindices);
end